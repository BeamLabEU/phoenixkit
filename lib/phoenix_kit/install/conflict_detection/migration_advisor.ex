defmodule PhoenixKit.Install.ConflictDetection.MigrationAdvisor do
  @moduledoc """
  Предоставляет стратегии миграции для разрешения auth конфликтов.
  
  Этот модуль:
  - Анализирует результаты dependency, config и code анализа
  - Генерирует персонализированные стратегии миграции
  - Предоставляет пошаговые инструкции для разрешения конфликтов
  - Оценивает сложность и риски миграции
  """

  require Logger

  @migration_strategies %{
    # Guardian coexistence strategy
    guardian_coexistence: %{
      complexity: :medium,
      timeline: "1-2 days",
      risk_level: :low,
      description: "Use Guardian for API auth, PhoenixKit for web auth",
      prerequisites: ["Separate API and web authentication scopes"],
      steps: [
        "Configure Guardian for API-only authentication",
        "Set up PhoenixKit for web authentication", 
        "Update routing to separate API and web scopes",
        "Test both authentication systems independently",
        "Verify JWT tokens work for API calls",
        "Ensure web session management works correctly"
      ],
      rollback_plan: "Disable PhoenixKit, keep Guardian as primary",
      success_criteria: ["API auth via JWT tokens", "Web auth via sessions", "No route conflicts"]
    },
    
    # Pow replacement strategy
    pow_replacement: %{
      complexity: :high,
      timeline: "1-2 weeks",
      risk_level: :high,
      description: "Replace Pow with PhoenixKit",
      prerequisites: ["User data backup", "Comprehensive test coverage"],
      steps: [
        "Backup existing user data and authentication state",
        "Analyze Pow-specific user schema and data",
        "Create data migration scripts for user accounts",
        "Remove Pow dependencies and configuration",
        "Install PhoenixKit with compatible user schema",
        "Migrate user data to PhoenixKit format",
        "Update all authentication-related code",
        "Test authentication flows thoroughly",
        "Deploy with rollback plan ready"
      ],
      rollback_plan: "Restore Pow configuration and user data from backup",
      success_criteria: ["All users can log in", "All auth features work", "No data loss"]
    },
    
    # Coherence replacement strategy  
    coherence_replacement: %{
      complexity: :low,
      timeline: "1-3 days", 
      risk_level: :low,
      description: "Replace deprecated Coherence with PhoenixKit",
      prerequisites: ["User data analysis"],
      steps: [
        "Analyze existing Coherence user data structure",
        "Remove Coherence dependencies",
        "Install PhoenixKit",
        "Create user data mapping migration",
        "Test authentication with existing users",
        "Update any Coherence-specific code patterns"
      ],
      rollback_plan: "Restore Coherence configuration (not recommended)",
      success_criteria: ["Existing users can log in", "All features migrated", "Improved security"]
    },
    
    # Multiple auth systems resolution
    multiple_systems_resolution: %{
      complexity: :high,
      timeline: "2-4 weeks",
      risk_level: :high, 
      description: "Consolidate multiple authentication systems",
      prerequisites: ["Complete audit of all auth systems", "Stakeholder alignment"],
      steps: [
        "Audit all existing authentication systems",
        "Map user data across all systems",
        "Choose primary authentication strategy",
        "Plan user account consolidation",
        "Create comprehensive migration scripts",
        "Implement gradual migration approach",
        "Test each migration phase thoroughly",
        "Communicate changes to users",
        "Monitor post-migration authentication"
      ],
      rollback_plan: "Phase-based rollback to previous stable state",
      success_criteria: ["Single auth system", "All users migrated", "No service disruption"]
    },
    
    # Clean installation strategy
    clean_installation: %{
      complexity: :low,
      timeline: "1-2 hours",
      risk_level: :low,
      description: "Fresh PhoenixKit installation with no conflicts",
      prerequisites: ["No existing auth systems"],
      steps: [
        "Run PhoenixKit professional installer",
        "Configure authentication settings",
        "Test basic authentication flows",
        "Set up user registration and login",
        "Configure email and password reset"
      ],
      rollback_plan: "Remove PhoenixKit configuration",
      success_criteria: ["Full authentication system working", "All routes accessible"]
    }
  }

  @doc """
  Генерирует персонализированную стратегию миграции на основе анализа конфликтов.
  
  ## Parameters
  
  - `dependency_analysis` - Результат анализа зависимостей
  - `config_analysis` - Результат анализа конфигураций  
  - `code_analysis` - Результат анализа кода
  - `opts` - Опции генерации стратегии:
    - `:risk_tolerance` - Уровень толерантности к рискам (:low, :medium, :high)
    - `:timeline_preference` - Предпочтительные временные рамки (:fast, :balanced, :thorough)
    - `:migration_approach` - Подход к миграции (:replace, :coexist, :gradual)
  
  ## Returns
  
  - `{:ok, migration_strategy}` - рекомендованная стратегия миграции
  - `{:error, reason}` - ошибка при генерации стратегии
  """
  def generate_migration_strategy(dependency_analysis, config_analysis, code_analysis, opts \\ []) do
    Logger.info("🎯 Generating personalized migration strategy")
    
    __risk_tolerance = Keyword.get(opts, :risk_tolerance, :medium)
    __timeline_preference = Keyword.get(opts, :timeline_preference, :balanced)
    migration_approach = Keyword.get(opts, :migration_approach, :auto)
    
    try do
      conflict_profile = build_conflict_profile(dependency_analysis, config_analysis, code_analysis)
      base_strategy = determine_base_strategy(conflict_profile, migration_approach)
      customized_strategy = customize_strategy(base_strategy, conflict_profile, opts)
      
      migration_strategy = %{
        strategy_name: customized_strategy.name,
        conflict_profile: conflict_profile,
        base_strategy: base_strategy,
        customized_steps: customized_strategy.steps,
        estimated_complexity: customized_strategy.complexity,
        estimated_timeline: customized_strategy.timeline,
        risk_assessment: customized_strategy.risk_level,
        prerequisites: customized_strategy.prerequisites,
        success_criteria: customized_strategy.success_criteria,
        rollback_plan: customized_strategy.rollback_plan,
        recommendations: generate_specific_recommendations(conflict_profile),
        warnings: generate_warnings(conflict_profile, customized_strategy),
        next_steps: generate_immediate_next_steps(customized_strategy)
      }
      
      log_migration_strategy_summary(migration_strategy)
      {:ok, migration_strategy}
    rescue
      error ->
        Logger.error("❌ Failed to generate migration strategy: #{inspect(error)}")
        {:error, {:strategy_generation_failed, error}}
    end
  end

  @doc """
  Предоставляет детальную оценку рисков для конкретной стратегии миграции.
  """
  def assess_migration_risks(migration_strategy) do
    base_risks = get_base_strategy_risks(migration_strategy.base_strategy)
    conflict_risks = assess_conflict_specific_risks(migration_strategy.conflict_profile)
    implementation_risks = assess_implementation_risks(migration_strategy)
    
    %{
      overall_risk_level: calculate_overall_risk(base_risks, conflict_risks, implementation_risks),
      base_strategy_risks: base_risks,
      conflict_specific_risks: conflict_risks,
      implementation_risks: implementation_risks,
      mitigation_strategies: generate_risk_mitigation_strategies(base_risks, conflict_risks),
      risk_monitoring_plan: generate_risk_monitoring_plan(migration_strategy)
    }
  end

  @doc """
  Генерирует детальный план выполнения миграции.
  """
  def generate_execution_plan(migration_strategy) do
    phases = break_down_into_phases(migration_strategy.customized_steps)
    
    %{
      total_phases: length(phases),
      phases: phases,
      estimated_total_time: calculate_total_time(phases),
      resource_requirements: assess_resource_requirements(migration_strategy),
      checkpoints: define_checkpoints(phases),
      rollback_triggers: define_rollback_triggers(migration_strategy),
      testing_strategy: generate_testing_strategy(migration_strategy)
    }
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp build_conflict_profile(dependency_analysis, config_analysis, code_analysis) do
    %{
      has_dependencies: length(dependency_analysis.found_auth_libraries) > 0,
      auth_libraries: dependency_analysis.found_auth_libraries,
      dependency_conflicts: dependency_analysis.conflicts,
      config_conflicts: config_analysis.conflicts,
      code_conflicts: code_analysis.conflicts,
      has_user_schemas: length(code_analysis.user_schemas) > 0,
      user_schema_count: length(code_analysis.user_schemas),
      migration_complexity: code_analysis.migration_complexity,
      requires_data_migration: code_analysis.requires_data_migration,
      total_high_conflicts: count_high_priority_conflicts(dependency_analysis, config_analysis, code_analysis),
      conflict_categories: categorize_all_conflicts(dependency_analysis, config_analysis, code_analysis)
    }
  end

  defp determine_base_strategy(conflict_profile, :auto) do
    cond do
      conflict_profile.total_high_conflicts == 0 and not conflict_profile.has_dependencies ->
        :clean_installation
      
      :guardian in conflict_profile.auth_libraries and can_coexist_with_guardian?(conflict_profile) ->
        :guardian_coexistence
      
      :pow in conflict_profile.auth_libraries ->
        :pow_replacement
      
      :coherence in conflict_profile.auth_libraries ->
        :coherence_replacement
      
      length(conflict_profile.auth_libraries) > 1 ->
        :multiple_systems_resolution
      
      true ->
        :clean_installation
    end
  end

  defp determine_base_strategy(_conflict_profile, strategy) when strategy in [:replace, :coexist, :gradual] do
    case strategy do
      :replace -> :pow_replacement  # Default replacement strategy
      :coexist -> :guardian_coexistence
      :gradual -> :multiple_systems_resolution
    end
  end

  defp customize_strategy(base_strategy, conflict_profile, opts) do
    base_strategy_config = Map.get(@migration_strategies, base_strategy)
    
    # Кастомизируем стратегию на основе конкретного конфликт профиля
    customized_steps = customize_steps(base_strategy_config.steps, conflict_profile)
    adjusted_complexity = adjust_complexity(base_strategy_config.complexity, conflict_profile)
    adjusted_timeline = adjust_timeline(base_strategy_config.timeline, conflict_profile, opts)
    
    %{
      name: base_strategy,
      steps: customized_steps,
      complexity: adjusted_complexity,
      timeline: adjusted_timeline,
      risk_level: base_strategy_config.risk_level,
      prerequisites: base_strategy_config.prerequisites,
      success_criteria: base_strategy_config.success_criteria,
      rollback_plan: base_strategy_config.rollback_plan
    }
  end

  defp customize_steps(base_steps, conflict_profile) do
    # Добавляем шаги, специфичные для найденных конфликтов
    additional_steps = []
    
    additional_steps = if conflict_profile.has_user_schemas do
      additional_steps ++ ["Create user data backup before migration"]
    else
      additional_steps
    end
    
    additional_steps = if :guardian in conflict_profile.auth_libraries do
      additional_steps ++ ["Configure Guardian for API-only access"]
    else
      additional_steps
    end
    
    additional_steps ++ base_steps
  end

  defp adjust_complexity(base_complexity, conflict_profile) do
    # Увеличиваем сложность в зависимости от количества конфликтов
    case {base_complexity, conflict_profile.total_high_conflicts} do
      {:low, count} when count > 2 -> :medium
      {:medium, count} when count > 3 -> :high
      {complexity, _} -> complexity
    end
  end

  defp adjust_timeline(base_timeline, _conflict_profile, opts) do
    timeline_preference = Keyword.get(opts, :timeline_preference, :balanced)
    
    # Корректируем timeline на основе сложности конфликтов и предпочтений
    case timeline_preference do
      :fast -> reduce_timeline(base_timeline)
      :thorough -> extend_timeline(base_timeline)
      :balanced -> base_timeline
    end
  end

  defp generate_specific_recommendations(conflict_profile) do
    recommendations = ["Migration strategy customized for your application"]
    
    recommendations = if conflict_profile.requires_data_migration do
      recommendations ++ [
        "⚠️  Data migration required - ensure comprehensive backups",
        "Consider testing migration on database copy first"
      ]
    else
      recommendations
    end
    
    recommendations = if conflict_profile.total_high_conflicts > 0 do
      recommendations ++ [
        "🚨 High-priority conflicts detected - careful planning required",
        "Consider staged migration approach to minimize risks"
      ]
    else
      recommendations
    end
    
    recommendations
  end

  defp generate_warnings(conflict_profile, strategy) do
    warnings = []
    
    warnings = if strategy.risk_level == :high do
      warnings ++ ["🚨 High-risk migration - comprehensive testing essential"]
    else
      warnings
    end
    
    warnings = if conflict_profile.user_schema_count > 1 do
      warnings ++ ["⚠️  Multiple user schemas detected - data consolidation complex"]
    else
      warnings
    end
    
    warnings
  end

  defp generate_immediate_next_steps(strategy) do
    case strategy.name do
      :clean_installation ->
        [
          "Run: mix phoenix_kit.install.pro",
          "Test basic authentication flows",
          "Configure production settings"
        ]
      
      :guardian_coexistence ->
        [
          "Review Guardian configuration for API-only usage",
          "Plan routing separation strategy",
          "Run PhoenixKit installer with custom prefix"
        ]
      
      :pow_replacement ->
        [
          "Create comprehensive backup of user data",
          "Analyze Pow user schema structure",
          "Plan migration timeline with stakeholders"
        ]
      
      _ ->
        [
          "Review detailed migration plan",
          "Gather required resources and approvals",
          "Set up testing environment"
        ]
    end
  end

  defp count_high_priority_conflicts(dependency_analysis, config_analysis, code_analysis) do
    dep_high = Enum.count(dependency_analysis.conflicts, &(&1.conflict_level == :high))
    config_high = length(config_analysis.high_priority_conflicts)
    code_critical = length(code_analysis.critical_conflicts)
    
    dep_high + config_high + code_critical
  end

  defp categorize_all_conflicts(dependency_analysis, config_analysis, code_analysis) do
    %{
      dependency: Enum.map(dependency_analysis.conflicts, & %{type: &1.library, level: &1.conflict_level}),
      configuration: Enum.map(config_analysis.conflicts, & %{type: &1.type, level: &1.priority}),
      code: Enum.map(code_analysis.conflicts, & %{type: &1.type, level: &1.severity})
    }
  end

  defp can_coexist_with_guardian?(conflict_profile) do
    # Guardian может сосуществовать, если нет других высоко-конфликтных библиотек
    high_conflict_libraries = [:pow, :coherence]
    not Enum.any?(high_conflict_libraries, &(&1 in conflict_profile.auth_libraries))
  end

  defp get_base_strategy_risks(strategy_name) do
    base_strategy = Map.get(@migration_strategies, strategy_name)
    
    %{
      inherent_risk: base_strategy.risk_level,
      complexity_risk: base_strategy.complexity,
      timeline_risk: assess_timeline_risk(base_strategy.timeline)
    }
  end

  defp assess_conflict_specific_risks(conflict_profile) do
    %{
      data_migration_risk: if(conflict_profile.requires_data_migration, do: :high, else: :low),
      multiple_systems_risk: assess_multiple_systems_risk(conflict_profile.auth_libraries),
      user_schema_risk: assess_user_schema_risk(conflict_profile.user_schema_count)
    }
  end

  defp assess_implementation_risks(migration_strategy) do
    %{
      step_complexity_risk: assess_step_complexity_risk(migration_strategy.customized_steps),
      rollback_risk: assess_rollback_complexity(migration_strategy.rollback_plan),
      testing_coverage_risk: :medium  # Default assumption
    }
  end

  defp calculate_overall_risk(base_risks, conflict_risks, implementation_risks) do
    # Простая логика для расчёта общего риска
    all_risks = [
      base_risks.inherent_risk,
      conflict_risks.data_migration_risk,
      conflict_risks.multiple_systems_risk,
      implementation_risks.rollback_risk
    ]
    
    cond do
      :high in all_risks -> :high
      Enum.count(all_risks, &(&1 == :medium)) >= 2 -> :high
      :medium in all_risks -> :medium
      true -> :low
    end
  end

  defp generate_risk_mitigation_strategies(_base_risks, conflict_risks) do
    strategies = ["Implement comprehensive backup strategy"]
    
    strategies = if conflict_risks.data_migration_risk == :high do
      strategies ++ [
        "Test migration on database copy first",
        "Implement gradual user migration approach",
        "Set up monitoring for authentication failures"
      ]
    else
      strategies
    end
    
    strategies
  end

  defp generate_risk_monitoring_plan(_migration_strategy) do
    %{
      key_metrics: [
        "Authentication success rate",
        "User login failures",
        "Database migration errors",
        "System performance impact"
      ],
      monitoring_frequency: "Every 15 minutes during migration",
      alert_thresholds: %{
        login_failure_rate: "> 5%",
        migration_errors: "> 0",
        response_time_increase: "> 50%"
      },
      rollback_triggers: [
        "Login failure rate exceeds 10%",
        "Critical migration errors",
        "System unavailability > 5 minutes"
      ]
    }
  end

  defp break_down_into_phases(steps) do
    # Разбиваем шаги на логические фазы
    steps
    |> Enum.chunk_every(3)
    |> Enum.with_index(1)
    |> Enum.map(fn {phase_steps, index} ->
      %{
        phase_number: index,
        name: "Phase #{index}",
        steps: phase_steps,
        estimated_duration: estimate_phase_duration(phase_steps),
        dependencies: if(index == 1, do: [], else: ["Phase #{index - 1}"])
      }
    end)
  end

  defp calculate_total_time(phases) do
    phases
    |> Enum.map(& &1.estimated_duration)
    |> Enum.reduce(0, &(&1 + &2))
  end

  defp assess_resource_requirements(migration_strategy) do
    %{
      team_size: assess_required_team_size(migration_strategy.complexity),
      skills_required: assess_required_skills(migration_strategy),
      infrastructure: assess_infrastructure_needs(migration_strategy),
      estimated_effort: "#{migration_strategy.timeline} of focused work"
    }
  end

  defp define_checkpoints(phases) do
    Enum.map(phases, fn phase ->
      %{
        phase: phase.phase_number,
        checkpoint_name: "Phase #{phase.phase_number} Complete",
        success_criteria: ["All phase steps completed", "No critical errors", "Functionality verified"],
        go_no_go_decision: "Proceed to next phase or rollback"
      }
    end)
  end

  defp define_rollback_triggers(_migration_strategy) do
    [
      "Critical authentication system failure",
      "Data corruption detected",
      "Unacceptable performance degradation",
      "User access completely blocked",
      "Migration timeline exceeded by 100%"
    ]
  end

  defp generate_testing_strategy(_migration_strategy) do
    %{
      testing_phases: [
        "Unit testing of migration components",
        "Integration testing with existing systems", 
        "User acceptance testing of auth flows",
        "Performance testing under load",
        "Rollback procedure testing"
      ],
      test_environments: ["Development", "Staging", "Pre-production"],
      test_data_strategy: "Use anonymized production data subset",
      automation_level: "Automated where possible, manual for user flows"
    }
  end

  # Helper functions for risk and complexity assessment
  defp assess_timeline_risk(timeline) do
    cond do
      String.contains?(timeline, "week") -> :medium
      String.contains?(timeline, "day") -> :low
      String.contains?(timeline, "hour") -> :low
      true -> :medium
    end
  end

  defp assess_multiple_systems_risk(auth_libraries) do
    case length(auth_libraries) do
      0 -> :low
      1 -> :low
      2 -> :medium
      _ -> :high
    end
  end

  defp assess_user_schema_risk(schema_count) do
    case schema_count do
      0 -> :low
      1 -> :low
      _ -> :high
    end
  end

  defp assess_step_complexity_risk(steps) do
    complex_keywords = ["migrate", "backup", "consolidate", "replace"]
    
    complex_steps = Enum.count(steps, fn step ->
      Enum.any?(complex_keywords, &String.contains?(String.downcase(step), &1))
    end)
    
    case complex_steps do
      count when count > 5 -> :high
      count when count > 2 -> :medium
      _ -> :low
    end
  end

  defp assess_rollback_complexity(rollback_plan) do
    if String.contains?(rollback_plan, "backup") or String.contains?(rollback_plan, "restore") do
      :medium
    else
      :low
    end
  end

  defp reduce_timeline(timeline), do: timeline  # TODO: Implement timeline reduction logic
  defp extend_timeline(timeline), do: timeline  # TODO: Implement timeline extension logic

  defp estimate_phase_duration(steps) do
    # Простая оценка: 1 час на шаг
    length(steps)
  end

  defp assess_required_team_size(complexity) do
    case complexity do
      :low -> "1-2 developers"
      :medium -> "2-3 developers + 1 DevOps"
      :high -> "3-5 developers + 1-2 DevOps + 1 architect"
    end
  end

  defp assess_required_skills(migration_strategy) do
    base_skills = ["Elixir/Phoenix", "Database migrations", "Authentication systems"]
    
    additional_skills = case migration_strategy.strategy_name do
      :guardian_coexistence -> ["JWT tokens", "API design"]
      :pow_replacement -> ["Data migration", "User management systems"]
      :multiple_systems_resolution -> ["System architecture", "Data consolidation"]
      _ -> []
    end
    
    base_skills ++ additional_skills
  end

  defp assess_infrastructure_needs(migration_strategy) do
    base_needs = ["Staging environment", "Database backup system"]
    
    case migration_strategy.risk_assessment do
      :high -> base_needs ++ ["Pre-production environment", "Monitoring systems", "Rollback automation"]
      :medium -> base_needs ++ ["Enhanced monitoring"]
      :low -> base_needs
    end
  end

  defp log_migration_strategy_summary(strategy) do
    Logger.info("📊 Migration Strategy Summary:")
    Logger.info("   Strategy: #{strategy.strategy_name}")
    Logger.info("   Complexity: #{strategy.estimated_complexity}")
    Logger.info("   Timeline: #{strategy.estimated_timeline}")
    Logger.info("   Risk Level: #{strategy.risk_assessment}")
    Logger.info("   Steps: #{length(strategy.customized_steps)}")
    Logger.info("   Prerequisites: #{length(strategy.prerequisites)}")
    Logger.info("   Warnings: #{length(strategy.warnings)}")
  end
end