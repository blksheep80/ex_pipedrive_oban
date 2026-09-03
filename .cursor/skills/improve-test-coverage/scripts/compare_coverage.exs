#!/usr/bin/env elixir
# Compare two ExCoveralls JSON runs to find unstable coverage lines.
#
# Usage:
#   elixir .cursor/skills/improve-test-coverage/scripts/compare_coverage.exs file1.json file2.json [module_filter]

defmodule CompareCoverage do
  def main([a, b | rest]) do
    filter = List.first(rest)

    data_a = a |> File.read!() |> Jason.decode!()
    data_b = b |> File.read!() |> Jason.decode!()

    index_a = index(data_a)
    index_b = index(data_b)

    names =
      MapSet.union(MapSet.new(Map.keys(index_a)), MapSet.new(Map.keys(index_b)))
      |> Enum.sort()
      |> maybe_filter(filter)

    variant_count = 0

    for name <- names do
      cov_a = Map.get(index_a, name, [])
      cov_b = Map.get(index_b, name, [])

      variants =
        Enum.zip(cov_a, cov_b)
        |> Enum.with_index(1)
        |> Enum.filter(fn {{hit_a, hit_b}, _line} ->
          (hit_a == 0 and hit_b != 0) or (hit_a != 0 and hit_b == 0)
        end)

      if variants != [] do
        IO.puts("\n#{name}:")
        variant_count = variant_count + length(variants)

        for {{hit_a, hit_b}, line_no} <- variants do
          IO.puts("  line #{line_no}: #{inspect(hit_a)} -> #{inspect(hit_b)}")
        end
      end
    end

    if variant_count == 0, do: IO.puts("No variant lines between runs.")
  end

  def main(_) do
    IO.puts(:stderr, "Usage: compare_coverage.exs file1.json file2.json [module_filter]")
    System.halt(1)
  end

  defp index(data) do
    data["source_files"]
    |> Enum.map(fn f -> {f["name"], f["coverage"] || []} end)
    |> Map.new()
  end

  defp maybe_filter(names, nil), do: names

  defp maybe_filter(names, filter) do
    Enum.filter(names, fn n -> String.contains?(n, filter) end)
  end
end

CompareCoverage.main(System.argv())
