defmodule PhoenixKit.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/BeamLabEU/phoenixkit"

  def project do
    [
      app: :phoenix_kit,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix dependencies with latest/RC versions
      {:phoenix, "~> 1.8.0-rc.0", override: true},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0.0-rc.0"},
      {:phoenix_template, "~> 1.0"},

      # Additional utilities
      {:jason, "~> 1.4"},
      {:plug, "~> 1.16"},

      # Igniter for code generation and installation
      {:igniter, "~> 0.6", only: [:dev, :test], optional: true},

      # Dev/Test dependencies
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp description do
    """
    PhoenixKit v0.3.0 - A comprehensive extension library for Phoenix Framework.
    Provides ready-to-use components, utilities, and tools for rapid development 
    of modern web applications. Features include interactive dashboards, LiveView 
    components, 100+ utility functions, security systems, and modern design.
    """
  end

  defp package do
    [
      name: "phoenix_kit",
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/phoenix_kit"
      },
      maintainers: ["BeamLab EU"]
    ]
  end

  defp docs do
    [
      main: "PhoenixKit",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp aliases do
    [
      test: ["test"],
      "test.coverage": ["coveralls.html"]
    ]
  end
end
