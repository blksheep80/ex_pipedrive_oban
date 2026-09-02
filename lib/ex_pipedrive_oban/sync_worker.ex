defmodule ExPipedriveOban.SyncWorker do
  @moduledoc """
  Cursor-aware Oban worker for Pipedrive list endpoints.

  Job args:

  * `"source"` — module implementing `ExPipedriveOban.Source`
  * `"tenant_id"` — opaque tenant key (unique with `"resource"`)
  * `"resource"` — `"deals"` / `"persons"` / `"organizations"` / `"activities"`
  * `"cursor"` — optional v2 cursor to resume
  * `"limit"` — optional page size
  * `"list_opts"` — optional string-key map of extra `list_page/2` options

  Kickoff jobs are unique per tenant + resource. Continuation pages insert
  with `unique: false` so the next cursor is not treated as a duplicate kickoff.
  """

  use Oban.Worker,
    queue: :pipedrive,
    unique: [
      period: 60,
      keys: [:tenant_id, :resource],
      states: [:scheduled, :available, :retryable]
    ]

  alias ExPipedrive.Error
  alias ExPipedrive.Page
  alias ExPipedriveOban.Sync

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    source = source_module(args)

    with {:ok, client} <- fetch_client(source, args),
         {:ok, %Page{} = page} <- Sync.page(client, args),
         :ok <- source.handle_page(args["resource"], page.data, args) do
      enqueue_next(page, args)
    else
      {:error, %Error{kind: :rate_limited} = error} ->
        {:snooze, Sync.snooze_seconds(error)}

      {:error, :unknown_resource} ->
        {:discard, :unknown_resource}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_client(source, args) do
    case source.client(args) do
      %Tesla.Client{} = client -> {:ok, client}
      {:ok, %Tesla.Client{} = client} -> {:ok, client}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_client, other}}
    end
  end

  defp source_module(%{"source" => source}) when is_binary(source) do
    String.to_existing_atom(source)
  end

  defp enqueue_next(%Page{next_cursor: nil}, _args), do: :ok

  defp enqueue_next(%Page{next_cursor: cursor}, args) do
    args
    |> Map.put("cursor", cursor)
    |> new(unique: false)
    |> insert_job()
    |> case do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_job(changeset) do
    insert = Application.get_env(:ex_pipedrive_oban, :insert, &Oban.insert/1)
    insert.(changeset)
  end
end
