defmodule PhoenixModuleTemplate.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "Professional Phoenix module template with PostgreSQL support"
  @source_url "https://github.com/your-org/phoenix_module_template"

  def project do
    [
      app: :phoenix_module_template,
      version: @version,
      description: @description,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex package configuration
      package: package(),

      # Documentation
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Aliases for development
      aliases: aliases()
    ]
  end

  # Library configuration - no OTP application
  # The parent Phoenix application will handle supervision
  def application do
    [
      extra_applications: [:logger, :ecto, :postgrex]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies - minimal and focused on library functionality
  defp deps do
    [
      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Optional Phoenix integration (peer dependencies)
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_ecto, "~> 4.4", optional: true},
      {:phoenix_html, "~> 4.0", optional: true},
      {:phoenix_live_view, "~> 0.20", optional: true},

      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Utilities
      {:jason, "~> 1.4", optional: true}
    ]
  end

  # Package configuration for Hex.pm
  defp package do
    [
      name: "phoenix_module_template",
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  # Documentation configuration
  defp docs do
    [
      name: "Phoenix Module Template",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  # Development aliases
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],

      # Code quality
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
