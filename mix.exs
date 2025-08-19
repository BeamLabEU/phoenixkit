defmodule PhoenixKit.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "Professional authentication library for Phoenix applications with zero-config setup"
  @source_url "https://github.com/BeamLabEU/phoenix_kit"

  def project do
    [
      app: :phoenix_kit,
      version: @version,
      description: @description,
      elixir: "~> 1.18",
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
      extra_applications: [:logger, :ecto, :postgrex, :crypto, :gettext]
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
      {:postgrex, "~> 0.21.1"},

      # Phoenix web layer - required for authentication module
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.1.7"},

      # Web functionality
      {:gettext, "~> 0.24"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:plug_cowboy, "~> 2.5"},
      {:esbuild, "~> 0.8", only: :dev},
      {:tailwind, "~> 0.2", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},

      # Authentication
      {:bcrypt_elixir, "~> 3.0"},
      {:swoosh, "~> 1.19.5"},

      # Development and testing
      {:ex_doc, "~> 0.38.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.6", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:hackney, "~> 1.9"},

      # Utilities
      {:jason, "~> 1.4"},

      # Code generation and project patching
      {:igniter, "~> 0.6.27", optional: true}
    ]
  end

  # Package configuration for Hex.pm
  defp package do
    [
      name: "phoenix_kit",
      maintainers: ["BeamLab EU"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  # Documentation configuration
  defp docs do
    [
      name: "PhoenixKit",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "PhoenixKit",
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Authentication: [
          PhoenixKit.Users.Auth,
          PhoenixKit.Users.Auth.User,
          PhoenixKit.Users.Auth.UserToken,
          PhoenixKit.Users.MagicLink,
          PhoenixKit.Users.Auth.Scope
        ],
        "Web Integration": [
          PhoenixKitWeb.Integration,
          PhoenixKitWeb.Users.Auth,
          PhoenixKit.LayoutConfig
        ],
        Database: [
          PhoenixKit.Migration,
          PhoenixKit.Repo,
          PhoenixKit.RepoHelper
        ],
        Configuration: [
          PhoenixKit.Config,
          PhoenixKit.ConfigEnv,
          PhoenixKit.Mailer
        ],
        "Mix Tasks": [
          Mix.Tasks.PhoenixKit.Install,
          Mix.Tasks.PhoenixKit.Update,
          Mix.Tasks.PhoenixKit.Gen.Migration
        ]
      ]
    ]
  end

  # Development aliases
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],

      # Code quality
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
