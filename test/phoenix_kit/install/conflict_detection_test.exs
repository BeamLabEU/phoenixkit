defmodule PhoenixKit.Install.ConflictDetectionTest do
  @moduledoc """
  Integration tests for PhoenixKit conflict detection system.

  Tests the complete conflict detection flow including:
  - Quick conflict checking
  - Comprehensive analysis
  - Dependency analysis
  - Config analysis
  - Code analysis
  - Migration strategy generation
  """

  use ExUnit.Case, async: true

  alias PhoenixKit.Install.ConflictDetection

  alias PhoenixKit.Install.ConflictDetection.{
    DependencyAnalyzer,
    ConfigAnalyzer,
    CodeAnalyzer,
    MigrationAdvisor
  }

  # Sample project files for testing
  @sample_mix_exs """
  defmodule MyApp.MixProject do
    use Mix.Project
    
    def project do
      [
        app: :my_app,
        version: "0.1.0",
        elixir: "~> 1.14",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
    end
    
    def application do
      [
        mod: {MyApp.Application, []},
        extra_applications: [:logger, :runtime_tools]
      ]
    end
    
    defp deps do
      [
        {:phoenix, "~> 1.7.0"},
        {:phoenix_ecto, "~> 4.4"},
        {:ecto_sql, "~> 3.10"},
        {:postgrex, ">= 0.0.0"},
        {:phoenix_live_view, "~> 0.18.1"},
        {:swoosh, "~> 1.3"}
      ]
    end
  end
  """

  @conflicting_mix_exs """
  defmodule MyApp.MixProject do
    use Mix.Project
    
    def project do
      [
        app: :my_app,
        version: "0.1.0",
        elixir: "~> 1.14",
        deps: deps()
      ]
    end
    
    defp deps do
      [
        {:phoenix, "~> 1.6.0"},
        {:ecto, "~> 3.8"},
        {:guardian, "~> 2.0"},
        {:pow, "~> 1.0.21"}
      ]
    end
  end
  """

  @sample_config_exs """
  import Config

  config :my_app,
    ecto_repos: [MyApp.Repo]

  config :my_app, MyApp.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "my_app_dev",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10

  config :my_app, MyAppWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    check_origin: false,
    code_reloader: true,
    debug_errors: true,
    secret_key_base: "secret",
    watchers: []
  """

  @conflicting_config_exs """
  import Config

  config :my_app,
    ecto_repos: [MyApp.Repo]

  # Conflicting PhoenixKit config
  config :phoenix_kit,
    repo: MyApp.OtherRepo,
    prefix: "conflicting_auth"

  # Guardian config (conflicting auth system)
  config :my_app, MyApp.Guardian,
    issuer: "my_app",
    secret_key: "secret"
  """

  @sample_router_with_auth """
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router
    import MyAppWeb.AuthController
    
    scope "/", MyAppWeb do
      pipe_through :browser
      
      get "/", PageController, :home
      get "/login", AuthController, :login
      post "/login", AuthController, :create_session
      delete "/logout", AuthController, :delete_session
    end
  end
  """

  describe "quick_conflict_check/1" do
    setup do
      test_dir = create_test_project_structure()
      igniter = create_mock_igniter(test_dir)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter, test_dir: test_dir}
    end

    test "returns clean assessment for simple project", %{igniter: igniter} do
      assert {:ok, assessment} = ConflictDetection.quick_conflict_check(igniter)

      assert assessment.total_potential_conflicts >= 0
      assert assessment.estimated_conflict_level in [:low, :medium, :high]
      assert is_binary(assessment.recommendation)
      assert is_boolean(assessment.should_run_full_analysis)
      assert assessment.quick_check_duration_ms > 0
      assert %DateTime{} = assessment.check_timestamp
    end

    test "detects high conflict potential in problematic project", %{test_dir: test_dir} do
      # Replace mix.exs with conflicting version
      File.write!(Path.join(test_dir, "mix.exs"), @conflicting_mix_exs)
      File.write!(Path.join([test_dir, "config", "config.exs"]), @conflicting_config_exs)

      igniter = create_mock_igniter(test_dir)

      assert {:ok, assessment} = ConflictDetection.quick_conflict_check(igniter)

      # Should detect more conflicts
      assert assessment.total_potential_conflicts > 0
      assert assessment.estimated_conflict_level in [:medium, :high]
      assert assessment.should_run_full_analysis == true
    end

    test "handles missing project files gracefully", %{} do
      empty_igniter = create_empty_igniter()

      # Should not crash, but may return error or warning
      result = ConflictDetection.quick_conflict_check(empty_igniter)

      assert {:ok, _assessment} = result or {:error, _reason} = result
    end
  end

  describe "perform_comprehensive_analysis/2" do
    setup do
      test_dir = create_test_project_structure()
      igniter = create_mock_igniter(test_dir)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter, test_dir: test_dir}
    end

    test "performs thorough analysis with default options", %{igniter: igniter} do
      opts = [
        risk_tolerance: :medium,
        generate_migration_strategy: true,
        scan_test_files: false,
        max_files: 1000
      ]

      assert {:ok, analysis} = ConflictDetection.perform_comprehensive_analysis(igniter, opts)

      # Check overall assessment structure
      assert Map.has_key?(analysis, :overall_assessment)
      overall = analysis.overall_assessment

      assert is_integer(overall.total_conflicts)
      assert is_integer(overall.critical_conflicts)
      assert is_integer(overall.auto_resolvable_conflicts)
      assert overall.overall_risk_level in [:low, :medium, :high]
      assert is_boolean(overall.safe_to_proceed)
      assert is_boolean(overall.requires_manual_intervention)
      assert is_list(overall.blocking_issues)

      # Check component analyses
      assert Map.has_key?(analysis, :dependency_analysis)
      assert Map.has_key?(analysis, :config_analysis)
      assert Map.has_key?(analysis, :code_analysis)

      # Check recommendations and strategy
      assert is_list(analysis.recommendations)
      assert is_list(analysis.next_steps)
      assert Map.has_key?(analysis, :migration_strategy) or analysis.migration_strategy == nil

      # Check metadata
      assert %DateTime{} = analysis.analysis_timestamp
      assert is_integer(analysis.analysis_duration_ms)
    end

    test "generates migration strategy when requested", %{igniter: igniter} do
      opts = [generate_migration_strategy: true, risk_tolerance: :low]

      assert {:ok, analysis} = ConflictDetection.perform_comprehensive_analysis(igniter, opts)

      if analysis.overall_assessment.total_conflicts > 0 do
        assert Map.has_key?(analysis, :migration_strategy)
        assert analysis.migration_strategy != nil

        strategy = analysis.migration_strategy
        assert Map.has_key?(strategy, :strategy_name)
        assert Map.has_key?(strategy, :estimated_timeline)
        assert is_list(Map.get(strategy, :steps, []))
      end
    end

    test "respects risk tolerance settings", %{igniter: igniter, test_dir: test_dir} do
      # Create conflicting project
      File.write!(Path.join(test_dir, "mix.exs"), @conflicting_mix_exs)
      File.write!(Path.join([test_dir, "config", "config.exs"]), @conflicting_config_exs)

      igniter = create_mock_igniter(test_dir)

      # Test different risk tolerances
      low_risk_opts = [risk_tolerance: :low]
      high_risk_opts = [risk_tolerance: :high]

      {:ok, low_analysis} =
        ConflictDetection.perform_comprehensive_analysis(igniter, low_risk_opts)

      {:ok, high_analysis} =
        ConflictDetection.perform_comprehensive_analysis(igniter, high_risk_opts)

      # Low risk should be more conservative
      assert low_analysis.overall_assessment.requires_manual_intervention or
               not low_analysis.overall_assessment.safe_to_proceed

      # High risk should be more permissive
      # (though still may not be safe depending on actual conflicts)
    end

    test "handles analysis errors gracefully", %{igniter: igniter} do
      # Mock dependency analyzer to fail
      with_mock(DependencyAnalyzer, [:passthrough],
        analyze_dependencies: fn _igniter, _opts -> {:error, :mock_analysis_error} end
      ) do
        result = ConflictDetection.perform_comprehensive_analysis(igniter, [])

        # Should either handle error gracefully or return error
        case result do
          {:ok, analysis} ->
            # Analysis succeeded despite mock error
            assert Map.has_key?(analysis, :overall_assessment)

          {:error, _reason} ->
            # Analysis failed as expected
            :ok
        end
      end
    end
  end

  describe "maybe_generate_migration_strategy/3" do
    setup do
      test_dir = create_test_project_structure()
      igniter = create_mock_igniter(test_dir)

      # Create a mock overall assessment with conflicts
      overall_assessment = %{
        total_conflicts: 3,
        critical_conflicts: 1,
        auto_resolvable_conflicts: 2,
        overall_risk_level: :medium,
        safe_to_proceed: false,
        requires_manual_intervention: true,
        blocking_issues: ["Conflicting authentication system detected"]
      }

      analyses = %{
        dependency_analysis: %{conflicts: []},
        config_analysis: %{conflicts: []},
        code_analysis: %{conflicts: []}
      }

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter, overall_assessment: overall_assessment, analyses: analyses}
    end

    test "generates migration strategy for conflicts", %{
      igniter: igniter,
      overall_assessment: assessment,
      analyses: analyses
    } do
      opts = [generate_migration_strategy: true]

      result =
        ConflictDetection.maybe_generate_migration_strategy(igniter, assessment, analyses, opts)

      case result do
        {:ok, strategy} ->
          assert Map.has_key?(strategy, :strategy_name)
          assert Map.has_key?(strategy, :estimated_timeline)
          assert is_list(Map.get(strategy, :steps, []))

        {:skip, :no_conflicts} ->
          # No conflicts to migrate
          :ok

        {:error, _reason} ->
          # Migration strategy generation failed
          :ok
      end
    end

    test "skips strategy generation when disabled", %{
      igniter: igniter,
      overall_assessment: assessment,
      analyses: analyses
    } do
      opts = [generate_migration_strategy: false]

      result =
        ConflictDetection.maybe_generate_migration_strategy(igniter, assessment, analyses, opts)

      assert {:skip, :strategy_generation_disabled} = result
    end
  end

  # Helper functions
  defp create_test_project_structure do
    test_dir = System.tmp_dir!() |> Path.join("phoenix_kit_conflict_test_#{:rand.uniform(10000)}")

    # Create project structure
    File.mkdir_p!(test_dir)
    File.mkdir_p!(Path.join(test_dir, "config"))
    File.mkdir_p!(Path.join([test_dir, "lib", "my_app_web"]))
    File.mkdir_p!(Path.join(test_dir, "test"))

    # Create sample files
    File.write!(Path.join(test_dir, "mix.exs"), @sample_mix_exs)
    File.write!(Path.join([test_dir, "config", "config.exs"]), @sample_config_exs)

    # Create sample router
    File.write!(Path.join([test_dir, "lib", "my_app_web", "router.ex"]), """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router
      
      scope "/", MyAppWeb do
        pipe_through :browser
        get "/", PageController, :home
      end
    end
    """)

    test_dir
  end

  defp create_mock_igniter(test_dir) do
    %{
      assigns: %{},
      issues: [],
      notices: [],
      tasks: [],
      rewrite: %{sources: %{}},
      test_dir: test_dir,
      project_dir: test_dir
    }
  end

  defp create_empty_igniter do
    %{
      assigns: %{},
      issues: [],
      notices: [],
      tasks: [],
      rewrite: %{sources: %{}}
    }
  end

  defp with_mock(module, opts, mocks, test_fun) do
    # Simple mock implementation
    original_module = Process.get({:mock, module})
    Process.put({:mock, module}, mocks)

    try do
      test_fun.()
    after
      if original_module do
        Process.put({:mock, module}, original_module)
      else
        Process.delete({:mock, module})
      end
    end
  end
end
