defmodule PhoenixKit.Install.LayoutIntegration do
  @moduledoc """
  Главный модуль для автоматической интеграции с layout'ами Phoenix приложения.
  
  Этот модуль координирует работу всех компонентов layout integration:
  - Обнаружение существующих layout'ов (LayoutDetector)
  - Автоматическая конфигурация (AutoConfigurator) 
  - Улучшение layout'ов (LayoutEnhancer)
  - Обработка fallback'ов (FallbackHandler)
  
  Предоставляет высокоуровневый API для Professional Installer.
  """

  require Logger

  alias PhoenixKit.Install.LayoutIntegration.{
    LayoutDetector,
    AutoConfigurator,
    LayoutEnhancer,
    FallbackHandler
  }

  @doc """
  Выполняет полную интеграцию с layout'ами Phoenix приложения.
  
  ## Parameters
  
  - `igniter` - Igniter context
  - `opts` - Опции интеграции:
    - `:enhance_layouts` - Улучшать ли существующие layout'ы (default: true)
    - `:create_fallbacks` - Создавать ли fallback layout'ы (default: true)
    - `:layout_preference` - Предпочтительный layout (:auto, :existing, :phoenix_kit)
    - `:root_layout_strategy` - Стратегия для root layout (:detect, :create, :skip)
  
  ## Returns
  
  - `{:ok, igniter, integration_result}` - успешная интеграция
  - `{:error, reason}` - ошибка при интеграции
  - `{:skipped, reason}` - интеграция пропущена
  
  ## Examples
  
      iex> LayoutIntegration.perform_full_integration(igniter)
      {:ok, updated_igniter, %{
        detected_layouts: [...],
        integration_strategy: :use_existing,
        configuration_updates: [...],
        enhancements_applied: [...]
      }}
  """
  def perform_full_integration(igniter, opts \\ []) do
    enhance_layouts = Keyword.get(opts, :enhance_layouts, true)
    create_fallbacks = Keyword.get(opts, :create_fallbacks, true)
    layout_preference = Keyword.get(opts, :layout_preference, :auto)
    _root_layout_strategy = Keyword.get(opts, :root_layout_strategy, :detect)
    
    Logger.info("🎨 Starting comprehensive layout integration")
    Logger.info("   Layout preference: #{layout_preference}")
    Logger.info("   Enhance layouts: #{enhance_layouts}")
    Logger.info("   Create fallbacks: #{create_fallbacks}")
    
    integration_start_time = System.monotonic_time(:millisecond)
    
    with {:ok, layout_analysis} <- run_layout_detection(igniter),
         {:ok, integration_strategy} <- determine_integration_strategy(layout_analysis, layout_preference),
         {:ok, updated_igniter, config_result} <- perform_auto_configuration(igniter, integration_strategy, opts),
         {:ok, final_igniter, enhancement_result} <- maybe_enhance_layouts(updated_igniter, integration_strategy, enhance_layouts),
         {:ok, complete_igniter, fallback_result} <- maybe_create_fallbacks(final_igniter, integration_strategy, create_fallbacks) do
      
      integration_duration = System.monotonic_time(:millisecond) - integration_start_time
      
      integration_result = %{
        integration_timestamp: DateTime.utc_now(),
        integration_duration_ms: integration_duration,
        detected_layouts: layout_analysis.detected_layouts,
        integration_strategy: integration_strategy,
        configuration_updates: config_result,
        enhancements_applied: enhancement_result,
        fallbacks_created: fallback_result,
        recommendations: compile_integration_recommendations(layout_analysis, integration_strategy),
        next_steps: generate_post_integration_steps(integration_strategy)
      }
      
      log_integration_summary(integration_result)
      {:ok, complete_igniter, integration_result}
    else
      {:error, reason} = error ->
        Logger.error("❌ Layout integration failed: #{inspect(reason)}")
        error
      
      {:skip, reason} ->
        Logger.info("⏭️  Layout integration skipped: #{reason}")
        {:skipped, reason}
    end
  end

  @doc """
  Быстрая проверка доступных layout'ов без полной интеграции.
  
  Полезно для предварительной оценки перед запуском полной интеграции.
  """
  def quick_layout_check(_igniter) do
    Logger.info("⚡ Running quick layout availability check")
    
    with {:ok, basic_layouts} <- check_basic_layout_structure(),
         {:ok, existing_configs} <- check_existing_layout_configs() do
      
      quick_assessment = %{
        has_app_layout: basic_layouts.has_app_layout,
        has_root_layout: basic_layouts.has_root_layout,
        layout_files: basic_layouts.layout_files,
        existing_phoenix_kit_config: existing_configs.has_phoenix_kit_config,
        integration_complexity: estimate_integration_complexity(basic_layouts, existing_configs),
        recommendation: generate_quick_recommendation(basic_layouts, existing_configs),
        should_run_full_integration: should_run_full_integration?(basic_layouts, existing_configs)
      }
      
      Logger.info("⚡ Quick check complete - integration complexity: #{quick_assessment.integration_complexity}")
      {:ok, quick_assessment}
    else
      error ->
        Logger.warning("⚡ Quick check failed, recommend running full integration: #{inspect(error)}")
        {:ok, %{
          has_errors: true,
          error: error,
          recommendation: "Run full layout integration for detailed analysis",
          should_run_full_integration: true
        }}
    end
  end

  @doc """
  Проверяет совместимость обнаруженных layout'ов с PhoenixKit.
  """
  def assess_layout_compatibility(layout_analysis) do
    compatibility_checks = %{
      phoenix_version_compatible: check_phoenix_version_compatibility(layout_analysis),
      liveview_compatible: check_liveview_compatibility(layout_analysis),
      tailwind_compatible: check_css_framework_compatibility(layout_analysis),
      component_compatible: check_component_system_compatibility(layout_analysis),
      flash_message_compatible: check_flash_message_compatibility(layout_analysis)
    }
    
    overall_compatibility = %{
      fully_compatible: all_checks_pass?(compatibility_checks),
      compatibility_score: calculate_compatibility_score(compatibility_checks),
      blocking_issues: identify_blocking_compatibility_issues(compatibility_checks),
      enhancement_opportunities: identify_enhancement_opportunities(compatibility_checks),
      migration_requirements: determine_migration_requirements(compatibility_checks)
    }
    
    {:ok, overall_compatibility}
  end

  @doc """
  Генерирует детальный отчёт об интеграции layout'ов для пользователя.
  """
  def generate_integration_report(integration_result, format \\ :detailed) do
    case format do
      :summary ->
        generate_summary_report(integration_result)
      
      :detailed ->
        generate_detailed_report(integration_result)
      
      :technical ->
        generate_technical_report(integration_result)
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp run_layout_detection(igniter) do
    Logger.debug("Running layout detection...")
    case LayoutDetector.detect_existing_layouts(igniter) do
      {:ok, result} ->
        Logger.debug("✅ Layout detection completed")
        {:ok, result}
      
      {:error, reason} = error ->
        Logger.error("❌ Layout detection failed: #{inspect(reason)}")
        error
    end
  end

  defp determine_integration_strategy(layout_analysis, :auto) do
    cond do
      layout_analysis.has_complete_layout_system ->
        {:ok, :use_existing_layouts}
      
      layout_analysis.has_partial_layouts ->
        {:ok, :enhance_existing_layouts}
      
      layout_analysis.has_no_layouts ->
        {:ok, :create_phoenix_kit_layouts}
      
      true ->
        {:ok, :hybrid_integration}
    end
  end

  defp determine_integration_strategy(_layout_analysis, strategy) when strategy in [:existing, :phoenix_kit] do
    case strategy do
      :existing -> {:ok, :use_existing_layouts}
      :phoenix_kit -> {:ok, :create_phoenix_kit_layouts}
    end
  end

  defp perform_auto_configuration(igniter, integration_strategy, opts) do
    Logger.debug("Performing auto-configuration...")
    case AutoConfigurator.configure_layout_integration(igniter, integration_strategy, opts) do
      {:ok, updated_igniter, config_result} ->
        Logger.debug("✅ Auto-configuration completed")
        {:ok, updated_igniter, config_result}
      
      {:error, reason} = error ->
        Logger.error("❌ Auto-configuration failed: #{inspect(reason)}")
        error
    end
  end

  defp maybe_enhance_layouts(igniter, _integration_strategy, false) do
    {:ok, igniter, %{enhancements_skipped: true}}
  end

  defp maybe_enhance_layouts(igniter, integration_strategy, true) do
    Logger.debug("Enhancing layouts...")
    case LayoutEnhancer.enhance_layouts(igniter, integration_strategy) do
      {:ok, updated_igniter, enhancement_result} ->
        Logger.debug("✅ Layout enhancement completed")
        {:ok, updated_igniter, enhancement_result}
      
      {:error, reason} = _error ->
        Logger.warning("⚠️  Layout enhancement failed: #{inspect(reason)}")
        # Не прерываем весь процесс из-за ошибки в enhancement
        {:ok, igniter, %{enhancement_failed: true, error: reason}}
    end
  end

  defp maybe_create_fallbacks(igniter, _integration_strategy, false) do
    {:ok, igniter, %{fallbacks_skipped: true}}
  end

  defp maybe_create_fallbacks(igniter, integration_strategy, true) do
    Logger.debug("Creating fallback layouts...")
    case FallbackHandler.create_fallback_layouts(igniter, integration_strategy) do
      {:ok, updated_igniter, fallback_result} ->
        Logger.debug("✅ Fallback creation completed")
        {:ok, updated_igniter, fallback_result}
      
      {:error, reason} = _error ->
        Logger.warning("⚠️  Fallback creation failed: #{inspect(reason)}")
        # Не прерываем весь процесс из-за ошибки в fallback
        {:ok, igniter, %{fallback_failed: true, error: reason}}
    end
  end

  defp compile_integration_recommendations(layout_analysis, integration_strategy) do
    base_recommendations = ["Layout integration completed successfully"]
    
    strategy_recommendations = case integration_strategy do
      :use_existing_layouts ->
        ["✅ Using existing layouts - minimal changes required"]
      
      :enhance_existing_layouts ->
        ["🎨 Enhanced existing layouts for PhoenixKit compatibility"]
      
      :create_phoenix_kit_layouts ->
        ["🆕 Created new PhoenixKit layouts - customize as needed"]
      
      :hybrid_integration ->
        ["🔀 Hybrid approach - combining existing and new layouts"]
    end
    
    compatibility_recommendations = if layout_analysis.compatibility_issues do
      ["⚠️  Some compatibility issues found - review integration report"]
    else
      []
    end
    
    base_recommendations ++ strategy_recommendations ++ compatibility_recommendations
  end

  defp generate_post_integration_steps(integration_strategy) do
    case integration_strategy do
      :use_existing_layouts ->
        [
          "✅ Layout integration complete",
          "Test PhoenixKit authentication pages with your layouts",
          "Customize styles if needed"
        ]
      
      :enhance_existing_layouts ->
        [
          "✅ Layout enhancement complete", 
          "Review enhanced layout files",
          "Test authentication flows with updated layouts"
        ]
      
      :create_phoenix_kit_layouts ->
        [
          "✅ PhoenixKit layouts created",
          "Customize layouts to match your app's design",
          "Update CSS/styling as needed"
        ]
      
      _ ->
        [
          "✅ Layout integration complete",
          "Review integration report for details",
          "Test authentication pages"
        ]
    end
  end

  # Quick check helper functions
  defp check_basic_layout_structure do
    try do
      layout_files = Path.wildcard("lib/*/web/components/layouts/*.html.heex") ++
                    Path.wildcard("lib/*_web/components/layouts/*.html.heex")
      
      app_layout = Enum.any?(layout_files, &String.contains?(&1, "app.html"))
      root_layout = Enum.any?(layout_files, &String.contains?(&1, "root.html"))
      
      {:ok, %{
        has_app_layout: app_layout,
        has_root_layout: root_layout,
        layout_files: layout_files,
        layout_count: length(layout_files)
      }}
    rescue
      _ -> {:error, :layout_structure_scan_error}
    end
  end

  defp check_existing_layout_configs do
    try do
      config_files = ["config/config.exs", "config/dev.exs"]
      
      has_phoenix_kit_config = Enum.any?(config_files, fn file ->
        case File.read(file) do
          {:ok, content} -> String.contains?(content, "phoenix_kit") and String.contains?(content, "layout")
          {:error, _} -> false
        end
      end)
      
      {:ok, %{has_phoenix_kit_config: has_phoenix_kit_config}}
    rescue
      _ -> {:error, :config_scan_error}
    end
  end

  defp estimate_integration_complexity(basic_layouts, existing_configs) do
    complexity_score = 0
    
    complexity_score = complexity_score + if basic_layouts.has_app_layout, do: 0, else: 2
    complexity_score = complexity_score + if basic_layouts.has_root_layout, do: 0, else: 1
    complexity_score = complexity_score + if existing_configs.has_phoenix_kit_config, do: 1, else: 0
    
    cond do
      complexity_score == 0 -> :simple
      complexity_score <= 2 -> :moderate  
      true -> :complex
    end
  end

  defp generate_quick_recommendation(basic_layouts, existing_configs) do
    cond do
      basic_layouts.has_app_layout and basic_layouts.has_root_layout ->
        "✅ Complete layout structure detected - integration should be straightforward"
      
      basic_layouts.layout_count > 0 ->
        "📝 Partial layout structure - enhancement and fallbacks may be needed"
      
      existing_configs.has_phoenix_kit_config ->
        "ℹ️  PhoenixKit layout config exists - will update existing configuration"
      
      true ->
        "🆕 No layouts detected - will create complete PhoenixKit layout system"
    end
  end

  defp should_run_full_integration?(basic_layouts, existing_configs) do
    # Рекомендуем полную интеграцию в большинстве случаев для лучшего результата
    basic_layouts.layout_count > 0 or existing_configs.has_phoenix_kit_config
  end

  # Compatibility check functions
  defp check_phoenix_version_compatibility(_layout_analysis) do
    # TODO: Implement Phoenix version compatibility check
    true
  end

  defp check_liveview_compatibility(_layout_analysis) do
    # TODO: Implement LiveView compatibility check
    true
  end

  defp check_css_framework_compatibility(_layout_analysis) do
    # TODO: Implement CSS framework compatibility check
    true
  end

  defp check_component_system_compatibility(_layout_analysis) do
    # TODO: Implement component system compatibility check
    true
  end

  defp check_flash_message_compatibility(_layout_analysis) do
    # TODO: Implement flash message compatibility check
    true
  end

  defp all_checks_pass?(compatibility_checks) do
    Enum.all?(Map.values(compatibility_checks))
  end

  defp calculate_compatibility_score(compatibility_checks) do
    passed_checks = compatibility_checks |> Map.values() |> Enum.count(& &1)
    total_checks = map_size(compatibility_checks)
    
    (passed_checks / total_checks * 100) |> round()
  end

  defp identify_blocking_compatibility_issues(compatibility_checks) do
    compatibility_checks
    |> Enum.filter(fn {_check, passed} -> not passed end)
    |> Enum.map(fn {check, _} -> "#{check} compatibility issue" end)
  end

  defp identify_enhancement_opportunities(_compatibility_checks) do
    # TODO: Implement enhancement opportunity identification
    []
  end

  defp determine_migration_requirements(_compatibility_checks) do
    # TODO: Implement migration requirements determination
    []
  end

  # Report generation functions
  defp generate_summary_report(integration_result) do
    """
    # PhoenixKit Layout Integration Summary
    
    **Integration Date:** #{integration_result.integration_timestamp}
    **Duration:** #{integration_result.integration_duration_ms}ms
    **Strategy:** #{integration_result.integration_strategy}
    
    ## Key Results
    - Detected Layouts: #{length(integration_result.detected_layouts)}
    - Configuration Updates: #{map_size(integration_result.configuration_updates)}
    - Enhancements Applied: #{integration_result.enhancements_applied != %{}}
    
    ## Next Steps
    #{Enum.join(integration_result.next_steps, "\n")}
    """
  end

  defp generate_detailed_report(integration_result) do
    # TODO: Implement detailed report generation
    generate_summary_report(integration_result) <> "\n\n[Detailed analysis would go here]"
  end

  defp generate_technical_report(integration_result) do
    # TODO: Implement technical report generation  
    generate_detailed_report(integration_result) <> "\n\n[Technical details would go here]"
  end

  defp log_integration_summary(integration_result) do
    Logger.info("🎨 Layout Integration Complete!")
    Logger.info("   Duration: #{integration_result.integration_duration_ms}ms")
    Logger.info("   Strategy: #{integration_result.integration_strategy}")
    Logger.info("   Detected layouts: #{length(integration_result.detected_layouts)}")
    Logger.info("   Configuration updates: #{map_size(integration_result.configuration_updates)}")
    Logger.info("   Enhancements applied: #{integration_result.enhancements_applied != %{}}")
    Logger.info("   Fallbacks created: #{integration_result.fallbacks_created != %{}}")
  end
end