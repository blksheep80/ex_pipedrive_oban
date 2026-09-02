defmodule ExPipedriveOban.Workers.SyncDeals do
  @moduledoc """
  Convenience enqueue helper for a deals cursor sync.

  See `ExPipedriveOban.SyncWorker` for job args and uniqueness.
  """

  alias ExPipedriveOban.SyncWorker

  @doc """
  Builds an Oban changeset for a deals sync (does not insert).
  """
  @spec enqueue(module() | String.t(), String.t(), keyword()) :: Ecto.Changeset.t()
  def enqueue(source, tenant_id, opts \\ []) when is_binary(tenant_id) do
    source_name =
      case source do
        mod when is_atom(mod) -> Atom.to_string(mod)
        name when is_binary(name) -> name
      end

    %{
      "source" => source_name,
      "tenant_id" => tenant_id,
      "resource" => "deals",
      "cursor" => Keyword.get(opts, :cursor),
      "limit" => Keyword.get(opts, :limit),
      "list_opts" => stringify_keys(Keyword.get(opts, :list_opts, []))
    }
    |> SyncWorker.new()
  end

  defp stringify_keys(list) when is_list(list) do
    Map.new(list, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
