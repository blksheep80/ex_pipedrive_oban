#!/usr/bin/env elixir
# Show uncovered lines for a module file.
#
# Usage:
#   elixir .cursor/skills/improve-test-coverage/scripts/find_uncovered_lines.exs <module_path>
#
# module_path may be a full path, partial path, or basename.

defmodule FindUncoveredLines do
  @default_path "cover/excoveralls.json"

  def main(argv) do
    case argv do
      ["--help" | _] -> help()
      [pattern] -> run(pattern)
      _ ->
        IO.puts(:stderr, "Usage: find_uncovered_lines.exs <module_path>")
        System.halt(1)
    end
  end

  defp help do
    IO.puts("""
    Usage: find_uncovered_lines.exs <module_path>

    Examples:
      find_uncovered_lines.exs lib/ex_pipedrive/client.ex
      find_uncovered_lines.exs client.ex
    """)
  end

  defp run(pattern) do
    unless File.exists?(@default_path) do
      IO.puts(:stderr, "Run mix coveralls.json first")
      System.halt(1)
    end

    data = @default_path |> File.read!() |> Jason.decode!()

    file =
      data["source_files"]
      |> Enum.find(fn f ->
        name = f["name"] || ""
        String.ends_with?(name, pattern) or String.contains?(name, pattern)
      end)

    unless file do
      IO.puts(:stderr, "No coverage entry matching: #{pattern}")
      System.halt(1)
    end

    lines = String.split(file["source"] || "", "\n")
    coverage = file["coverage"] || []

    IO.puts("Module: #{file["name"]}")
    IO.puts(String.duplicate("-", 72))

    coverage
    |> Enum.with_index(1)
    |> Enum.filter(fn {hit, _line_no} -> hit == 0 end)
    |> Enum.each(fn {_hit, line_no} ->
      src = Enum.at(lines, line_no - 1, "")
      IO.puts("#{line_no}: #{String.trim_leading(src)}")
    end)
  end
end

FindUncoveredLines.main(System.argv())
