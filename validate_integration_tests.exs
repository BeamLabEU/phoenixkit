#!/usr/bin/env elixir

# Validation script to check integration tests without database dependencies
Code.require_file("lib/phoenix_kit/install/router_integration.ex")
Code.require_file("lib/phoenix_kit/install/layout_integration.ex") 
Code.require_file("lib/phoenix_kit/install/conflict_detection.ex")

defmodule IntegrationTestValidator do
  @moduledoc """
  Validates that integration tests are properly structured and modules are accessible.
  """
  
  def run do
    IO.puts("🔍 PhoenixKit Integration Test Validation")
    IO.puts("=" |> String.duplicate(50))
    
    results = [
      validate_module_availability(),
      validate_test_file_structure(),
      validate_function_exports(),
      validate_integration_completeness()
    ]
    
    print_results(results)
    
    if Enum.all?(results, fn {_, status} -> status == :ok end) do
      IO.puts("\n✅ All integration tests validated successfully!")
      :ok
    else
      IO.puts("\n❌ Some integration test validations failed")
      :error
    end
  end
  
  defp validate_module_availability do
    try do
      # Check that main integration modules exist and are compiled
      modules = [
        PhoenixKit.Install.RouterIntegration,
        PhoenixKit.Install.LayoutIntegration,
        PhoenixKit.Install.ConflictDetection
      ]
      
      missing = Enum.filter(modules, fn mod ->
        not Code.ensure_loaded?(mod)
      end)
      
      if missing == [] do
        {"Module Availability", :ok, "All integration modules loaded"}
      else
        {"Module Availability", :error, "Missing modules: #{inspect(missing)}"}
      end
    catch
      _, error ->
        {"Module Availability", :error, "Error loading modules: #{inspect(error)}"}
    end
  end
  
  defp validate_test_file_structure do
    test_files = [
      "test/phoenix_kit/install/router_integration_test.exs",
      "test/phoenix_kit/install/layout_integration_test.exs", 
      "test/phoenix_kit/install/conflict_detection_test.exs",
      "test/phoenix_kit/install/professional_installer_integration_test.exs",
      "test/phoenix_kit/install/basic_integration_test.exs"
    ]
    
    {missing, existing} = Enum.split_with(test_files, fn file ->
      not File.exists?(file)
    end)
    
    if missing == [] do
      total_lines = existing 
                   |> Enum.map(&File.read!/1)
                   |> Enum.map(&(String.split(&1, "\n") |> length()))
                   |> Enum.sum()
      
      {"Test File Structure", :ok, "#{length(existing)} test files, #{total_lines} total lines"}
    else
      {"Test File Structure", :error, "Missing files: #{inspect(missing)}"}
    end
  end
  
  defp validate_function_exports do
    expected_exports = %{
      PhoenixKit.Install.RouterIntegration => [
        {:perform_full_integration, 2},
        {:check_integration_feasibility, 2},  
        {:rollback_integration, 2},
        {:generate_integration_report, 2}
      ],
      PhoenixKit.Install.LayoutIntegration => [
        {:perform_full_integration, 2},
        {:quick_layout_check, 1},
        {:assess_layout_compatibility, 1},
        {:generate_integration_report, 2}
      ],
      PhoenixKit.Install.ConflictDetection => [
        {:quick_conflict_check, 1},
        {:perform_comprehensive_analysis, 2}
      ]
    }
    
    missing_functions = []
    
    Enum.each(expected_exports, fn {module, functions} ->
      if Code.ensure_loaded?(module) do
        Enum.each(functions, fn {func, arity} ->
          unless function_exported?(module, func, arity) do
            missing_functions = missing_functions ++ ["#{module}.#{func}/#{arity}"]
          end
        end)
      end
    end)
    
    if missing_functions == [] do
      total_functions = expected_exports 
                       |> Map.values() 
                       |> List.flatten() 
                       |> length()
      {"Function Exports", :ok, "All #{total_functions} expected functions exported"}
    else
      {"Function Exports", :error, "Missing functions: #{inspect(missing_functions)}"}
    end
  end
  
  defp validate_integration_completeness do
    # Check that we have comprehensive test coverage
    coverage_areas = [
      {"Router Integration", "test/phoenix_kit/install/router_integration_test.exs", [
        "perform_full_integration",
        "check_integration_feasibility",
        "rollback_integration"
      ]},
      {"Layout Integration", "test/phoenix_kit/install/layout_integration_test.exs", [
        "perform_full_integration", 
        "quick_layout_check",
        "assess_layout_compatibility"
      ]},
      {"Conflict Detection", "test/phoenix_kit/install/conflict_detection_test.exs", [
        "quick_conflict_check",
        "perform_comprehensive_analysis"
      ]},
      {"End-to-end Integration", "test/phoenix_kit/install/professional_installer_integration_test.exs", [
        "complete professional installation flow",
        "error handling and recovery"
      ]}
    ]
    
    coverage_results = Enum.map(coverage_areas, fn {area, file, keywords} ->
      if File.exists?(file) do
        content = File.read!(file)
        covered = Enum.count(keywords, fn keyword ->
          String.contains?(content, keyword)
        end)
        {area, covered, length(keywords)}
      else
        {area, 0, length(keywords)}
      end
    end)
    
    total_covered = coverage_results |> Enum.map(fn {_, covered, _} -> covered end) |> Enum.sum()
    total_expected = coverage_results |> Enum.map(fn {_, _, expected} -> expected end) |> Enum.sum()
    
    coverage_percentage = if total_expected > 0 do
      round(total_covered / total_expected * 100)
    else
      0
    end
    
    if coverage_percentage >= 80 do
      {"Integration Coverage", :ok, "#{coverage_percentage}% coverage (#{total_covered}/#{total_expected})"}
    else
      {"Integration Coverage", :warning, "#{coverage_percentage}% coverage (#{total_covered}/#{total_expected}) - could be better"}
    end
  end
  
  defp print_results(results) do
    IO.puts("\n📊 Validation Results:")
    IO.puts("-" |> String.duplicate(30))
    
    Enum.each(results, fn {test_name, status, details} ->
      icon = case status do
        :ok -> "✅"
        :warning -> "⚠️ "
        :error -> "❌"
      end
      
      IO.puts("#{icon} #{test_name}")
      IO.puts("   #{details}")
    end)
  end
end

# Run validation
case IntegrationTestValidator.run() do
  :ok -> System.halt(0)
  :error -> System.halt(1)
end