#!/usr/bin/env elixir

# Script to fix all compiler warnings by adding underscores to unused variables

defmodule WarningFixer do
  def fix_all_warnings do
    IO.puts("🔧 Fixing all compiler warnings...")

    # Define all the warning fixes
    warning_fixes = [
      # conflict_detection/dependency_analyzer.ex
      {"lib/phoenix_kit/install/conflict_detection/dependency_analyzer.ex",
       [
         {"defp extract_mix_exs_dependencies(igniter) do",
          "defp extract_mix_exs_dependencies(_igniter) do"},
         {"defp extract_mix_lock_dependencies(igniter) do",
          "defp extract_mix_lock_dependencies(_igniter) do"},
         {"{:error, _} = error ->", "{:error, _} = _error ->"}
       ]},

      # conflict_detection.ex
      {"lib/phoenix_kit/install/conflict_detection.ex",
       [
         {"def quick_conflict_check(igniter) do", "def quick_conflict_check(_igniter) do"},
         {"defp maybe_generate_migration_strategy(dependency_analysis, config_analysis, code_analysis, false, _opts) do",
          "defp maybe_generate_migration_strategy(_dependency_analysis, _config_analysis, _code_analysis, false, _opts) do"},
         {"{:error, reason} = error ->", "{:error, reason} = _error ->"},
         {"defp compile_required_changes_for_coexistence(dep_conflicts, config_conflicts, code_conflicts) do",
          "defp compile_required_changes_for_coexistence(dep_conflicts, config_conflicts, _code_conflicts) do"},
         {"defp identify_blocking_issues(dep_analysis, config_analysis, code_analysis) do",
          "defp identify_blocking_issues(dep_analysis, _config_analysis, code_analysis) do"}
       ]},

      # config_analyzer.ex
      {"lib/phoenix_kit/install/conflict_detection/config_analyzer.ex",
       [
         {"def analyze_auth_configurations(igniter) do",
          "def analyze_auth_configurations(_igniter) do"},
         {"defp detect_incompatible_settings(pattern_matches) do",
          "defp detect_incompatible_settings(_pattern_matches) do"},
         {"|> Enum.flat_map(fn {library, matches} ->",
          "|> Enum.flat_map(fn {library, _matches} ->"}
       ]},

      # code_analyzer.ex  
      {"lib/phoenix_kit/install/conflict_detection/code_analyzer.ex",
       [
         {"def analyze_authentication_code(igniter, opts \\\\ []) do",
          "def analyze_authentication_code(_igniter, opts \\\\ []) do"},
         {"defp extract_context_around_match(content, start, length) do",
          "defp extract_context_around_match(content, start, _length) do"},
         {"defp check_user_schema_compatibility(schema) do",
          "defp check_user_schema_compatibility(_schema) do"}
       ]},

      # migration_advisor.ex
      {"lib/phoenix_kit/install/conflict_detection/migration_advisor.ex",
       [
         {"risk_tolerance = Keyword.get(opts, :risk_tolerance, :medium)",
          "_risk_tolerance = Keyword.get(opts, :risk_tolerance, :medium)"},
         {"timeline_preference = Keyword.get(opts, :timeline_preference, :balanced)",
          "_timeline_preference = Keyword.get(opts, :timeline_preference, :balanced)"},
         {"defp adjust_timeline(base_timeline, conflict_profile, opts) do",
          "defp adjust_timeline(base_timeline, _conflict_profile, opts) do"},
         {"defp generate_risk_mitigation_strategies(base_risks, conflict_risks) do",
          "defp generate_risk_mitigation_strategies(_base_risks, conflict_risks) do"},
         {"defp generate_risk_monitoring_plan(migration_strategy) do",
          "defp generate_risk_monitoring_plan(_migration_strategy) do"},
         {"defp define_rollback_triggers(migration_strategy) do",
          "defp define_rollback_triggers(_migration_strategy) do"},
         {"defp generate_testing_strategy(migration_strategy) do",
          "defp generate_testing_strategy(_migration_strategy) do"}
       ]}
    ]

    # Apply all fixes
    Enum.each(warning_fixes, fn {file_path, fixes} ->
      IO.puts("📝 Fixing #{file_path}")
      apply_fixes_to_file(file_path, fixes)
    end)

    IO.puts("✅ All warning fixes applied!")
  end

  defp apply_fixes_to_file(file_path, fixes) do
    case File.read(file_path) do
      {:ok, content} ->
        updated_content =
          Enum.reduce(fixes, content, fn {old, new}, acc ->
            String.replace(acc, old, new)
          end)

        File.write!(file_path, updated_content)

      {:error, reason} ->
        IO.puts("❌ Error reading #{file_path}: #{reason}")
    end
  end
end

WarningFixer.fix_all_warnings()
