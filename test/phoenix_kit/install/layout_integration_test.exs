defmodule PhoenixKit.Install.LayoutIntegrationTest do
  @moduledoc """
  Integration tests for PhoenixKit layout integration system.
  
  Tests the complete layout integration flow including:
  - Layout detection
  - Auto-configuration
  - Layout enhancement
  - Fallback creation
  - Compatibility assessment
  """
  
  use ExUnit.Case, async: true
  
  alias PhoenixKit.Install.LayoutIntegration
  alias PhoenixKit.Install.LayoutIntegration.{
    LayoutDetector,
    AutoConfigurator,
    LayoutEnhancer,
    FallbackHandler
  }
  
  # Sample layout templates for testing
  @sample_app_layout """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>My App</title>
      <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    </head>
    <body>
      <header class="px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between border-b border-zinc-100 py-3">
          <div class="flex items-center gap-4">
            <a href="/">
              <img src={~p"/images/logo.svg"} width="36" />
            </a>
          </div>
        </div>
      </header>
      <main class="px-4 py-20 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-2xl">
          <.flash_group flash={@flash} />
          <%= @inner_content %>
        </div>
      </main>
      <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
    </body>
  </html>
  """
  
  @sample_root_layout """
  <!DOCTYPE html>
  <html lang="en" class="[scrollbar-gutter:stable]">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="csrf-token" content={get_csrf_token()} />
      <.live_title suffix=" · Phoenix Framework">
        <%= assigns[:page_title] || "MyApp" %>
      </.live_title>
      <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
      <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
    </head>
    <body class="bg-white antialiased">
      <%= @inner_content %>
    </body>
  </html>
  """
  
  @old_style_layout """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="utf-8"/>
      <title>Old App</title>
      <link rel="stylesheet" href="/css/app.css"/>
    </head>
    <body>
      <%= if flash[:info] do %>
        <div class="alert alert-info" role="alert">
          <%= flash[:info] %>
        </div>
      <% end %>
      <%= if flash[:error] do %>
        <div class="alert alert-danger" role="alert">
          <%= flash[:error] %>
        </div>
      <% end %>
      
      <main role="main">
        <%= @inner_content %>
      </main>
      
      <script src="/js/app.js"></script>
    </body>
  </html>
  """
  
  describe "perform_full_integration/2" do
    setup do
      test_dir = create_test_layout_structure()
      igniter = create_mock_igniter(test_dir)
      
      on_exit(fn -> File.rm_rf!(test_dir) end)
      
      %{igniter: igniter, test_dir: test_dir}
    end
    
    test "successfully integrates with complete layout system", %{igniter: igniter} do
      opts = [
        enhance_layouts: true,
        create_fallbacks: true,
        layout_preference: :auto
      ]
      
      assert {:ok, updated_igniter, result} = LayoutIntegration.perform_full_integration(igniter, opts)
      
      assert is_list(result.detected_layouts)
      assert result.integration_strategy in [:use_existing_layouts, :enhance_existing_layouts, :create_phoenix_kit_layouts, :hybrid_integration]
      assert Map.has_key?(result, :configuration_updates)
      assert Map.has_key?(result, :enhancements_applied)
      assert Map.has_key?(result, :fallbacks_created)
      assert is_list(result.recommendations)
      assert is_list(result.next_steps)
      assert %DateTime{} = result.integration_timestamp
      assert is_integer(result.integration_duration_ms)
    end
    
    test "respects layout preference option", %{igniter: igniter} do
      opts = [layout_preference: :existing]
      
      assert {:ok, _updated_igniter, result} = LayoutIntegration.perform_full_integration(igniter, opts)
      
      # Should prefer existing layouts
      assert result.integration_strategy == :use_existing_layouts
    end
    
    test "handles enhancement disabled option", %{igniter: igniter} do
      opts = [enhance_layouts: false]
      
      assert {:ok, _updated_igniter, result} = LayoutIntegration.perform_full_integration(igniter, opts)
      
      assert Map.get(result.enhancements_applied, :enhancements_skipped) == true or
             result.enhancements_applied == %{}
    end
    
    test "handles fallback creation disabled", %{igniter: igniter} do
      opts = [create_fallbacks: false]
      
      assert {:ok, _updated_igniter, result} = LayoutIntegration.perform_full_integration(igniter, opts)
      
      assert Map.get(result.fallbacks_created, :fallbacks_skipped) == true or
             result.fallbacks_created == %{}
    end
    
    test "handles integration errors gracefully", %{igniter: igniter} do
      # Mock layout detector to fail
      with_mock(LayoutDetector, [:passthrough], [
        detect_existing_layouts: fn _igniter -> {:error, :mock_detection_error} end
      ]) do
        result = LayoutIntegration.perform_full_integration(igniter)
        
        assert {:error, :mock_detection_error} = result
      end
    end
  end
  
  describe "quick_layout_check/1" do
    setup do
      test_dir = create_test_layout_structure()
      igniter = create_mock_igniter(test_dir)
      
      on_exit(fn -> File.rm_rf!(test_dir) end)
      
      %{igniter: igniter}
    end
    
    test "provides quick assessment of layout structure", %{igniter: igniter} do
      assert {:ok, assessment} = LayoutIntegration.quick_layout_check(igniter)
      
      assert is_boolean(assessment.has_app_layout)
      assert is_boolean(assessment.has_root_layout)
      assert is_list(assessment.layout_files)
      assert is_boolean(assessment.existing_phoenix_kit_config)
      assert assessment.integration_complexity in [:simple, :moderate, :complex]
      assert is_binary(assessment.recommendation)
      assert is_boolean(assessment.should_run_full_integration)
    end
    
    test "handles scan errors gracefully", %{} do
      # Test with non-existent directory
      empty_igniter = create_empty_igniter()
      
      assert {:ok, assessment} = LayoutIntegration.quick_layout_check(empty_igniter)
      
      assert Map.has_key?(assessment, :has_errors) or
             assessment.should_run_full_integration == true
    end
  end
  
  describe "assess_layout_compatibility/1" do
    setup do
      # Create mock layout analysis
      layout_analysis = %{
        detected_layouts: ["app.html.heex", "root.html.heex"],
        has_complete_layout_system: true,
        has_partial_layouts: false,
        has_no_layouts: false,
        compatibility_issues: false,
        phoenix_version: "1.7.0",
        uses_liveview: true,
        css_framework: :tailwind,
        component_system: :phoenix_component
      }
      
      %{layout_analysis: layout_analysis}
    end
    
    test "assesses compatibility correctly", %{layout_analysis: layout_analysis} do
      assert {:ok, compatibility} = LayoutIntegration.assess_layout_compatibility(layout_analysis)
      
      assert is_boolean(compatibility.fully_compatible)
      assert is_integer(compatibility.compatibility_score)
      assert compatibility.compatibility_score >= 0 and compatibility.compatibility_score <= 100
      assert is_list(compatibility.blocking_issues)
      assert is_list(compatibility.enhancement_opportunities)
      assert is_list(compatibility.migration_requirements)
    end
  end
  
  describe "generate_integration_report/2" do
    setup do
      integration_result = %{
        integration_timestamp: DateTime.utc_now(),
        integration_duration_ms: 1500,
        detected_layouts: ["app.html.heex", "root.html.heex"],
        integration_strategy: :use_existing_layouts,
        configuration_updates: %{phoenix_kit_config: "updated"},
        enhancements_applied: %{flash_components: "added"},
        fallbacks_created: %{},
        recommendations: ["Layout integration successful"],
        next_steps: ["Test authentication pages"]
      }
      
      %{integration_result: integration_result}
    end
    
    test "generates summary report", %{integration_result: result} do
      report = LayoutIntegration.generate_integration_report(result, :summary)
      
      assert is_binary(report)
      assert String.contains?(report, "Layout Integration Summary")
      assert String.contains?(report, "Integration Date:")
      assert String.contains?(report, "Strategy:")
      assert String.contains?(report, "Next Steps")
    end
    
    test "generates detailed report", %{integration_result: result} do
      report = LayoutIntegration.generate_integration_report(result, :detailed)
      
      assert is_binary(report)
      assert String.contains?(report, "Layout Integration Summary")
      assert String.length(report) > String.length(LayoutIntegration.generate_integration_report(result, :summary))
    end
    
    test "generates technical report", %{integration_result: result} do
      report = LayoutIntegration.generate_integration_report(result, :technical)
      
      assert is_binary(report)
      assert String.contains?(report, "Layout Integration Summary")
    end
  end
  
  # Helper functions
  defp create_test_layout_structure do
    test_dir = System.tmp_dir!() |> Path.join("phoenix_kit_layout_test_#{:rand.uniform(10000)}")
    
    # Create directory structure
    layouts_dir = Path.join([test_dir, "lib", "my_app_web", "components", "layouts"])
    File.mkdir_p!(layouts_dir)
    
    # Create sample layout files
    File.write!(Path.join(layouts_dir, "app.html.heex"), @sample_app_layout)
    File.write!(Path.join(layouts_dir, "root.html.heex"), @sample_root_layout)
    
    # Create config directory
    config_dir = Path.join(test_dir, "config")
    File.mkdir_p!(config_dir)
    File.write!(Path.join(config_dir, "config.exs"), "# Config file\n")
    
    test_dir
  end
  
  defp create_test_layout_structure_with_old_style do
    test_dir = create_test_layout_structure()
    
    # Add old style layout
    layouts_dir = Path.join([test_dir, "lib", "my_app_web", "components", "layouts"])
    File.write!(Path.join(layouts_dir, "old_app.html.heex"), @old_style_layout)
    
    test_dir
  end
  
  defp create_mock_igniter(test_dir) do
    %{
      assigns: %{},
      issues: [],
      notices: [],
      tasks: [],
      rewrite: %{sources: %{}},
      test_dir: test_dir
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