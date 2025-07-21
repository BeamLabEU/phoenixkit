defmodule BeamLab.PhoenixKit.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/BeamLabEU/phoenixkit"

  def project do
    [
      app: :phoenix_kit,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      
      # Phoenix Code Reloader
      listeners: listeners(Mix.env()),
      
      # Package metadata
      description: description(),
      package: package(),
      
      # Documentation
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      
      # Testing
      preferred_cli_env: [
        "test.ci": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    case phoenix_kit_mode() do
      :standalone ->
        [
          mod: {BeamLab.PhoenixKit.Application, []},
          extra_applications: [:logger, :runtime_tools, :crypto]
        ]
      :library ->
        [
          extra_applications: [:logger, :crypto]
        ]
    end
  end

  # Determines if Phoenix Kit should run as standalone app or library
  defp phoenix_kit_mode do
    case {Mix.env(), Application.get_env(:phoenix_kit, :mode)} do
      {:dev, _} -> :standalone  # Always standalone in dev for easier development
      {:test, _} -> :standalone  # Always standalone in test for complete testing
      {_, :standalone} -> :standalone
      {_, :library} -> :library
      {_, nil} -> :library  # Default to library mode
      {_, _} -> :library
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # CORE libraries (always needed)
      {:phoenix, "~> 1.8.0-rc.4"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0.9"},
      {:tailwind, "~> 0.3"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},

      # DATABASE (optional, user can choose their own)
      {:postgrex, ">= 0.0.0", optional: true},

      # STANDALONE dependencies (only for demo/development)
      {:bandit, "~> 1.5", optional: true},
      {:swoosh, "~> 1.16", optional: true},
      {:req, "~> 0.5", optional: true},
      # {:dns_cluster, "~> 0.2", optional: true},
      {:phoenix_live_dashboard, "~> 0.8.3", optional: true},
      {:telemetry_metrics, "~> 1.0", optional: true},
      {:telemetry_poller, "~> 1.0", optional: true},

      # DEVELOPMENT dependencies
      {:phoenix_live_reload, "~> 1.2", only: :dev, optional: true},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev, optional: true},
      {:floki, ">= 0.30.0", only: :test}

    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind phoenix_kit", "esbuild phoenix_kit"],
      "assets.deploy": [
        "tailwind phoenix_kit --minify",
        "esbuild phoenix_kit --minify",
        "phx.digest"
      ],
      
      # PhoenixKit installation aliases (available when used as dependency)
      "phoenix_kit.install": ["run -e \"Mix.Tasks.PhoenixKit.Install.run([])\""],
      "phoenix_kit.gen.migration": ["run -e \"Mix.Tasks.PhoenixKit.Gen.Migration.run([])\""],
      "phoenix_kit.gen.routes": ["run -e \"Mix.Tasks.PhoenixKit.Gen.Routes.run([])\""]
    ]
  end

  defp description do
    """
    BeamLab Phoenix Kit - A professional Phoenix authentication and UI component library.
    
    Provides complete user authentication system with registration, login, password reset,
    email confirmation, and security best practices. Includes reusable UI components 
    built with Tailwind CSS and designed for easy integration into Phoenix applications.
    """
  end

  defp package do
    [
      name: "phoenix_kit",
      maintainers: ["BeamLab Team"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/phoenix_kit",
        "BeamLab" => "https://beamlab.eu"
      },
      files: ~w(
        lib
        priv/repo/migrations
        priv/gettext
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
      )
    ]
  end

  defp docs do
    [
      main: "BeamLab.PhoenixKit",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      groups_for_modules: [
        "Core API": [
          BeamLab.PhoenixKit
        ],
        "Accounts": [
          BeamLab.PhoenixKit.Accounts,
          BeamLab.PhoenixKit.Accounts.User,
          BeamLab.PhoenixKit.Accounts.UserToken,
          BeamLab.PhoenixKit.Accounts.UserNotifier,
          BeamLab.PhoenixKit.Accounts.Scope
        ],
        "Web Layer": [
          BeamLab.PhoenixKitWeb,
          BeamLab.PhoenixKitWeb.UserAuth
        ],
        "Controllers": [
          BeamLab.PhoenixKitWeb.UserRegistrationController,
          BeamLab.PhoenixKitWeb.UserSessionController,
          BeamLab.PhoenixKitWeb.UserSettingsController
        ],
        "Components": [
          BeamLab.PhoenixKitWeb.CoreComponents
        ]
      ]
    ]
  end

  # Phoenix Code Reloader listeners (only in dev mode)
  defp listeners(:dev), do: [Phoenix.CodeReloader]
  defp listeners(_), do: []
end
