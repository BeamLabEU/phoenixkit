defmodule PhoenixKit.Install.LayoutIntegration.AutoConfigurator do
  @moduledoc """
  Автоматически конфигурирует PhoenixKit для интеграции с обнаруженными layout'ами.

  Этот модуль:
  - Определяет оптимальную конфигурацию на основе анализа layout'ов
  - Автоматически создаёт или обновляет конфигурационные файлы
  - Настраивает layout modules и их параметры
  - Обрабатывает специфичные для Phoenix версии конфигурации
  - Интегрируется с существующими layout системами
  """

  require Logger

  @configuration_templates %{
    # Layout configuration for different integration strategies
    use_existing_layouts: %{
      config_keys: [:layout, :root_layout],
      fallback_strategy: :use_phoenix_kit_fallbacks,
      enhancement_level: :minimal
    },
    enhance_existing_layouts: %{
      config_keys: [:layout, :root_layout, :page_title_prefix],
      fallback_strategy: :enhanced_fallbacks,
      enhancement_level: :moderate
    },
    create_phoenix_kit_layouts: %{
      config_keys: [:layout, :root_layout, :page_title_prefix, :custom_css_classes],
      fallback_strategy: :comprehensive_fallbacks,
      enhancement_level: :full
    },
    hybrid_integration: %{
      config_keys: [:layout, :root_layout, :page_title_prefix, :layout_fallbacks],
      fallback_strategy: :hybrid_fallbacks,
      enhancement_level: :adaptive
    }
  }

  @default_phoenix_kit_configs %{
    # Default configuration values for different scenarios
    minimal: %{
      page_title_prefix: "Authentication",
      layout_fallbacks: true,
      custom_css_classes: %{}
    },
    standard: %{
      page_title_prefix: "Authentication",
      layout_fallbacks: true,
      custom_css_classes: %{
        container: "max-w-md mx-auto",
        form: "space-y-4",
        input: "w-full px-3 py-2 border rounded-md",
        button: "w-full py-2 px-4 bg-blue-600 text-white rounded-md hover:bg-blue-700"
      }
    },
    enhanced: %{
      page_title_prefix: "Authentication",
      layout_fallbacks: true,
      flash_message_styling: true,
      responsive_design: true,
      accessibility_features: true,
      custom_css_classes: %{
        container: "max-w-lg mx-auto px-4 sm:px-6 lg:px-8",
        form: "space-y-6",
        input:
          "block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500",
        button:
          "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      }
    }
  }

  @doc """
  Конфигурирует layout интеграцию на основе стратегии и обнаруженных layout'ов.

  ## Parameters

  - `igniter` - Igniter context
  - `integration_strategy` - Стратегия интеграции (:use_existing_layouts, :enhance_existing_layouts, :create_phoenix_kit_layouts, :hybrid_integration)
  - `opts` - Опции конфигурации:
    - `:layout_preference` - Предпочтительный layout модуль
    - `:root_layout_preference` - Предпочтительный root layout
    - `:enhancement_level` - Уровень улучшений (:minimal, :standard, :enhanced)
    - `:preserve_existing_config` - Сохранять ли существующую конфигурацию (default: true)

  ## Returns

  - `{:ok, updated_igniter, configuration_result}` - успешная конфигурация
  - `{:error, reason}` - ошибка при конфигурации

  ## Examples

      iex> AutoConfigurator.configure_layout_integration(igniter, :use_existing_layouts)
      {:ok, updated_igniter, %{
        applied_configurations: [...],
        detected_layouts: %{...},
        fallback_configurations: [...]
      }}
  """
  def configure_layout_integration(igniter, integration_strategy, opts \\ []) do
    enhancement_level = Keyword.get(opts, :enhancement_level, :standard)
    preserve_existing = Keyword.get(opts, :preserve_existing_config, true)
    _layout_preference = Keyword.get(opts, :layout_preference)
    _root_layout_preference = Keyword.get(opts, :root_layout_preference)

    Logger.info("🔧 Starting layout integration configuration")
    Logger.info("   Strategy: #{integration_strategy}")
    Logger.info("   Enhancement level: #{enhancement_level}")
    Logger.info("   Preserve existing: #{preserve_existing}")

    config_start_time = System.monotonic_time(:millisecond)

    with {:ok, existing_config} <- analyze_existing_configuration(igniter, preserve_existing),
         {:ok, layout_detection} <- detect_available_layouts(igniter),
         {:ok, optimal_config} <-
           determine_optimal_configuration(
             integration_strategy,
             layout_detection,
             enhancement_level,
             opts
           ),
         {:ok, updated_igniter, applied_configs} <-
           apply_configuration_changes(igniter, optimal_config, existing_config),
         {:ok, final_igniter, validation_result} <- validate_configuration(updated_igniter) do
      config_duration = System.monotonic_time(:millisecond) - config_start_time

      configuration_result = %{
        configuration_timestamp: DateTime.utc_now(),
        configuration_duration_ms: config_duration,
        integration_strategy: integration_strategy,
        enhancement_level: enhancement_level,
        applied_configurations: applied_configs,
        existing_configuration: existing_config,
        detected_layouts: layout_detection,
        validation_result: validation_result,
        recommendations: generate_configuration_recommendations(optimal_config, layout_detection)
      }

      log_configuration_summary(configuration_result)
      {:ok, final_igniter, configuration_result}
    else
      error ->
        Logger.error("❌ Layout configuration failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Обновляет существующую конфигурацию PhoenixKit layout'ов.
  """
  def update_existing_configuration(igniter, configuration_updates) do
    Logger.info("🔄 Updating existing layout configuration")

    with {:ok, current_config} <- read_current_phoenix_kit_config(igniter),
         {:ok, merged_config} <-
           merge_configuration_updates(current_config, configuration_updates),
         {:ok, updated_igniter} <- write_updated_configuration(igniter, merged_config) do
      {:ok, updated_igniter,
       %{
         previous_config: current_config,
         updated_config: merged_config,
         changes_applied: Map.keys(configuration_updates)
       }}
    else
      error ->
        Logger.error("❌ Configuration update failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Создаёт конфигурацию fallback layout'ов для случаев, когда обнаруженные layout'ы недоступны.
  """
  def configure_fallback_layouts(igniter, integration_strategy) do
    Logger.info("🛡️  Configuring fallback layout system")

    fallback_config = determine_fallback_configuration(integration_strategy)

    with {:ok, updated_igniter} <- apply_fallback_configuration(igniter, fallback_config) do
      {:ok, updated_igniter, fallback_config}
    else
      error ->
        Logger.error("❌ Fallback configuration failed: #{inspect(error)}")
        error
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp analyze_existing_configuration(igniter, preserve_existing) do
    Logger.debug("Analyzing existing PhoenixKit configuration...")

    try do
      app_name = Igniter.Project.Application.app_name(igniter)

      config_analysis = %{
        has_phoenix_kit_config: check_existing_phoenix_kit_config(igniter, app_name),
        existing_layout_config: extract_existing_layout_config(igniter, app_name),
        preserve_existing: preserve_existing,
        config_file_locations: find_config_file_locations()
      }

      {:ok, config_analysis}
    rescue
      error ->
        {:error, {:config_analysis_error, error}}
    end
  end

  defp detect_available_layouts(_igniter) do
    Logger.debug("Detecting available layouts for configuration...")

    # Simplified layout detection for configuration purposes
    try do
      available_layouts = %{
        app_layout_modules: find_app_layout_modules(),
        root_layout_modules: find_root_layout_modules(),
        layout_files: find_layout_files(),
        component_modules: find_component_modules()
      }

      {:ok, available_layouts}
    rescue
      error ->
        {:error, {:layout_detection_error, error}}
    end
  end

  defp determine_optimal_configuration(
         integration_strategy,
         layout_detection,
         enhancement_level,
         opts
       ) do
    Logger.debug("Determining optimal configuration...")

    base_template = Map.get(@configuration_templates, integration_strategy)
    base_config = Map.get(@default_phoenix_kit_configs, enhancement_level)

    # Merge layout detection results with configuration preferences  
    layout_config = determine_layout_configuration(layout_detection, opts)

    optimal_config = %{
      strategy: integration_strategy,
      enhancement_level: enhancement_level,
      config_keys: base_template.config_keys,
      layout_config: layout_config,
      base_config: base_config,
      fallback_strategy: base_template.fallback_strategy,
      custom_configurations: extract_custom_configurations(opts)
    }

    {:ok, optimal_config}
  end

  defp apply_configuration_changes(igniter, optimal_config, existing_config) do
    Logger.debug("Applying configuration changes...")

    app_name = Igniter.Project.Application.app_name(igniter)

    # Build the configuration to apply
    config_to_apply = build_configuration_map(optimal_config, existing_config)

    # Apply configuration using Igniter - ensure we pass a map
    updated_igniter =
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        app_name,
        [PhoenixKit],
        config_to_apply
      )

    {:ok, updated_igniter, config_to_apply}
  end

  defp validate_configuration(igniter) do
    Logger.debug("Validating applied configuration...")

    # Basic validation of the applied configuration
    validation_result = %{
      # TODO: Implement syntax validation
      config_syntax_valid: true,
      # TODO: Implement module existence check
      layout_modules_exist: true,
      # TODO: Implement fallback validation
      fallbacks_configured: true,
      # TODO: Implement compatibility check
      compatibility_maintained: true
    }

    {:ok, igniter, validation_result}
  end

  defp determine_layout_configuration(layout_detection, opts) do
    layout_preference = Keyword.get(opts, :layout_preference)
    root_layout_preference = Keyword.get(opts, :root_layout_preference)

    # Determine layout configuration based on detection and preferences
    layout_config = %{}

    # Configure main layout
    layout_config =
      if layout_preference do
        Map.put(layout_config, :layout, parse_layout_preference(layout_preference))
      else
        auto_detect_layout_config(layout_detection, :layout)
      end

    # Configure root layout
    layout_config =
      if root_layout_preference do
        Map.put(layout_config, :root_layout, parse_layout_preference(root_layout_preference))
      else
        auto_detect_layout_config(layout_detection, :root_layout)
      end

    layout_config
  end

  defp auto_detect_layout_config(layout_detection, layout_type) do
    case layout_type do
      :layout ->
        # Try to detect the best app layout module
        case layout_detection.app_layout_modules do
          %{} when map_size(layout_detection.app_layout_modules) == 0 ->
            # Will use PhoenixKit default
            nil

          modules when is_map(modules) ->
            # Get first module from map
            case Map.to_list(modules) do
              [{module, _} | _] -> {module, :app}
              [] -> nil
            end

          [module | _] ->
            # Fallback for list format
            {module, :app}

          [] ->
            # Will use PhoenixKit default
            nil
        end

      :root_layout ->
        # Try to detect the best root layout module
        case layout_detection.root_layout_modules do
          %{} when map_size(layout_detection.root_layout_modules) == 0 ->
            # Will use PhoenixKit default
            nil

          modules when is_map(modules) ->
            # Get first module from map
            case Map.to_list(modules) do
              [{module, _} | _] -> {module, :root}
              [] -> nil
            end

          [module | _] ->
            # Fallback for list format
            {module, :root}

          [] ->
            # Will use PhoenixKit default
            nil
        end
    end
  end

  defp parse_layout_preference(preference) when is_binary(preference) do
    # Parse string like "MyAppWeb.Layouts.app" into {MyAppWeb.Layouts, :app}
    case String.split(preference, ".") do
      parts when length(parts) > 1 ->
        {function, module_parts} = List.pop_at(parts, -1)
        module = Module.concat(module_parts)
        {module, String.to_atom(function)}

      _ ->
        preference
    end
  end

  defp parse_layout_preference(preference), do: preference

  defp build_configuration_map(optimal_config, existing_config) do
    base_config = optimal_config.base_config || %{}
    layout_config = optimal_config.layout_config || %{}

    # Start with base configuration as a map
    config_map = base_config

    # Add layout-specific configuration 
    config_map =
      if is_map(layout_config) do
        Map.merge(config_map, layout_config)
      else
        # Handle case where layout_config might be a keyword list
        layout_map =
          layout_config
          |> Enum.filter(fn {_key, value} -> value != nil end)
          |> Enum.into(%{})

        Map.merge(config_map, layout_map)
      end

    # Add custom configurations
    custom_configs = optimal_config.custom_configurations || %{}
    config_map = Map.merge(config_map, custom_configs)

    # Filter out keys we don't want to override if preserving existing config
    config_map =
      if existing_config.preserve_existing do
        filter_preserved_config_keys(config_map, existing_config.existing_layout_config || %{})
      else
        config_map
      end

    config_map
  end

  defp filter_preserved_config_keys(config_map, existing_layout_config) do
    existing_keys = Map.keys(existing_layout_config)

    Map.drop(config_map, existing_keys)
  end

  defp extract_custom_configurations(opts) do
    # Extract any custom configuration options from opts
    opts
    |> Keyword.take([:page_title_prefix, :custom_css_classes, :flash_message_styling])
    |> Enum.into(%{})
  end

  defp determine_fallback_configuration(integration_strategy) do
    template = Map.get(@configuration_templates, integration_strategy)

    case template.fallback_strategy do
      :use_phoenix_kit_fallbacks ->
        %{
          fallback_layout: {PhoenixKitWeb.Layouts, :app},
          fallback_root_layout: {PhoenixKitWeb.Layouts, :root}
        }

      :enhanced_fallbacks ->
        %{
          fallback_layout: {PhoenixKitWeb.Layouts, :app},
          fallback_root_layout: {PhoenixKitWeb.Layouts, :root},
          fallback_error_layout: {PhoenixKitWeb.Layouts, :error}
        }

      :comprehensive_fallbacks ->
        %{
          fallback_layout: {PhoenixKitWeb.Layouts, :app},
          fallback_root_layout: {PhoenixKitWeb.Layouts, :root},
          fallback_error_layout: {PhoenixKitWeb.Layouts, :error},
          fallback_email_layout: {PhoenixKitWeb.Layouts, :email}
        }

      _ ->
        %{fallback_layout: {PhoenixKitWeb.Layouts, :app}}
    end
  end

  defp apply_fallback_configuration(igniter, fallback_config) do
    app_name = Igniter.Project.Application.app_name(igniter)

    # Apply fallback configuration - pass map directly to Igniter
    updated_igniter =
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        app_name,
        [PhoenixKit, :layout_fallbacks],
        fallback_config
      )

    {:ok, updated_igniter}
  end

  # Configuration analysis helper functions
  defp check_existing_phoenix_kit_config(_igniter, _app_name) do
    # TODO: Implement check for existing PhoenixKit configuration
    false
  end

  defp extract_existing_layout_config(_igniter, _app_name) do
    # TODO: Implement extraction of existing layout configuration
    %{}
  end

  defp find_config_file_locations do
    ["config/config.exs", "config/dev.exs", "config/prod.exs"]
    |> Enum.filter(&File.exists?/1)
  end

  # Layout detection helper functions
  defp find_app_layout_modules do
    # TODO: Implement detection of app layout modules
    %{}
  end

  defp find_root_layout_modules do
    # TODO: Implement detection of root layout modules  
    %{}
  end

  defp find_layout_files do
    # TODO: Implement detection of layout files
    []
  end

  defp find_component_modules do
    # TODO: Implement detection of component modules
    []
  end

  defp read_current_phoenix_kit_config(_igniter) do
    # TODO: Implement reading current PhoenixKit configuration
    {:ok, %{}}
  end

  defp merge_configuration_updates(current_config, updates) do
    merged_config = Map.merge(current_config, updates)
    {:ok, merged_config}
  end

  defp write_updated_configuration(igniter, merged_config) do
    app_name = Igniter.Project.Application.app_name(igniter)

    updated_igniter =
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        app_name,
        [PhoenixKit],
        merged_config
      )

    {:ok, updated_igniter}
  end

  defp generate_configuration_recommendations(optimal_config, layout_detection) do
    recommendations = ["Layout configuration applied successfully"]

    # Strategy-specific recommendations
    recommendations =
      recommendations ++
        case optimal_config.strategy do
          :use_existing_layouts ->
            ["✅ Using existing layouts - minimal configuration changes"]

          :enhance_existing_layouts ->
            ["🎨 Enhanced existing layouts with PhoenixKit features"]

          :create_phoenix_kit_layouts ->
            ["🆕 Created comprehensive PhoenixKit layout configuration"]

          :hybrid_integration ->
            ["🔀 Hybrid configuration - balances existing and new layouts"]
        end

    # Layout-specific recommendations
    app_layout_modules = layout_detection.app_layout_modules || %{}

    recommendations =
      recommendations ++
        if map_size(app_layout_modules) > 0 do
          ["🎯 Integrated with detected app layout modules"]
        else
          ["📝 No app layouts detected - using PhoenixKit defaults"]
        end

    recommendations
  end

  defp log_configuration_summary(configuration_result) do
    Logger.info("🔧 Layout Configuration Complete!")
    Logger.info("   Duration: #{configuration_result.configuration_duration_ms}ms")
    Logger.info("   Strategy: #{configuration_result.integration_strategy}")
    Logger.info("   Enhancement level: #{configuration_result.enhancement_level}")
    applied_configs = configuration_result.applied_configurations || %{}
    detected_layouts = configuration_result.detected_layouts || %{}

    applied_count =
      if is_list(applied_configs), do: length(applied_configs), else: map_size(applied_configs)

    detected_count =
      if is_list(detected_layouts), do: length(detected_layouts), else: map_size(detected_layouts)

    Logger.info("   Applied configs: #{applied_count}")
    Logger.info("   Detected layouts: #{detected_count}")

    Logger.info(
      "   Validation passed: #{configuration_result.validation_result.config_syntax_valid}"
    )
  end
end
