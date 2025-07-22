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
      
      # Phoenix Code Reloader (only for standalone dev mode) 
      listeners: listeners(),
      
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
    # ВСЕГДА по умолчанию library режим для безопасной установки как зависимость
    case Application.get_env(:phoenix_kit, :mode) do
      :standalone -> :standalone  # Только если явно указано
      _ -> :library  # По умолчанию library
    end
  end
  
  # Check if this is the main project being compiled (not a dependency)
  defp is_main_project? do
    # Multiple checks to ensure this is the main PhoenixKit project
    cond do
      # Check if we're in a deps directory (compiled as dependency)
      String.contains?(File.cwd!(), "/deps/phoenix_kit") -> false
      
      # Check if this app is phoenix_kit AND we're in the right directory
      Mix.Project.config()[:app] == :phoenix_kit and 
      Path.basename(File.cwd!()) == "phoenix_kit" -> true
      
      # Check if Mix.Project.deps includes phoenix_kit (we're a dependency)
      Enum.any?(Mix.Project.deps_paths(), fn {app, _path} -> app == :phoenix_kit end) -> false
      
      # Default: if app name is phoenix_kit, assume it's main project
      Mix.Project.config()[:app] == :phoenix_kit -> true
      
      # Otherwise, we're definitely a library
      true -> false
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    base_deps() ++ mode_specific_deps(phoenix_kit_mode())
  end

  defp base_deps do
    [
      # Минимальные CORE библиотеки для аутентификации
      {:bcrypt_elixir, "~> 3.3"},
      {:gettext, "~> 0.26"},
      
      # DEVELOPMENT dependencies  
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  # Mode-specific dependencies
  defp mode_specific_deps(:standalone) do
    [
      # Standalone mode: Use specific Phoenix versions for compatibility
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:tailwind, "~> 0.3"},
      
      # Standalone runtime dependencies
      {:bandit, "~> 1.5"},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      # Development dependencies (only for standalone)
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev}
    ]
  end
  
  defp mode_specific_deps(:library) do
    [
      # Library mode: Минимальные зависимости, используем версии родительского приложения
      {:phoenix, ">= 1.6.0", optional: true},
      {:phoenix_live_view, ">= 0.18.0", optional: true},
      {:phoenix_ecto, ">= 4.0.0", optional: true},
      {:ecto_sql, ">= 3.0.0", optional: true},
      {:phoenix_html, ">= 3.0.0", optional: true},
      {:jason, ">= 1.0.0", optional: true},
      
      # UI зависимости (полностью опциональные)
      {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.1", optional: true, sparse: "optimized", app: false, compile: false},
      {:tailwind, "~> 0.3", optional: true},
      {:esbuild, "~> 0.9", optional: true}
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

  # Phoenix Code Reloader listeners (only for standalone dev mode)
  defp listeners() do
    # Safely determine if we should add listeners without calling potentially problematic functions
    cond do
      # Only add listeners if we're in dev environment AND this is the main project
      Mix.env() == :dev and is_main_project_safe?() ->
        # Use proper child_spec for Phoenix.CodeReloader
        [%{
          id: Phoenix.CodeReloader,
          start: {Phoenix.CodeReloader, :start_link, []},
          type: :worker,
          restart: :permanent,
          shutdown: 5000
        }]
      
      # In all other cases, no listeners
      true -> []
    end
  end
  
  # Safe version of is_main_project that won't fail during dependency compilation
  defp is_main_project_safe? do
    try do
      is_main_project?()
    rescue
      _ -> false
    end
  end
end
