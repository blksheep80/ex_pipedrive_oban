#!/usr/bin/env elixir
# Find high-ROI coverage targets (modules close to 100% with few gaps).
#
# Usage:
#   elixir .cursor/skills/improve-test-coverage/scripts/find_quick_wins.exs [min] [max] [max_uncovered] [limit]
#
# Defaults: min=85, max=99.9, max_uncovered=10, limit=20

defmodule FindQuickWins do
  @default_path "cover/excoveralls.json"

  def main(argv) do
    case argv do
      ["--help" | _] -> help()
      _ -> run(argv)
    end
  end

  defp help do
    IO.puts("""
    Usage: find_quick_wins.exs [min_cov] [max_cov] [max_uncovered] [limit]

    Example:
      elixir find_quick_wins.exs 90 99 5 15
    """)
  end

  defp run(argv) do
    [min_s, max_s, max_unc_s, limit_s] = (argv ++ ["85", "99.9", "10", "20"]) |> Enum.take(4)
    min = String.to_float(min_s)
    max = String.to_float(max_s)
    max_unc = String.to_integer(max_unc_s)
    limit = String.to_integer(limit_s)

    unless File.exists?(@default_path) do
      IO.puts(:stderr, "Run mix coveralls.json first")
      System.halt(1)
    end

    data = @default_path |> File.read!() |> Jason.decode!()

    data["source_files"]
    |> Enum.map(&module_stats/1)
    |> Enum.filter(fn m ->
      m.coverage >= min and m.coverage <= max and m.uncovered <= max_unc and m.relevant > 0
    end)
    |> Enum.sort_by(fn m -> {m.uncovered, -m.coverage} end)
    |> Enum.take(limit)
    |> case do
      [] ->
        IO.puts("No quick-win modules found. Try widening min/max or max_uncovered.")

      rows ->
        IO.puts("Quick-win modules (#{length(rows)} shown):")
        IO.puts("")

        for m <- rows do
          IO.puts(
            "#{Float.round(m.coverage, 1)}%  #{m.uncovered} uncovered  #{m.name}"
          )
        end
    end
  end

  defp module_stats(file) do
    hits = file["coverage"] || []
    relevant = Enum.reject(hits, &is_nil/1)
    uncovered = Enum.count(relevant, &(&1 == 0))
    covered = length(relevant) - uncovered

    pct =
      if relevant == [],
        do: 0.0,
        else: covered / length(relevant) * 100

    %{
      name: file["name"],
      coverage: pct,
      uncovered: uncovered,
      relevant: length(relevant)
    }
  end
end

FindQuickWins.main(System.argv())
