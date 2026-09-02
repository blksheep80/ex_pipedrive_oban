defmodule ExPipedriveOban.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/blksheep80/ex_pipedrive_oban"

  def project do
    [
      app: :ex_pipedrive_oban,
      version: @version,
      elixir: "~> 1.17",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      ex_pipedrive_dep(),
      {:oban, "~> 2.17"}
    ] ++ path_dev_pins()
  end

  defp using_local_core? do
    System.get_env("HEX_PUBLISH") not in ~w(1 true) and local_core?()
  end

  defp local_core? do
    mix = Path.expand("../ex_pipedrive/mix.exs", __DIR__)
    File.exists?(mix) and File.read!(mix) =~ ~r/app:\s*:ex_pipedrive/
  end

  defp path_dev_pins do
    if using_local_core?(), do: [{:tesla, "~> 1.12.0"}], else: []
  end

  defp ex_pipedrive_dep do
    if using_local_core?() do
      {:ex_pipedrive, path: Path.expand("../ex_pipedrive", __DIR__), override: true}
    else
      {:ex_pipedrive, "~> 0.2"}
    end
  end

  defp description do
    """
    Optional Oban workers for cursor-aware Pipedrive sync with rate-limit
    snooze. Depends on ex_pipedrive; the host app owns Oban, Ecto, and TokenStore.
    """
  end

  defp package do
    [
      name: "ex_pipedrive_oban",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "HexDocs" => "https://hexdocs.pm/ex_pipedrive_oban",
        "Core" => "https://hex.pm/packages/ex_pipedrive"
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"]
    ]
  end
end
