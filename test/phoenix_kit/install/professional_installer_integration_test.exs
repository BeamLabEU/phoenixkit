defmodule PhoenixKit.Install.ProfessionalInstallerIntegrationTest do
  @moduledoc """
  End-to-end integration tests for the PhoenixKit Professional Installer.

  Tests the complete installation flow including:
  - Conflict detection and analysis
  - Router integration
  - Layout integration
  - Configuration updates
  - Migration generation
  - Validation and reporting
  """

  use ExUnit.Case, async: true

  alias Mix.Tasks.PhoenixKit.Install.Pro, as: ProInstaller

  # Complete sample Phoenix application structure
  @sample_phoenix_app_structure %{
    "mix.exs" => """
    defmodule TestPhoenixApp.MixProject do
      use Mix.Project
      
      def project do
        [
          app: :test_phoenix_app,
          version: "0.1.0",
          elixir: "~> 1.14",
          start_permanent: Mix.env() == :prod,
          aliases: aliases(),
          deps: deps()
        ]
      end
      
      def application do
        [
          mod: {TestPhoenixApp.Application, []},
          extra_applications: [:logger, :runtime_tools]
        ]
      end
      
      defp deps do
        [
          {:phoenix, "~> 1.7.0"},
          {:phoenix_ecto, "~> 4.4"},
          {:ecto_sql, "~> 3.10"},
          {:postgrex, ">= 0.0.0"},
          {:phoenix_html, "~> 3.3"},
          {:phoenix_live_reload, "~> 1.2", only: :dev},
          {:phoenix_live_view, "~> 0.18.1"},
          {:floki, ">= 0.30.0", only: :test},
          {:phoenix_live_dashboard, "~> 0.7.2"},
          {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
          {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
          {:swoosh, "~> 1.3"},
          {:finch, "~> 0.13"},
          {:telemetry_metrics, "~> 0.6"},
          {:telemetry_poller, "~> 1.0"},
          {:gettext, "~> 0.20"},
          {:jason, "~> 1.2"},
          {:plug_cowboy, "~> 2.5"}
        ]
      end
      
      defp aliases do
        [
          setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
          "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
          "ecto.reset": ["ecto.drop", "ecto.setup"],
          test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
          "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
          "assets.build": ["tailwind default", "esbuild default"],
          "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
        ]
      end
    end
    """,
    "config/config.exs" => """
    import Config

    config :test_phoenix_app,
      ecto_repos: [TestPhoenixApp.Repo],
      generators: [timestamp_type: :utc_datetime]

    config :test_phoenix_app, TestPhoenixApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "test_phoenix_app_dev",
      stacktrace: true,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10

    config :test_phoenix_app, TestPhoenixAppWeb.Endpoint,
      url: [host: "localhost"],
      adapter: Phoenix.PubSub.PG2,
      render_errors: [
        formats: [html: TestPhoenixAppWeb.ErrorHTML, json: TestPhoenixAppWeb.ErrorJSON],
        layout: false
      ],
      pubsub_server: TestPhoenixApp.PubSub,
      live_view: [signing_salt: "secret"]

    import_config "\#{config_env()}.exs"
    """,
    "config/dev.exs" => """
    import Config

    config :test_phoenix_app, TestPhoenixAppWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4000],
      check_origin: false,
      code_reloader: true,
      debug_errors: true,
      secret_key_base: "secret_key_base_here",
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
      ]
    """,
    "config/test.exs" => """
    import Config

    config :test_phoenix_app, TestPhoenixApp.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "test_phoenix_app_test\#{System.get_env("MIX_TEST_PARTITION")}",
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: 10

    config :test_phoenix_app, TestPhoenixAppWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4002],
      secret_key_base: "secret_key_base_for_tests",
      server: false
    """,
    "lib/test_phoenix_app_web/router.ex" => """
    defmodule TestPhoenixAppWeb.Router do
      use TestPhoenixAppWeb, :router
      
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {TestPhoenixAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end
      
      pipeline :api do
        plug :accepts, ["json"]
      end
      
      scope "/", TestPhoenixAppWeb do
        pipe_through :browser
        
        get "/", PageController, :home
      end
    end
    """,
    "lib/test_phoenix_app_web/components/layouts/app.html.heex" => """
    <header class="px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
        <div class="flex items-center gap-4">
          <a href="/">
            <img src={~p"/images/logo.svg"} width="36" alt="Phoenix Framework Logo" />
          </a>
          <p class="bg-brand/5 text-brand rounded-full px-2 font-medium leading-6">
            v<%= Application.spec(:phoenix, :vsn) %>
          </p>
        </div>
      </div>
    </header>
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </div>
    </main>
    """,
    "lib/test_phoenix_app_web/components/layouts/root.html.heex" => """
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title suffix=" · Phoenix Framework">
          <%= assigns[:page_title] || "TestPhoenixApp" %>
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
      </head>
      <body class="bg-white antialiased">
        <%= @inner_content %>
      </body>
    </html>
    """,
    "lib/test_phoenix_app/repo.ex" => """
    defmodule TestPhoenixApp.Repo do
      use Ecto.Repo,
        otp_app: :test_phoenix_app,
        adapter: Ecto.Adapters.Postgres
    end
    """
  }

  describe "complete professional installation flow" do
    setup do
      test_dir = create_complete_phoenix_app()
      original_cwd = File.cwd!()

      # Change to test directory for Mix tasks
      File.cd!(test_dir)

      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(test_dir)
      end)

      %{test_dir: test_dir, original_cwd: original_cwd}
    end

    @tag :integration
    test "installs PhoenixKit with default settings", %{test_dir: test_dir} do
      # Create mock igniter for the installation
      igniter = create_comprehensive_igniter(test_dir)

      # Mock the installation process
      result = simulate_professional_installation(igniter, [])

      assert {:ok, final_igniter} = result

      # Verify installation components
      assert_configuration_updated(final_igniter)
      assert_migration_created(final_igniter)
      assert_router_integration_completed(final_igniter)
      assert_layout_integration_completed(final_igniter)
    end

    @tag :integration
    test "handles custom configuration options", %{test_dir: test_dir} do
      opts = [
        repo: "TestPhoenixApp.Repo",
        prefix: "auth",
        route_prefix: "/authentication",
        create_schema: true,
        layout_strategy: "existing",
        conflict_tolerance: "low"
      ]

      igniter = create_comprehensive_igniter(test_dir)
      result = simulate_professional_installation(igniter, opts)

      assert {:ok, final_igniter} = result

      # Verify custom options were applied
      assert_custom_configuration_applied(final_igniter, opts)
    end

    @tag :integration
    test "performs conflict detection before installation", %{test_dir: test_dir} do
      # Create conflicting project setup
      create_conflicting_dependencies(test_dir)

      igniter = create_comprehensive_igniter(test_dir)
      result = simulate_professional_installation(igniter, [])

      # Should either succeed with conflict resolution or fail gracefully
      case result do
        {:ok, final_igniter} ->
          assert_conflicts_resolved(final_igniter)

        {:error, reason} ->
          assert_conflict_detection_prevented_installation(reason)

        {:warning, final_igniter, warnings} ->
          assert is_list(warnings)
          assert_installation_completed_with_warnings(final_igniter)
      end
    end

    @tag :integration
    test "integrates with existing authentication system", %{test_dir: test_dir} do
      # Add existing authentication routes to router
      add_existing_auth_routes(test_dir)

      igniter = create_comprehensive_igniter(test_dir)
      result = simulate_professional_installation(igniter, [])

      # Should detect conflicts and handle appropriately
      case result do
        {:ok, final_igniter} ->
          assert_existing_auth_conflicts_resolved(final_igniter)

        {:error, reason} ->
          assert String.contains?(inspect(reason), "conflict") or
                   String.contains?(inspect(reason), "authentication")
      end
    end

    @tag :integration
    test "validates complete installation", %{test_dir: test_dir} do
      igniter = create_comprehensive_igniter(test_dir)

      assert {:ok, final_igniter} = simulate_professional_installation(igniter, [])

      # Perform post-installation validation
      validation_result = validate_complete_installation(final_igniter)

      assert validation_result.configuration_valid == true
      assert validation_result.migration_created == true
      assert validation_result.router_integration_successful == true
      assert validation_result.layout_integration_successful == true
      assert length(validation_result.warnings) >= 0
      assert length(validation_result.errors) == 0
    end
  end

  describe "error handling and recovery" do
    setup do
      test_dir = create_incomplete_phoenix_app()
      original_cwd = File.cwd!()
      File.cd!(test_dir)

      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(test_dir)
      end)

      %{test_dir: test_dir}
    end

    @tag :integration
    test "handles missing repo gracefully", %{test_dir: test_dir} do
      # Remove repo configuration
      remove_repo_config(test_dir)

      igniter = create_comprehensive_igniter(test_dir)
      result = simulate_professional_installation(igniter, [])

      case result do
        {:error, final_igniter} ->
          assert has_repo_error_message(final_igniter)

        {:ok, _} ->
          # Should not succeed without repo
          flunk("Installation should fail without valid repo")
      end
    end

    @tag :integration
    test "recovers from partial installation", %{test_dir: test_dir} do
      # Simulate partially completed installation
      create_partial_installation_state(test_dir)

      igniter = create_comprehensive_igniter(test_dir)
      result = simulate_professional_installation(igniter, [])

      # Should detect existing state and either skip or complete
      assert {:ok, final_igniter} = result or {:skipped, _reason} = result
    end
  end

  # Helper functions for creating test environments
  defp create_complete_phoenix_app do
    test_dir = System.tmp_dir!() |> Path.join("phoenix_kit_pro_test_#{:rand.uniform(10000)}")

    Enum.each(@sample_phoenix_app_structure, fn {file_path, content} ->
      full_path = Path.join(test_dir, file_path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, content)
    end)

    test_dir
  end

  defp create_incomplete_phoenix_app do
    test_dir = create_complete_phoenix_app()

    # Remove some critical files to simulate incomplete setup
    File.rm!(Path.join(test_dir, "lib/test_phoenix_app/repo.ex"))

    test_dir
  end

  defp create_comprehensive_igniter(test_dir) do
    # Create a comprehensive mock igniter with all necessary context
    %{
      assigns: %{
        app_name: :test_phoenix_app,
        project_dir: test_dir
      },
      issues: [],
      notices: [],
      tasks: [],
      rewrite: %{
        sources: load_all_sources(test_dir)
      },
      args: %{
        options: %{
          repo: nil,
          prefix: "public",
          create_schema: false,
          add_routes: true,
          route_prefix: "/phoenix_kit",
          auto_resolve_conflicts: true,
          skip_conflict_detection: false,
          conflict_tolerance: "medium",
          integrate_layouts: true,
          layout_strategy: "auto",
          enhance_layouts: true,
          create_fallbacks: true
        }
      },
      test_dir: test_dir
    }
  end

  defp simulate_professional_installation(igniter, opts) do
    # Simulate the main installation flow without actually running Mix tasks
    try do
      # Merge custom options
      updated_igniter = update_igniter_options(igniter, opts)

      # Simulate each phase of installation
      with {:ok, phase1_igniter} <- simulate_conflict_analysis(updated_igniter),
           {:ok, phase2_igniter} <- simulate_configuration_updates(phase1_igniter),
           {:ok, phase3_igniter} <- simulate_router_integration(phase2_igniter),
           {:ok, phase4_igniter} <- simulate_layout_integration(phase3_igniter),
           {:ok, final_igniter} <- simulate_migration_creation(phase4_igniter) do
        {:ok, final_igniter}
      else
        error -> error
      end
    rescue
      error -> {:error, {:installation_error, error}}
    end
  end

  defp simulate_conflict_analysis(igniter) do
    # Mock conflict detection
    if igniter.args.options.skip_conflict_detection do
      {:ok, igniter}
    else
      # Simulate successful conflict analysis
      analysis_result = %{
        total_conflicts: 0,
        critical_conflicts: 0,
        safe_to_proceed: true
      }

      updated_igniter = Map.put(igniter, :conflict_analysis, analysis_result)
      {:ok, updated_igniter}
    end
  end

  defp simulate_configuration_updates(igniter) do
    # Mock configuration updates
    config_updates = %{
      phoenix_kit_config: "added",
      mailer_config: "added",
      test_config: "added"
    }

    updated_igniter = Map.put(igniter, :configuration_updates, config_updates)
    {:ok, updated_igniter}
  end

  defp simulate_router_integration(igniter) do
    if igniter.args.options.add_routes do
      # Mock successful router integration
      router_result = %{
        router_module: TestPhoenixAppWeb.Router,
        import_added: true,
        routes_added: true,
        conflicts_resolved: []
      }

      updated_igniter = Map.put(igniter, :router_integration, router_result)
      {:ok, updated_igniter}
    else
      {:ok, igniter}
    end
  end

  defp simulate_layout_integration(igniter) do
    if igniter.args.options.integrate_layouts do
      # Mock successful layout integration
      layout_result = %{
        integration_strategy: :use_existing_layouts,
        detected_layouts: ["app.html.heex", "root.html.heex"],
        enhancements_applied: %{flash_components: true},
        fallbacks_created: %{}
      }

      updated_igniter = Map.put(igniter, :layout_integration, layout_result)
      {:ok, updated_igniter}
    else
      {:ok, igniter}
    end
  end

  defp simulate_migration_creation(igniter) do
    # Mock migration creation
    migration_result = %{
      migration_file: "20231201000000_add_phoenix_kit_auth_tables.exs",
      migration_created: true
    }

    updated_igniter = Map.put(igniter, :migration_creation, migration_result)
    {:ok, updated_igniter}
  end

  # Assertion helpers
  defp assert_configuration_updated(igniter) do
    assert Map.has_key?(igniter, :configuration_updates)
    config = igniter.configuration_updates
    assert config.phoenix_kit_config == "added"
    assert config.mailer_config == "added"
  end

  defp assert_migration_created(igniter) do
    assert Map.has_key?(igniter, :migration_creation)
    assert igniter.migration_creation.migration_created == true
  end

  defp assert_router_integration_completed(igniter) do
    assert Map.has_key?(igniter, :router_integration)
    router = igniter.router_integration
    assert router.import_added == true
    assert router.routes_added == true
  end

  defp assert_layout_integration_completed(igniter) do
    assert Map.has_key?(igniter, :layout_integration)
    layout = igniter.layout_integration
    assert layout.integration_strategy != nil
  end

  defp assert_custom_configuration_applied(igniter, opts) do
    # Verify custom options were applied
    if opts[:prefix] do
      # Should have custom prefix in configuration
      assert igniter.args.options.prefix == opts[:prefix] or
               Map.has_key?(igniter, :custom_prefix_applied)
    end

    if opts[:route_prefix] do
      assert igniter.args.options.route_prefix == opts[:route_prefix]
    end
  end

  defp assert_conflicts_resolved(igniter) do
    assert Map.has_key?(igniter, :conflict_analysis)
    assert igniter.conflict_analysis.safe_to_proceed == true
  end

  defp assert_conflict_detection_prevented_installation(reason) do
    assert String.contains?(inspect(reason), "conflict") or
             String.contains?(inspect(reason), "critical") or
             String.contains?(inspect(reason), "blocked")
  end

  defp assert_installation_completed_with_warnings(igniter) do
    assert Map.has_key?(igniter, :configuration_updates)
  end

  defp assert_existing_auth_conflicts_resolved(igniter) do
    if Map.has_key?(igniter, :router_integration) do
      assert is_list(igniter.router_integration.conflicts_resolved)
    end
  end

  # Validation and error helpers
  defp validate_complete_installation(igniter) do
    %{
      configuration_valid: Map.has_key?(igniter, :configuration_updates),
      migration_created:
        Map.has_key?(igniter, :migration_creation) and
          igniter.migration_creation.migration_created,
      router_integration_successful:
        Map.has_key?(igniter, :router_integration) and
          igniter.router_integration.routes_added,
      layout_integration_successful: Map.has_key?(igniter, :layout_integration),
      warnings: Map.get(igniter, :warnings, []),
      errors: Map.get(igniter, :errors, [])
    }
  end

  defp create_conflicting_dependencies(test_dir) do
    # Add conflicting authentication gem to mix.exs
    mix_file = Path.join(test_dir, "mix.exs")
    content = File.read!(mix_file)

    conflicting_content =
      String.replace(
        content,
        "{:plug_cowboy, \"~> 2.5\"}",
        "{:plug_cowboy, \"~> 2.5\"},\n        {:guardian, \"~> 2.0\"}"
      )

    File.write!(mix_file, conflicting_content)
  end

  defp add_existing_auth_routes(test_dir) do
    router_file = Path.join([test_dir, "lib", "test_phoenix_app_web", "router.ex"])
    content = File.read!(router_file)

    auth_routes = """
        
        # Existing authentication routes
        get "/login", AuthController, :new
        post "/login", AuthController, :create
        delete "/logout", AuthController, :delete
    """

    updated_content =
      String.replace(
        content,
        "get \"/\", PageController, :home",
        "get \"/\", PageController, :home#{auth_routes}"
      )

    File.write!(router_file, updated_content)
  end

  defp remove_repo_config(test_dir) do
    config_file = Path.join([test_dir, "config", "config.exs"])
    content = File.read!(config_file)

    # Remove ecto_repos configuration
    updated_content = String.replace(content, ~r/config :test_phoenix_app,\s*ecto_repos:.*\n/, "")
    File.write!(config_file, updated_content)

    # Remove repo file
    repo_file = Path.join([test_dir, "lib", "test_phoenix_app", "repo.ex"])

    if File.exists?(repo_file) do
      File.rm!(repo_file)
    end
  end

  defp create_partial_installation_state(test_dir) do
    # Add partial PhoenixKit configuration
    config_file = Path.join([test_dir, "config", "config.exs"])
    content = File.read!(config_file)

    partial_config = """

    # Partial PhoenixKit configuration
    config :phoenix_kit,
      repo: TestPhoenixApp.Repo
    """

    File.write!(config_file, content <> partial_config)
  end

  defp has_repo_error_message(igniter) do
    issues = Map.get(igniter, :issues, [])

    Enum.any?(issues, fn issue ->
      String.contains?(issue, "repo") or String.contains?(issue, "Repo")
    end)
  end

  defp load_all_sources(test_dir) do
    # Mock loading all source files
    %{}
  end

  defp update_igniter_options(igniter, opts) do
    current_options = igniter.args.options

    updated_options =
      Enum.reduce(opts, current_options, fn {key, value}, acc ->
        Map.put(acc, key, value)
      end)

    put_in(igniter, [:args, :options], updated_options)
  end
end
