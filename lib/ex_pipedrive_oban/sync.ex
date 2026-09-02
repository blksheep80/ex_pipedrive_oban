defmodule ExPipedriveOban.Sync do
  @moduledoc """
  Fetches one cursor page and computes Oban snooze delays.

  `ExPipedriveOban.SyncWorker` wraps this for job unique keys and enqueueing
  the next page. Tests can call `page/2` without running Oban.
  """

  alias ExPipedrive.Activities
  alias ExPipedrive.Deals
  alias ExPipedrive.Error
  alias ExPipedrive.Organizations
  alias ExPipedrive.Page
  alias ExPipedrive.Persons
  alias ExPipedrive.RateLimit
  alias Tesla.Client

  @default_snooze 15

  @doc """
  Resources that can be synced via `list_page/2`.
  """
  @spec resources() :: [String.t()]
  def resources, do: ["deals", "persons", "organizations", "activities"]

  @doc """
  Loads one v2 cursor page for `args["resource"]`.

  Extra Pipedrive list filters come from `args["list_opts"]` (string-key map).
  """
  @spec page(Client.t(), map()) :: {:ok, Page.t()} | {:error, Error.t() | :unknown_resource}
  def page(%Client{} = client, args) when is_map(args) do
    resource = Map.get(args, "resource") || Map.get(args, :resource)
    opts = list_opts(args)

    case fetcher(resource) do
      nil -> {:error, :unknown_resource}
      fun -> fun.(client, opts)
    end
  end

  @doc """
  Oban snooze seconds for a rate-limit error (at least 1).
  """
  @spec snooze_seconds(Error.t()) :: pos_integer()
  def snooze_seconds(%Error{rate_limit: info}) do
    case RateLimit.delay_ms(info) do
      nil -> @default_snooze
      ms when is_integer(ms) and ms > 0 -> max(1, div(ms, 1000))
      _ -> @default_snooze
    end
  end

  def snooze_seconds(_), do: @default_snooze

  defp fetcher("deals"), do: &Deals.list_page/2
  defp fetcher("persons"), do: &Persons.list_page/2
  defp fetcher("organizations"), do: &Organizations.list_page/2
  defp fetcher("activities"), do: &Activities.list_page/2
  defp fetcher(_), do: nil

  defp list_opts(args) do
    cursor = Map.get(args, "cursor") || Map.get(args, :cursor)
    limit = Map.get(args, "limit") || Map.get(args, :limit)
    extra = Map.get(args, "list_opts") || Map.get(args, :list_opts) || %{}

    extra
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      {key, value} when is_atom(key) -> {key, value}
    end)
    |> Keyword.new()
    |> Keyword.put(:cursor, cursor)
    |> then(fn opts ->
      if is_integer(limit) and limit > 0, do: Keyword.put(opts, :limit, limit), else: opts
    end)
  end
end
