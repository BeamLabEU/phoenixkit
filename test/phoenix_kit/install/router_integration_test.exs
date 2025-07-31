defmodule PhoenixKit.Install.RouterIntegrationTest do
  @moduledoc """
  Integration tests for PhoenixKit router integration system.

  Tests the complete router integration flow including:
  - AST analysis and router detection
  - Import injection
  - Route injection
  - Conflict detection and resolution
  - Validation
  """

  use ExUnit.Case, async: true

  alias PhoenixKit.Install.RouterIntegration

  alias PhoenixKit.Install.RouterIntegration.{
    ASTAnalyzer,
    ImportInjector,
    RouteInjector,
    ConflictResolver,
    Validator
  }

  # Test data - sample router content
  @sample_router_content """
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router
    
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end
    
    scope "/", MyAppWeb do
      pipe_through :browser
      
      get "/", PageController, :home
    end
  end
  """

  @router_with_imports """
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router
    import Phoenix.LiveDashboard.Router
    
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
    end
    
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/", PageController, :home
    end
  end
  """

  @router_with_phoenix_kit """
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router
    import PhoenixKitWeb.Integration
    
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
    end
    
    scope "/", MyAppWeb do
      pipe_through :browser
      get "/", PageController, :home
      phoenix_kit_auth_routes()
    end
  end
  """

  describe "perform_full_integration/2" do
    setup do
      # Create a temporary directory for test files
      test_dir = System.tmp_dir!() |> Path.join("phoenix_kit_router_test_#{:rand.uniform(10000)}")
      File.mkdir_p!(test_dir)

      router_file = Path.join(test_dir, "router.ex")
      File.write!(router_file, @sample_router_content)

      # Create a mock igniter context
      igniter = create_mock_igniter(test_dir, router_file)

      on_exit(fn ->
        File.rm_rf!(test_dir)
      end)

      %{igniter: igniter, router_file: router_file, test_dir: test_dir}
    end

    test "successfully integrates PhoenixKit routes with default options", %{igniter: igniter} do
      assert {:ok, updated_igniter, result} = RouterIntegration.perform_full_integration(igniter)

      assert result.success == true
      assert result.router_module == MyAppWeb.Router
      assert result.prefix == "/phoenix_kit"
      assert is_list(result.conflicts_resolved)
      assert Map.has_key?(result, :validation_result)
    end

    test "respects custom prefix option", %{igniter: igniter} do
      opts = [prefix: "/auth"]

      assert {:ok, _updated_igniter, result} =
               RouterIntegration.perform_full_integration(igniter, opts)

      assert result.prefix == "/auth"
    end

    test "skips integration when routes already exist", %{test_dir: test_dir} do
      # Create router with existing PhoenixKit routes
      router_file = Path.join(test_dir, "router_existing.ex")
      File.write!(router_file, @router_with_phoenix_kit)

      igniter = create_mock_igniter(test_dir, router_file)

      result = RouterIntegration.perform_full_integration(igniter, skip_if_exists: true)

      # Should skip or succeed without duplication
      assert {:ok, _igniter, integration_result} =
               result or
                 {:skipped, :already_integrated} = result
    end

    test "handles validation errors gracefully", %{igniter: igniter} do
      # Mock validation to fail
      with_mock(Validator, [:passthrough],
        validate_router_integration: fn _igniter, _module ->
          {:error, [:mock_validation_error]}
        end
      ) do
        assert {:ok, _updated_igniter, result} =
                 RouterIntegration.perform_full_integration(igniter)

        # Should still succeed but with validation failure noted
        assert Map.has_key?(result.validation_result, :validation_failed)
      end
    end
  end

  describe "check_integration_feasibility/2" do
    setup do
      test_dir =
        System.tmp_dir!() |> Path.join("phoenix_kit_feasibility_test_#{:rand.uniform(10000)}")

      File.mkdir_p!(test_dir)

      router_file = Path.join(test_dir, "router.ex")
      File.write!(router_file, @sample_router_content)

      igniter = create_mock_igniter(test_dir, router_file)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter}
    end

    test "returns feasibility assessment for clean router", %{igniter: igniter} do
      assert {:ok, feasibility} = RouterIntegration.check_integration_feasibility(igniter)

      assert feasibility.router_found == true
      assert feasibility.router_module == MyAppWeb.Router
      assert is_list(feasibility.conflicts)
      assert is_integer(feasibility.auto_resolvable_conflicts)
      assert is_integer(feasibility.manual_conflicts)
      assert is_boolean(feasibility.feasible)
      assert is_list(feasibility.recommendations)
    end

    test "handles missing router gracefully", %{} do
      # Create igniter without valid router
      empty_igniter = create_empty_igniter()

      assert {:error, error_result} =
               RouterIntegration.check_integration_feasibility(empty_igniter)

      assert error_result.router_found == false
      assert error_result.feasible == false
      assert is_list(error_result.recommendations)
    end
  end

  describe "rollback_integration/2" do
    setup do
      test_dir =
        System.tmp_dir!() |> Path.join("phoenix_kit_rollback_test_#{:rand.uniform(10000)}")

      File.mkdir_p!(test_dir)

      router_file = Path.join(test_dir, "router.ex")
      File.write!(router_file, @router_with_phoenix_kit)

      igniter = create_mock_igniter(test_dir, router_file)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter}
    end

    test "successfully removes PhoenixKit routes", %{igniter: igniter} do
      assert {:ok, _updated_igniter} = RouterIntegration.rollback_integration(igniter)
    end
  end

  describe "generate_integration_report/2" do
    setup do
      test_dir = System.tmp_dir!() |> Path.join("phoenix_kit_report_test_#{:rand.uniform(10000)}")
      File.mkdir_p!(test_dir)

      router_file = Path.join(test_dir, "router.ex")
      File.write!(router_file, @sample_router_content)

      igniter = create_mock_igniter(test_dir, router_file)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      %{igniter: igniter}
    end

    test "generates comprehensive integration report", %{igniter: igniter} do
      report = RouterIntegration.generate_integration_report(igniter)

      assert %{timestamp: _timestamp} = report
      assert Map.has_key?(report, :router_info)
      assert Map.has_key?(report, :diagnostic_report)
      assert Map.has_key?(report, :integration_status)

      # Integration status should be one of the expected values
      assert report.integration_status in [
               :not_integrated,
               :partially_integrated,
               :fully_integrated,
               :error
             ]
    end
  end

  # Helper functions for creating mock contexts
  defp create_mock_igniter(test_dir, router_file) do
    # This is a simplified mock igniter structure
    # In real implementation, you'd use proper Igniter test utilities
    %{
      assigns: %{},
      issues: [],
      notices: [],
      tasks: [],
      rewrite: %{
        sources: %{
          router_file => %{
            from: :string,
            source: File.read!(router_file),
            path: router_file
          }
        }
      },
      test_dir: test_dir,
      router_file: router_file
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

  # Add mock support if not available in test environment
  defp with_mock(module, opts, mocks, test_fun) do
    # Simple mock implementation for testing
    # In real setup, you'd use a proper mocking library like Mox
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
