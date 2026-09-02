defmodule ExPipedriveOban.SyncWorkerTest do
  use ExUnit.Case, async: false

  alias ExPipedrive.Client
  alias ExPipedriveOban.SyncWorker
  alias ExPipedriveOban.Workers.SyncDeals

  defmodule CaptureAdapter do
    @behaviour Tesla.Adapter

    @impl true
    def call(env, opts) do
      send(Keyword.fetch!(opts, :test_pid), {:tesla_request, env})
      response = Keyword.fetch!(opts, :response)

      {:ok,
       %{
         env
         | status: Map.get(response, :status, 200),
           body: Map.get(response, :body, %{}),
           headers: Map.get(response, :headers, [])
       }}
    end
  end

  defmodule Source do
    @behaviour ExPipedriveOban.Source

    @impl true
    def client(_args) do
      response = Process.get(:pipedrive_response)

      Client.new("token", "http://example.test",
        retry: false,
        telemetry: false,
        adapter: {CaptureAdapter, [test_pid: self(), response: response]}
      )
    end

    @impl true
    def handle_page(resource, rows, args) do
      send(self(), {:page, resource, rows, args})
      :ok
    end
  end

  setup do
    insert = fn changeset ->
      send(self(), {:inserted, changeset})
      {:ok, %Oban.Job{}}
    end

    Application.put_env(:ex_pipedrive_oban, :insert, insert)

    on_exit(fn ->
      Application.delete_env(:ex_pipedrive_oban, :insert)
    end)

    :ok
  end

  defp perform(response, args \\ %{}) do
    Process.put(:pipedrive_response, response)

    job = %Oban.Job{
      args:
        Map.merge(
          %{
            "source" => Atom.to_string(Source),
            "tenant_id" => "acme",
            "resource" => "deals"
          },
          args
        )
    }

    SyncWorker.perform(job)
  end

  test "delivers a deals page and stops when next_cursor is nil" do
    assert :ok =
             perform(%{
               status: 200,
               body: %{
                 "success" => true,
                 "data" => [%{"id" => 9, "title" => "Won"}],
                 "additional_data" => %{"next_cursor" => nil}
               }
             })

    assert_received {:page, "deals", [%ExPipedrive.Deal{id: 9}], _}
    refute_received {:inserted, _}
  end

  test "enqueues the next cursor without unique" do
    assert :ok =
             perform(%{
               status: 200,
               body: %{
                 "success" => true,
                 "data" => [%{"id" => 1, "title" => "Open"}],
                 "additional_data" => %{"next_cursor" => "cur-2"}
               }
             })

    assert_received {:inserted, changeset}
    assert Ecto.Changeset.get_field(changeset, :args)["cursor"] == "cur-2"
    refute Ecto.Changeset.get_field(changeset, :unique)
  end

  test "snoozes on rate_limited errors" do
    assert {:snooze, 7} =
             perform(%{
               status: 429,
               headers: [{"retry-after", "7"}],
               body: %{"success" => false, "error" => "too many requests"}
             })
  end

  test "SyncDeals.enqueue/3 builds a deals job changeset" do
    changeset = SyncDeals.enqueue(Source, "acme", list_opts: [status: "open"])
    args = Ecto.Changeset.get_field(changeset, :args)

    assert args["resource"] == "deals"
    assert args["tenant_id"] == "acme"
    assert args["source"] == Atom.to_string(Source)
    assert args["list_opts"]["status"] == "open"
  end
end
