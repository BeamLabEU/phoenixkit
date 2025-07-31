defmodule PhoenixKit.Install.ConflictDetection do
  @moduledoc """
  Главный модуль для комплексного обнаружения и разрешения конфликтов при установке PhoenixKit.

  Этот модуль координирует работу всех компонентов conflict detection:
  - Анализ зависимостей (DependencyAnalyzer)
  - Анализ конфигураций (ConfigAnalyzer) 
  - Анализ кода (CodeAnalyzer)
  - Генерация стратегий миграции (MigrationAdvisor)

  Предоставляет высокоуровневый API для Professional Installer.
  """

  require Logger

  alias PhoenixKit.Install.ConflictDetection.{
    DependencyAnalyzer,
    ConfigAnalyzer,
    CodeAnalyzer,
    MigrationAdvisor
  }

  @doc """
  Выполняет полный анализ конфликтов в Phoenix приложении.

  ## Parameters

  - `igniter` - Igniter context
  - `opts` - Опции анализа:
    - `:scan_test_files` - Включать ли test файлы в код анализ (default: false)
    - `:max_files` - Максимальное количество файлов для сканирования (default: 1000)
    - `:risk_tolerance` - Уровень толерантности к рискам (default: :medium)
    - `:generate_migration_strategy` - Генерировать ли стратегию миграции (default: true)

  ## Returns

  - `{:ok, comprehensive_analysis}` - полный анализ конфликтов
  - `{:error, reason}` - ошибка при анализе

  ## Examples

      iex> ConflictDetection.perform_comprehensive_analysis(igniter)
      {:ok, %{
        dependency_analysis: %{...},
        config_analysis: %{...}, 
        code_analysis: %{...},
        migration_strategy: %{...},
        overall_assessment: %{...}
      }}
  """
  def perform_comprehensive_analysis(igniter, opts \\ []) do
    scan_test_files = Keyword.get(opts, :scan_test_files, false)
    max_files = Keyword.get(opts, :max_files, 1000)
    risk_tolerance = Keyword.get(opts, :risk_tolerance, :medium)
    generate_strategy = Keyword.get(opts, :generate_migration_strategy, true)

    Logger.info("🔍 Starting comprehensive conflict detection analysis")
    Logger.info("   Risk tolerance: #{risk_tolerance}")
    Logger.info("   Generate migration strategy: #{generate_strategy}")

    analysis_start_time = System.monotonic_time(:millisecond)

    with {:ok, dependency_analysis} <- run_dependency_analysis(igniter),
         {:ok, config_analysis} <- run_config_analysis(igniter),
         {:ok, code_analysis} <- run_code_analysis(igniter, scan_test_files, max_files),
         {:ok, migration_strategy} <-
           maybe_generate_migration_strategy(
             dependency_analysis,
             config_analysis,
             code_analysis,
             generate_strategy,
             opts
           ),
         {:ok, overall_assessment} <-
           generate_overall_assessment(
             dependency_analysis,
             config_analysis,
             code_analysis,
             migration_strategy
           ) do
      analysis_duration = System.monotonic_time(:millisecond) - analysis_start_time

      comprehensive_analysis = %{
        analysis_timestamp: DateTime.utc_now(),
        analysis_duration_ms: analysis_duration,
        dependency_analysis: dependency_analysis,
        config_analysis: config_analysis,
        code_analysis: code_analysis,
        migration_strategy: migration_strategy,
        overall_assessment: overall_assessment,
        recommendations:
          compile_all_recommendations(dependency_analysis, config_analysis, code_analysis),
        next_steps: determine_next_steps(overall_assessment, migration_strategy)
      }

      log_comprehensive_analysis_summary(comprehensive_analysis)
      {:ok, comprehensive_analysis}
    else
      {:error, reason} = error ->
        Logger.error("❌ Comprehensive analysis failed: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Быстрая проверка основных конфликтов без детального анализа.

  Полезно для предварительной оценки перед запуском полного анализа.
  """
  def quick_conflict_check(_igniter) do
    Logger.info("⚡ Running quick conflict check")

    with {:ok, basic_deps} <- check_basic_auth_dependencies(),
         {:ok, basic_configs} <- check_basic_auth_configs(),
         {:ok, basic_user_schemas} <- check_basic_user_schemas() do
      quick_assessment = %{
        has_auth_dependencies: length(basic_deps) > 0,
        auth_dependencies: basic_deps,
        has_auth_configs: length(basic_configs) > 0,
        has_user_schemas: length(basic_user_schemas) > 0,
        estimated_conflict_level:
          estimate_quick_conflict_level(basic_deps, basic_configs, basic_user_schemas),
        recommendation:
          generate_quick_recommendation(basic_deps, basic_configs, basic_user_schemas),
        should_run_full_analysis:
          should_run_full_analysis?(basic_deps, basic_configs, basic_user_schemas)
      }

      Logger.info(
        "⚡ Quick check complete - estimated conflict level: #{quick_assessment.estimated_conflict_level}"
      )

      {:ok, quick_assessment}
    else
      error ->
        Logger.warning("⚡ Quick check failed, recommend running full analysis: #{inspect(error)}")

        {:ok,
         %{
           has_errors: true,
           error: error,
           recommendation: "Run full analysis for detailed conflict detection",
           should_run_full_analysis: true
         }}
    end
  end

  @doc """
  Проверяет, может ли PhoenixKit сосуществовать с найденными auth системами.
  """
  def assess_coexistence_feasibility(comprehensive_analysis) do
    dependency_conflicts = comprehensive_analysis.dependency_analysis.conflicts
    config_conflicts = comprehensive_analysis.config_analysis.conflicts
    code_conflicts = comprehensive_analysis.code_analysis.conflicts

    coexistence_assessment = %{
      overall_feasible: true,
      dependency_feasibility: assess_dependency_coexistence(dependency_conflicts),
      config_feasibility: assess_config_coexistence(config_conflicts),
      code_feasibility: assess_code_coexistence(code_conflicts),
      required_changes:
        compile_required_changes_for_coexistence(
          dependency_conflicts,
          config_conflicts,
          code_conflicts
        ),
      coexistence_strategy: determine_optimal_coexistence_strategy(comprehensive_analysis)
    }

    # Обновляем общую feasibility на основе индивидуальных оценок
    coexistence_assessment = %{
      coexistence_assessment
      | overall_feasible:
          coexistence_assessment.dependency_feasibility and
            coexistence_assessment.config_feasibility and
            coexistence_assessment.code_feasibility
    }

    {:ok, coexistence_assessment}
  end

  @doc """
  Генерирует детальный отчёт о конфликтах для пользователя.
  """
  def generate_conflict_report(comprehensive_analysis, format \\ :detailed) do
    case format do
      :summary ->
        generate_summary_report(comprehensive_analysis)

      :detailed ->
        generate_detailed_report(comprehensive_analysis)

      :technical ->
        generate_technical_report(comprehensive_analysis)
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp run_dependency_analysis(igniter) do
    Logger.debug("Running dependency analysis...")

    case DependencyAnalyzer.analyze_auth_dependencies(igniter) do
      {:ok, result} ->
        Logger.debug("✅ Dependency analysis completed")
        {:ok, result}

      {:error, reason} = error ->
        Logger.error("❌ Dependency analysis failed: #{inspect(reason)}")
        error
    end
  end

  defp run_config_analysis(igniter) do
    Logger.debug("Running configuration analysis...")

    case ConfigAnalyzer.analyze_auth_configurations(igniter) do
      {:ok, result} ->
        Logger.debug("✅ Configuration analysis completed")
        {:ok, result}

      {:error, reason} = error ->
        Logger.error("❌ Configuration analysis failed: #{inspect(reason)}")
        error
    end
  end

  defp run_code_analysis(igniter, scan_test_files, max_files) do
    Logger.debug("Running code analysis...")

    case CodeAnalyzer.analyze_authentication_code(igniter,
           scan_test_files: scan_test_files,
           max_files: max_files
         ) do
      {:ok, result} ->
        Logger.debug("✅ Code analysis completed")
        {:ok, result}

      {:error, reason} = error ->
        Logger.error("❌ Code analysis failed: #{inspect(reason)}")
        error
    end
  end

  defp maybe_generate_migration_strategy(
         _dependency_analysis,
         _config_analysis,
         _code_analysis,
         false,
         _opts
       ) do
    {:ok, %{strategy_generation_skipped: true}}
  end

  defp maybe_generate_migration_strategy(
         dependency_analysis,
         config_analysis,
         code_analysis,
         true,
         opts
       ) do
    Logger.debug("Generating migration strategy...")

    case MigrationAdvisor.generate_migration_strategy(
           dependency_analysis,
           config_analysis,
           code_analysis,
           opts
         ) do
      {:ok, strategy} ->
        Logger.debug("✅ Migration strategy generated")
        {:ok, strategy}

      {:error, reason} = _error ->
        Logger.warning("⚠️  Migration strategy generation failed: #{inspect(reason)}")

        # Не прерываем весь анализ из-за ошибки в стратегии
        {:ok, %{strategy_generation_failed: true, error: reason}}
    end
  end

  defp generate_overall_assessment(
         dependency_analysis,
         config_analysis,
         code_analysis,
         migration_strategy
       ) do
    total_conflicts = count_total_conflicts(dependency_analysis, config_analysis, code_analysis)

    critical_conflicts =
      count_critical_conflicts(dependency_analysis, config_analysis, code_analysis)

    overall_assessment = %{
      total_conflicts: total_conflicts,
      critical_conflicts: critical_conflicts,
      overall_risk_level: determine_overall_risk_level(critical_conflicts, total_conflicts),
      installation_complexity:
        determine_installation_complexity(dependency_analysis, code_analysis),
      estimated_migration_time: extract_migration_time(migration_strategy),
      safe_to_proceed: is_safe_to_proceed_with_installation?(critical_conflicts, total_conflicts),
      requires_manual_intervention:
        requires_manual_intervention?(dependency_analysis, config_analysis, code_analysis),
      auto_resolvable_conflicts:
        count_auto_resolvable_conflicts(dependency_analysis, config_analysis, code_analysis),
      blocking_issues:
        identify_blocking_issues(dependency_analysis, config_analysis, code_analysis)
    }

    {:ok, overall_assessment}
  end

  defp compile_all_recommendations(dependency_analysis, config_analysis, code_analysis) do
    [
      dependency_analysis.recommendations,
      config_analysis.recommendations,
      code_analysis.recommendations
    ]
    |> List.flatten()
    |> Enum.uniq()
  end

  defp determine_next_steps(overall_assessment, migration_strategy) do
    cond do
      not overall_assessment.safe_to_proceed ->
        [
          "🚨 STOP: Critical conflicts detected",
          "Review conflict details before proceeding",
          "Consider manual conflict resolution"
        ]

      overall_assessment.requires_manual_intervention ->
        [
          "⚠️  Manual intervention required",
          "Review migration strategy carefully",
          "Plan migration phases with team"
        ]

      Map.has_key?(migration_strategy, :next_steps) ->
        migration_strategy.next_steps

      true ->
        [
          "✅ Ready to proceed with PhoenixKit installation",
          "Run: mix phoenix_kit.install.pro",
          "Monitor installation for any issues"
        ]
    end
  end

  # Quick check helper functions
  defp check_basic_auth_dependencies do
    try do
      case File.read("mix.exs") do
        {:ok, content} ->
          auth_deps = ["guardian", "pow", "coherence", "ueberauth"]

          found_deps =
            Enum.filter(auth_deps, fn dep ->
              String.contains?(content, ":#{dep}")
            end)

          {:ok, found_deps}

        {:error, _} ->
          {:ok, []}
      end
    rescue
      _ -> {:error, :mix_exs_read_error}
    end
  end

  defp check_basic_auth_configs do
    config_files = ["config/config.exs", "config/dev.exs"]

    try do
      auth_configs =
        Enum.flat_map(config_files, fn file ->
          case File.read(file) do
            {:ok, content} ->
              auth_patterns = ["guardian", "pow", "coherence", "ueberauth"]

              Enum.filter(auth_patterns, fn pattern ->
                String.contains?(content, pattern)
              end)

            {:error, _} ->
              []
          end
        end)

      {:ok, Enum.uniq(auth_configs)}
    rescue
      _ -> {:error, :config_read_error}
    end
  end

  defp check_basic_user_schemas do
    try do
      case Path.wildcard("lib/**/*user*.ex") do
        [] ->
          {:ok, []}

        files ->
          user_schemas =
            Enum.filter(files, fn file ->
              case File.read(file) do
                {:ok, content} -> String.contains?(content, "schema \"users\"")
                {:error, _} -> false
              end
            end)

          {:ok, user_schemas}
      end
    rescue
      _ -> {:error, :user_schema_scan_error}
    end
  end

  defp estimate_quick_conflict_level(deps, configs, schemas) do
    conflict_score = length(deps) + length(configs) + length(schemas)

    cond do
      conflict_score == 0 -> :none
      conflict_score <= 2 -> :low
      conflict_score <= 4 -> :medium
      true -> :high
    end
  end

  defp generate_quick_recommendation(deps, configs, schemas) do
    cond do
      length(deps) == 0 and length(configs) == 0 and length(schemas) == 0 ->
        "✅ No obvious conflicts detected - installation should be straightforward"

      length(deps) == 1 and "guardian" in deps ->
        "ℹ️  Guardian detected - can likely coexist with PhoenixKit"

      "pow" in deps ->
        "⚠️  Pow detected - migration planning recommended"

      length(schemas) > 0 ->
        "⚠️  User schemas detected - data migration may be needed"

      true ->
        "ℹ️  Some auth components detected - run full analysis for details"
    end
  end

  defp should_run_full_analysis?(deps, configs, schemas) do
    # Рекомендуем полный анализ если есть любые потенциальные конфликты
    length(deps) > 0 or length(configs) > 0 or length(schemas) > 0
  end

  # Assessment helper functions
  defp assess_dependency_coexistence(dependency_conflicts) do
    # Зависимости могут сосуществовать если все конфликты низкого уровня или могут coexist
    Enum.all?(dependency_conflicts, fn conflict ->
      conflict.conflict_level in [:none, :low] or
        Map.get(conflict, :can_coexist, false)
    end)
  end

  defp assess_config_coexistence(config_conflicts) do
    # Конфигурации могут сосуществовать если нет high priority конфликтов
    not Enum.any?(config_conflicts, fn conflict ->
      Map.get(conflict, :priority, :medium) == :high and
        not Map.get(conflict, :auto_resolvable, false)
    end)
  end

  defp assess_code_coexistence(code_conflicts) do
    # Код может сосуществовать если нет critical конфликтов
    not Enum.any?(code_conflicts, fn conflict ->
      Map.get(conflict, :severity, :minor) == :critical
    end)
  end

  defp compile_required_changes_for_coexistence(dep_conflicts, config_conflicts, _code_conflicts) do
    changes = []

    # Добавляем изменения на основе конфликтов зависимостей
    changes =
      changes ++
        Enum.flat_map(dep_conflicts, fn conflict ->
          if Map.get(conflict, :can_coexist, false) do
            ["Configure #{conflict.library} for specific use case"]
          else
            []
          end
        end)

    # Добавляем изменения на основе конфликтов конфигурации
    changes =
      changes ++
        Enum.flat_map(config_conflicts, fn conflict ->
          if Map.get(conflict, :auto_resolvable, false) do
            ["Adjust configuration for #{conflict.type}"]
          else
            []
          end
        end)

    Enum.uniq(changes)
  end

  defp determine_optimal_coexistence_strategy(comprehensive_analysis) do
    # Простая логика для определения стратегии сосуществования
    auth_libs = comprehensive_analysis.dependency_analysis.found_auth_libraries

    cond do
      :guardian in auth_libs and length(auth_libs) == 1 ->
        "Use Guardian for API authentication, PhoenixKit for web authentication"

      :ueberauth in auth_libs ->
        "Use Ueberauth for OAuth, PhoenixKit for basic authentication"

      length(auth_libs) == 0 ->
        "Clean PhoenixKit installation"

      true ->
        "Evaluate each auth system individually for coexistence potential"
    end
  end

  # Report generation functions
  defp generate_summary_report(analysis) do
    """
    # PhoenixKit Conflict Detection Summary

    **Analysis Date:** #{analysis.analysis_timestamp}
    **Total Conflicts:** #{analysis.overall_assessment.total_conflicts}
    **Critical Conflicts:** #{analysis.overall_assessment.critical_conflicts}
    **Overall Risk:** #{analysis.overall_assessment.overall_risk_level}

    ## Key Findings
    - Auth Libraries: #{inspect(analysis.dependency_analysis.found_auth_libraries)}
    - Installation Complexity: #{analysis.overall_assessment.installation_complexity}
    - Safe to Proceed: #{analysis.overall_assessment.safe_to_proceed}

    ## Next Steps
    #{Enum.join(analysis.next_steps, "\n")}
    """
  end

  defp generate_detailed_report(analysis) do
    # TODO: Implement detailed report generation
    generate_summary_report(analysis) <> "\n\n[Detailed analysis would go here]"
  end

  defp generate_technical_report(analysis) do
    # TODO: Implement technical report generation  
    generate_detailed_report(analysis) <> "\n\n[Technical details would go here]"
  end

  # Metrics and assessment helper functions
  defp count_total_conflicts(dep_analysis, config_analysis, code_analysis) do
    length(dep_analysis.conflicts) +
      length(config_analysis.conflicts) +
      length(code_analysis.conflicts)
  end

  defp count_critical_conflicts(dep_analysis, config_analysis, code_analysis) do
    dep_critical = Enum.count(dep_analysis.conflicts, &(&1.conflict_level == :high))
    config_critical = length(config_analysis.high_priority_conflicts)
    code_critical = length(code_analysis.critical_conflicts)

    dep_critical + config_critical + code_critical
  end

  defp determine_overall_risk_level(critical_conflicts, total_conflicts) do
    cond do
      critical_conflicts > 0 -> :high
      total_conflicts > 5 -> :medium
      total_conflicts > 0 -> :low
      true -> :none
    end
  end

  defp determine_installation_complexity(dep_analysis, code_analysis) do
    cond do
      dep_analysis.migration_required and code_analysis.requires_data_migration -> :high
      dep_analysis.migration_required or code_analysis.requires_data_migration -> :medium
      dep_analysis.high_conflict_count > 0 -> :medium
      true -> :low
    end
  end

  defp extract_migration_time(migration_strategy) do
    case migration_strategy do
      %{estimated_timeline: timeline} -> timeline
      _ -> "Unknown"
    end
  end

  defp is_safe_to_proceed_with_installation?(critical_conflicts, total_conflicts) do
    critical_conflicts == 0 and total_conflicts < 10
  end

  defp requires_manual_intervention?(dep_analysis, config_analysis, code_analysis) do
    not dep_analysis.can_auto_resolve or
      not config_analysis.safe_to_proceed or
      code_analysis.migration_complexity in [:medium, :high]
  end

  defp count_auto_resolvable_conflicts(dep_analysis, config_analysis, code_analysis) do
    dep_auto = Enum.count(dep_analysis.conflicts, &Map.get(&1, :auto_resolvable, false))
    config_auto = Enum.count(config_analysis.conflicts, &Map.get(&1, :auto_resolvable, false))
    code_auto = Enum.count(code_analysis.conflicts, &Map.get(&1, :auto_resolvable, false))

    dep_auto + config_auto + code_auto
  end

  defp identify_blocking_issues(dep_analysis, _config_analysis, code_analysis) do
    blocking_issues = []

    # Блокирующие проблемы из зависимостей
    blocking_issues =
      (blocking_issues ++
         Enum.filter(dep_analysis.conflicts, fn conflict ->
           conflict.conflict_level == :high and not Map.get(conflict, :can_coexist, false)
         end))
      |> Enum.map(&"Dependency conflict: #{&1.library}")

    # Блокирующие проблемы из кода
    blocking_issues =
      (blocking_issues ++
         Enum.filter(code_analysis.conflicts, fn conflict ->
           conflict.severity == :critical
         end))
      |> Enum.map(&"Code conflict: #{&1.type}")

    blocking_issues
  end

  defp log_comprehensive_analysis_summary(analysis) do
    Logger.info("📊 Comprehensive Analysis Complete!")
    Logger.info("   Duration: #{analysis.analysis_duration_ms}ms")
    Logger.info("   Total conflicts: #{analysis.overall_assessment.total_conflicts}")
    Logger.info("   Critical conflicts: #{analysis.overall_assessment.critical_conflicts}")
    Logger.info("   Overall risk: #{analysis.overall_assessment.overall_risk_level}")
    Logger.info("   Safe to proceed: #{analysis.overall_assessment.safe_to_proceed}")

    Logger.info(
      "   Manual intervention: #{analysis.overall_assessment.requires_manual_intervention}"
    )

    if not analysis.overall_assessment.safe_to_proceed do
      Logger.warning("⚠️  Installation not recommended without conflict resolution")
    end
  end
end
