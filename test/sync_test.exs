defmodule ExPipedriveOban.SyncTest do
  use ExUnit.Case, async: true

  alias ExPipedrive.Client
  alias ExPipedrive.Deal
  alias ExPipedrive.Error
  alias ExPipedrive.Page
  alias ExPipedriveOban.Sync

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

  defp client(response) do
    Client.new("token", "http://example.test",
      retry: false,
      telemetry: false,
      adapter: {CaptureAdapter, [test_pid: self(), response: response]}
    )
  end

  test "page/2 lists deals with cursor opts" do
    client =
      client(%{
        status: 200,
        body: %{
          "success" => true,
          "data" => [%{"id" => 3, "title" => "Acme"}],
          "additional_data" => %{"next_cursor" => "abc", "limit" => 1}
        }
      })

    assert {:ok, %Page{data: [%Deal{id: 3}], next_cursor: "abc"}} =
             Sync.page(client, %{
               "resource" => "deals",
               "limit" => 1,
               "list_opts" => %{"status" => "open"}
             })

    assert_received {:tesla_request, %Tesla.Env{query: query, url: url}}
    assert String.contains?(url, "/api/v2/deals")
    assert query[:status] == "open"
    assert query[:limit] == 1
  end

  test "page/2 returns unknown_resource" do
    client = client(%{status: 200, body: %{"success" => true, "data" => []}})
    assert {:error, :unknown_resource} = Sync.page(client, %{"resource" => "widgets"})
  end

  test "snooze_seconds/1 uses Retry-After" do
    error = %Error{
      kind: :rate_limited,
      rate_limit: %{retry_after: 42}
    }

    assert Sync.snooze_seconds(error) == 42
  end

  test "snooze_seconds/1 defaults when headers are missing" do
    assert Sync.snooze_seconds(%Error{kind: :rate_limited}) == 15
  end
end
