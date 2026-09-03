#!/usr/bin/env elixir
# Overall ExCoveralls progress from cover/excoveralls.json
#
# Usage:
#   mix coveralls.json
#   elixir .cursor/skills/improve-test-coverage/scripts/coverage_progress.exs [path/to/coverage.json]

defmodule CoverageProgress do
  @default_path "cover/excoveralls.json"

  def main(argv) do
    path = List.first(argv) || @default_path

    unless File.exists?(path) do
      IO.puts(:stderr, "Coverage file not found: #{path}")
      IO.puts(:stderr, "Run: mix coveralls.json")
      System.halt(1)
    end

    data = path |> File.read!() |> Jason.decode!()
    files = Map.get(data, "source_files", [])

    {covered, total} =
      Enum.reduce(files, {0, 0}, fn file, {cov, tot} ->
        hits = file["coverage"] || []

        Enum.reduce(hits, {cov, tot}, fn
          nil, acc -> acc
          n, {c, t} -> {c + if(n > 0, do: 1, else: 0), t + 1}
        end)
      end)

    pct = if total == 0, do: 0.0, else: covered / total * 100

    IO.puts("Overall coverage: #{Float.round(pct, 1)}%")
    IO.puts("Lines covered: #{covered} / #{total}")
    IO.puts("Modules tracked: #{length(files)}")

    tiers = %{
      "100%" => 0,
      "95-99%" => 0,
      "85-94%" => 0,
      "75-84%" => 0,
      "<75%" => 0
    }

    tiers =
      Enum.reduce(files, tiers, fn file, acc ->
        hits = file["coverage"] || []
        relevant = Enum.reject(hits, &is_nil/1)

        tier =
          cond do
            relevant == [] -> "<75%"
            true ->
              file_cov = Enum.count(relevant, &(&1 > 0)) / length(relevant) * 100

              cond do
                file_cov == 100.0 -> "100%"
                file_cov >= 95.0 -> "95-99%"
                file_cov >= 85.0 -> "85-94%"
                file_cov >= 75.0 -> "75-84%"
                true -> "<75%"
              end
          end

        Map.update!(acc, tier, &(&1 + 1))
      end)

    IO.puts("")
    IO.puts("Module distribution:")

    for {tier, count} <- tiers do
      IO.puts("  #{tier}: #{count}")
    end

    for goal <- [75, 80, 85] do
      needed = max(0, ceil(goal / 100 * total - covered))
      IO.puts("Lines to reach #{goal}%: #{needed}")
    end
  end
end

CoverageProgress.main(System.argv())
