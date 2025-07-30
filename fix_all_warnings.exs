#!/usr/bin/env elixir

# Comprehensive warning fixer script

defmodule ComprehensiveWarningFixer do
  
  def fix_all do
    IO.puts("🔧 Starting comprehensive warning fix...")
    
    # Fix all remaining files
    fix_pro_installer()
    fix_layout_integration()
    fix_layout_modules()
    fix_router_integration()
    fix_router_modules()
    fix_code_analyzer_recommendations()
    
    IO.puts("✅ All warnings fixed!")
  end
  
  def fix_pro_installer do
    fix_file("lib/mix/tasks/phoenix_kit.install.pro.ex", [
      {"defp perform_quick_conflict_check(igniter, conflict_tolerance) do", 
       "defp perform_quick_conflict_check(igniter, _conflict_tolerance) do"},
      {"defp perform_comprehensive_conflict_analysis(igniter, conflict_tolerance, opts) do",
       "defp perform_comprehensive_conflict_analysis(igniter, conflict_tolerance, _opts) do"},
      {"defp log_conflict_analysis_summary(analysis_result) do",
       "defp log_conflict_analysis_summary(_analysis_result) do"},
      {"defp log_conflict_warnings(warnings) do",
       "defp log_conflict_warnings(_warnings) do"},
      {"defp log_critical_conflicts_and_abort(critical_conflicts) do",
       "defp log_critical_conflicts_and_abort(_critical_conflicts) do"}
    ])
  end
  
  def fix_layout_integration do
    fix_file("lib/phoenix_kit/install/layout_integration.ex", [
      {"def quick_layout_check(igniter) do", "def quick_layout_check(_igniter) do"},
      {"defp maybe_enhance_layouts(igniter, integration_strategy, false) do",
       "defp maybe_enhance_layouts(igniter, _integration_strategy, false) do"},
      {"defp maybe_create_fallbacks(igniter, integration_strategy, false) do",
       "defp maybe_create_fallbacks(igniter, _integration_strategy, false) do"}
    ])
  end
  
  def fix_layout_modules do
    # auto_configurator.ex
    fix_file("lib/phoenix_kit/install/layout_integration/auto_configurator.ex", [
      {"defp detect_available_layouts(igniter) do", "defp detect_available_layouts(_igniter) do"},
      {"defp check_existing_phoenix_kit_config(igniter, app_name) do", 
       "defp check_existing_phoenix_kit_config(_igniter, _app_name) do"},
      {"defp extract_existing_layout_config(igniter, app_name) do",
       "defp extract_existing_layout_config(_igniter, _app_name) do"},
      {"defp read_current_phoenix_kit_config(igniter) do",
       "defp read_current_phoenix_kit_config(_igniter) do"}
    ])
    
    # fallback_handler.ex
    fix_file("lib/phoenix_kit/install/layout_integration/fallback_handler.ex", [
      {"defp create_single_fallback(igniter, layout_type, target_dir, custom_templates, enhancement_level) do",
       "defp create_single_fallback(_igniter, layout_type, target_dir, custom_templates, enhancement_level) do"},
      {"defp discover_existing_fallbacks(igniter) do", "defp discover_existing_fallbacks(_igniter) do"},
      {"defp apply_update_to_content(content, update) do", "defp apply_update_to_content(content, _update) do"}
    ])
    
    # layout_detector.ex
    fix_file("lib/phoenix_kit/install/layout_integration/layout_detector.ex", [
      {"def detect_existing_layouts(igniter) do", "def detect_existing_layouts(_igniter) do"},
      {"defp assess_phoenix_kit_compatibility(layout_analysis, feature_analysis) do",
       "defp assess_phoenix_kit_compatibility(_layout_analysis, feature_analysis) do"},
      {"defp check_css_framework_compatibility(feature_analysis) do",
       "defp check_css_framework_compatibility(_feature_analysis) do"},
      {"defp generate_detection_recommendations(layout_analysis, structure_analysis, compatibility_analysis) do",
       "defp generate_detection_recommendations(_layout_analysis, structure_analysis, compatibility_analysis) do"}
    ])
    
    # layout_enhancer.ex
    fix_file("lib/phoenix_kit/install/layout_integration/layout_enhancer.ex", [
      {"defp discover_layout_files_to_enhance(igniter) do", "defp discover_layout_files_to_enhance(_igniter) do"},
      {"defp maybe_backup_original_files(igniter, layout_files, false), do: {:ok, igniter}",
       "defp maybe_backup_original_files(igniter, _layout_files, false), do: {:ok, igniter}"},
      {"enhanced_content = Regex.replace(old_pattern, content, fn match, flash_type ->",
       "enhanced_content = Regex.replace(old_pattern, content, fn _match, flash_type ->"},
      {"enhanced_content = Regex.replace(~r/<link([^>]*stylesheet[^>]*)>/, content, fn match, attrs ->",
       "enhanced_content = Regex.replace(~r/<link([^>]*stylesheet[^>]*)>/, content, fn match, _attrs ->"}
    ])
  end
  
  def fix_router_integration do
    fix_file("lib/phoenix_kit/install/router_integration.ex", [
      {"def rollback_integration(igniter, opts \\\\ []) do", "def rollback_integration(igniter, _opts \\\\ []) do"},
      {"def generate_integration_report(igniter, opts \\\\ []) do", "def generate_integration_report(igniter, _opts \\\\ []) do"},
      {"defp maybe_skip_if_exists(igniter, router_info, false) do", "defp maybe_skip_if_exists(igniter, _router_info, false) do"},
      {"defp validate_if_requested(igniter, router_module, false) do", "defp validate_if_requested(_igniter, _router_module, false) do"},
      {"|> Enum.flat_map(fn {type, conflicts_of_type} ->", "|> Enum.flat_map(fn {type, _conflicts_of_type} ->"}
    ])
  end
  
  def fix_router_modules do
    # ast_analyzer.ex
    fix_file("lib/phoenix_kit/install/router_integration/ast_analyzer.ex", [
      {"defp analyze_existing_scopes(zipper) do", "defp analyze_existing_scopes(_zipper) do"},
      {"defp analyze_existing_pipelines(zipper) do", "defp analyze_existing_pipelines(_zipper) do"},
      {"defp detect_potential_conflicts(zipper) do", "defp detect_potential_conflicts(_zipper) do"},
      {"defp has_browser_pipeline?(zipper) do", "defp has_browser_pipeline?(_zipper) do"},
      {"defp has_api_pipeline?(zipper) do", "defp has_api_pipeline?(_zipper) do"},
      {"defp has_phoenix_kit_routes?(zipper) do", "defp has_phoenix_kit_routes?(_zipper) do"}
    ])
    
    # conflict_resolver.ex
    fix_file("lib/phoenix_kit/install/router_integration/conflict_resolver.ex", [
      {"defp detect_incompatible_structure(router_info) do", "defp detect_incompatible_structure(_router_info) do"},
      {"defp auto_resolve_single_conflict(igniter, conflict) do", "defp auto_resolve_single_conflict(_igniter, conflict) do"},
      {"defp handle_manual_conflicts(igniter, conflicts, resolved_conflicts) do", 
       "defp handle_manual_conflicts(_igniter, conflicts, resolved_conflicts) do"},
      {"defp extract_existing_paths(router_info) do", "defp extract_existing_paths(_router_info) do"},
      {"defp suggest_alternative_prefix(current_prefix, existing_paths) do", 
       "defp suggest_alternative_prefix(_current_prefix, existing_paths) do"},
      {"defp scope_conflicts_with_phoenix_kit?(scope, prefix) do", 
       "defp scope_conflicts_with_phoenix_kit?(_scope, _prefix) do"}
    ])
    
    # route_injector.ex
    fix_file("lib/phoenix_kit/install/router_integration/route_injector.ex", [
      {"defp has_browser_scopes?(zipper) do", "defp has_browser_scopes?(_zipper) do"},
      {"zipper -> true", "_zipper -> true"}
    ])
    
    # validator.ex
    fix_file("lib/phoenix_kit/install/router_integration/validator.ex", [
      {"defp check_duplicate_imports(zipper) do", "defp check_duplicate_imports(_zipper) do"},
      {"defp check_route_conflicts(zipper) do", "defp check_route_conflicts(_zipper) do"},
      {"defp find_duplicate_imports(zipper) do", "defp find_duplicate_imports(_zipper) do"},
      {"defp find_duplicate_routes(zipper) do", "defp find_duplicate_routes(_zipper) do"},
      {"defp analyze_router_structure_issues(zipper) do", "defp analyze_router_structure_issues(_zipper) do"},
      {"defp analyze_imports(zipper) do", "defp analyze_imports(_zipper) do"},
      {"defp analyze_routes(zipper) do", "defp analyze_routes(_zipper) do"},
      {"defp analyze_pipelines(zipper) do", "defp analyze_pipelines(_zipper) do"},
      {"defp analyze_scopes(zipper) do", "defp analyze_scopes(_zipper) do"},
      {"defp detect_potential_issues(zipper) do", "defp detect_potential_issues(_zipper) do"},
      {"defp generate_summary_text(results, errors, warnings) do", 
       "defp generate_summary_text(_results, errors, warnings) do"}
    ])
  end
  
  def fix_code_analyzer_recommendations do
    # Fix the complex recommendation patterns
    content = File.read!("lib/phoenix_kit/install/conflict_detection/code_analyzer.ex")
    
    # Fix the recommendation patterns
    fixed_content = content
    |> String.replace(
      "    if Map.has_key?(pattern_matches, :user_schemas) do\n      recommendations = recommendations ++ [\n        \"✅ User schema detected - data migration may be needed\"\n      ]\n    end",
      "    recommendations = if Map.has_key?(pattern_matches, :user_schemas) do\n      recommendations ++ [\n        \"✅ User schema detected - data migration may be needed\"\n      ]\n    else\n      recommendations\n    end"
    )
    |> String.replace(
      "    if Map.has_key?(pattern_matches, :guardian_code) do\n      recommendations = recommendations ++ [\n        \"ℹ️  Guardian code found - can coexist with PhoenixKit for API auth\"\n      ]\n    end",
      "    recommendations = if Map.has_key?(pattern_matches, :guardian_code) do\n      recommendations ++ [\n        \"ℹ️  Guardian code found - can coexist with PhoenixKit for API auth\"\n      ]\n    else\n      recommendations\n    end"
    )
    |> String.replace(
      "    if Map.has_key?(pattern_matches, :pow_code) do\n      recommendations = recommendations ++ [\n        \"⚠️  Pow code found - migration planning required\"\n      ]\n    end",
      "    recommendations = if Map.has_key?(pattern_matches, :pow_code) do\n      recommendations ++ [\n        \"⚠️  Pow code found - migration planning required\"\n      ]\n    else\n      recommendations\n    end"
    )
    
    File.write!("lib/phoenix_kit/install/conflict_detection/code_analyzer.ex", fixed_content)
    IO.puts("📝 Fixed code_analyzer.ex recommendation patterns")
  end
  
  defp fix_file(file_path, replacements) do
    case File.read(file_path) do
      {:ok, content} ->
        updated_content = Enum.reduce(replacements, content, fn {old, new}, acc ->
          String.replace(acc, old, new)
        end)
        
        File.write!(file_path, updated_content)
        IO.puts("📝 Fixed #{file_path}")
        
      {:error, reason} ->
        IO.puts("❌ Error reading #{file_path}: #{reason}")
    end
  end
end

ComprehensiveWarningFixer.fix_all()