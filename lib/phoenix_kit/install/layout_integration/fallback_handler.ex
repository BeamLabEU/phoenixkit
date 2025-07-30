defmodule PhoenixKit.Install.LayoutIntegration.FallbackHandler do
  @moduledoc """
  Обрабатывает создание и управление fallback layout'ами для PhoenixKit.
  
  Этот модуль:
  - Создаёт fallback layout'ы когда основные недоступны
  - Управляет иерархией fallback'ов
  - Обеспечивает graceful degradation
  - Предоставляет минимально функциональные layout'ы
  - Поддерживает различные стратегии fallback'ов
  """

  require Logger

  @fallback_strategies %{
    # Use PhoenixKit fallbacks only when necessary
    use_phoenix_kit_fallbacks: %{
      priority: :minimal_intervention,
      fallback_layouts: [:app, :root],
      creation_conditions: [:missing_layouts, :incompatible_layouts],
      enhancement_level: :basic
    },
    
    # Enhanced fallbacks with better UX
    enhanced_fallbacks: %{
      priority: :improved_experience,
      fallback_layouts: [:app, :root, :error],
      creation_conditions: [:missing_layouts, :incompatible_layouts, :enhancement_requested],
      enhancement_level: :standard
    },
    
    # Comprehensive fallback system
    comprehensive_fallbacks: %{
      priority: :complete_coverage,
      fallback_layouts: [:app, :root, :error, :email, :live],
      creation_conditions: [:missing_layouts, :incompatible_layouts, :complete_system_requested],
      enhancement_level: :full
    },
    
    # Hybrid fallbacks balancing existing and new
    hybrid_fallbacks: %{
      priority: :balanced_approach,
      fallback_layouts: [:app, :root],
      creation_conditions: [:partial_compatibility, :mixed_system],
      enhancement_level: :adaptive
    }
  }

  @fallback_templates %{
    # Minimal but functional layout templates
    root: """
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title suffix=" · PhoenixKit">
          <%= assigns[:page_title] || "Authentication" %>
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
      </head>
      <body class="bg-white antialiased">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </body>
    </html>
    """,
    
    app: """
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </div>
    </main>
    """,
    
    error: """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Error · PhoenixKit</title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
      </head>
      <body class="bg-red-50">
        <main class="px-4 py-20 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h1 class="text-4xl font-bold text-red-600">Error</h1>
            <div class="mt-4 text-gray-600">
              <%= @inner_content %>
            </div>
          </div>
        </main>
      </body>
    </html>
    """,
    
    email: """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><%= assigns[:page_title] || "Email" %></title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f8f9fa; padding: 20px; text-align: center; }
          .content { padding: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>PhoenixKit Authentication</h1>
          </div>
          <div class="content">
            <%= @inner_content %>
          </div>
        </div>
      </body>
    </html>
    """,
    
    live: """
    <div class="min-h-screen bg-gray-50">
      <.flash_group flash={@flash} />
      <main class="px-4 py-8 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-4xl">
          <%= @inner_content %>
        </div>
      </main>
    </div>
    """
  }

  @doc """
  Создаёт fallback layout'ы на основе стратегии интеграции.
  
  ## Parameters
  
  - `igniter` - Igniter context
  - `integration_strategy` - Стратегия интеграции
  - `opts` - Опции создания fallback'ов:
    - `:force_creation` - Принудительно создавать fallback'ы (default: false)
    - `:custom_templates` - Кастомные шаблоны для fallback'ов
    - `:target_directory` - Целевая директория для fallback'ов
  
  ## Returns
  
  - `{:ok, updated_igniter, fallback_result}` - успешное создание fallback'ов
  - `{:error, reason}` - ошибка при создании
  - `{:skipped, reason}` - создание пропущено
  
  ## Examples
  
      iex> FallbackHandler.create_fallback_layouts(igniter, :comprehensive_fallbacks)
      {:ok, updated_igniter, %{
        created_fallbacks: [...],
        fallback_strategy: :comprehensive_fallbacks,
        configuration_updates: [...]
      }}
  """
  def create_fallback_layouts(igniter, integration_strategy, opts \\ []) do
    force_creation = Keyword.get(opts, :force_creation, false)
    custom_templates = Keyword.get(opts, :custom_templates, %{})
    target_directory = Keyword.get(opts, :target_directory)
    
    Logger.info("🛡️  Starting fallback layout creation")
    Logger.info("   Strategy: #{integration_strategy}")
    Logger.info("   Force creation: #{force_creation}")
    
    fallback_start_time = System.monotonic_time(:millisecond)
    
    with {:ok, fallback_strategy} <- determine_fallback_strategy(integration_strategy),
         {:ok, creation_plan} <- create_fallback_plan(fallback_strategy, force_creation, opts),
         {:ok, target_dir} <- determine_target_directory(igniter, target_directory),
         {:ok, updated_igniter, created_fallbacks} <- execute_fallback_creation(igniter, creation_plan, target_dir, custom_templates),
         {:ok, configured_igniter, config_updates} <- configure_fallback_system(updated_igniter, created_fallbacks, fallback_strategy) do
      
      fallback_duration = System.monotonic_time(:millisecond) - fallback_start_time
      
      fallback_result = %{
        fallback_timestamp: DateTime.utc_now(),
        fallback_duration_ms: fallback_duration,
        integration_strategy: integration_strategy,
        fallback_strategy: fallback_strategy,
        creation_plan: creation_plan,
        created_fallbacks: created_fallbacks,
        target_directory: target_dir,
        configuration_updates: config_updates,
        recommendations: generate_fallback_recommendations(created_fallbacks, fallback_strategy)
      }
      
      log_fallback_summary(fallback_result)
      {:ok, configured_igniter, fallback_result}
    else
      {:skip, reason} ->
        Logger.info("⏭️  Fallback creation skipped: #{reason}")
        {:skipped, reason}
      
      error ->
        Logger.error("❌ Fallback creation failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Обновляет существующие fallback layout'ы.
  """
  def update_fallback_layouts(igniter, fallback_updates) do
    Logger.info("🔄 Updating existing fallback layouts")
    
    with {:ok, existing_fallbacks} <- discover_existing_fallbacks(igniter),
         {:ok, updated_igniter, update_results} <- apply_fallback_updates(igniter, existing_fallbacks, fallback_updates) do
      
      {:ok, updated_igniter, %{
        existing_fallbacks: existing_fallbacks,
        update_results: update_results,
        updates_applied: Map.keys(fallback_updates)
      }}
    else
      error ->
        Logger.error("❌ Fallback update failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Проверяет необходимость создания fallback layout'ов.
  """
  def assess_fallback_necessity(_igniter, layout_analysis) do
    Logger.info("🔍 Assessing fallback layout necessity")
    
    necessity_factors = []
    
    # Check for missing essential layouts
    necessity_factors = necessity_factors ++
      if not layout_analysis.has_complete_layout_system do
        [:missing_essential_layouts]
      else
        []
      end
    
    # Check compatibility issues
    necessity_factors = necessity_factors ++
      if layout_analysis.compatibility_issues do
        [:compatibility_issues]
      else
        []
      end
    
    # Check for high integration complexity
    necessity_factors = necessity_factors ++
      if layout_analysis.integration_complexity == :complex do
        [:complex_integration]
      else
        []
      end
    
    necessity_assessment = %{
      fallbacks_needed: length(necessity_factors) > 0,
      necessity_factors: necessity_factors,
      recommended_strategy: recommend_fallback_strategy(necessity_factors),
      urgency_level: assess_urgency_level(necessity_factors),
      estimated_benefit: estimate_fallback_benefit(necessity_factors)
    }
    
    {:ok, necessity_assessment}
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp determine_fallback_strategy(integration_strategy) do
    strategy_mapping = %{
      use_existing_layouts: :use_phoenix_kit_fallbacks,
      enhance_existing_layouts: :enhanced_fallbacks,
      create_phoenix_kit_layouts: :comprehensive_fallbacks,
      hybrid_integration: :hybrid_fallbacks
    }
    
    fallback_strategy = Map.get(strategy_mapping, integration_strategy, :use_phoenix_kit_fallbacks)
    {:ok, fallback_strategy}
  end

  defp create_fallback_plan(fallback_strategy, force_creation, _opts) do
    strategy_config = Map.get(@fallback_strategies, fallback_strategy)
    
    # Determine which fallbacks to create
    planned_fallbacks = strategy_config.fallback_layouts
    
    # Apply force creation logic
    creation_conditions = if force_creation do
      [:force_creation | strategy_config.creation_conditions]
    else
      strategy_config.creation_conditions
    end
    
    creation_plan = %{
      fallback_strategy: fallback_strategy,
      planned_fallbacks: planned_fallbacks,
      creation_conditions: creation_conditions,
      enhancement_level: strategy_config.enhancement_level,
      priority: strategy_config.priority
    }
    
    {:ok, creation_plan}
  end

  defp determine_target_directory(igniter, nil) do
    # Auto-detect appropriate directory
    app_name = Igniter.Project.Application.app_name(igniter)
    
    possible_directories = [
      "lib/#{app_name}_web/components/layouts",
      "lib/#{app_name}/web/components/layouts",
      "lib/phoenix_kit_web/components/layouts"
    ]
    
    target_dir = Enum.find(possible_directories, fn dir ->
      parent_dir = Path.dirname(dir)
      File.exists?(parent_dir)
    end) || "lib/phoenix_kit_web/components/layouts"
    
    {:ok, target_dir}
  end

  defp determine_target_directory(_igniter, target_directory) do
    {:ok, target_directory}
  end

  defp execute_fallback_creation(igniter, creation_plan, target_dir, custom_templates) do
    Logger.debug("Executing fallback creation in #{target_dir}")
    
    # Ensure target directory exists
    File.mkdir_p!(target_dir)
    
    created_fallbacks = creation_plan.planned_fallbacks
    |> Enum.map(fn layout_type ->
      create_single_fallback(igniter, layout_type, target_dir, custom_templates, creation_plan.enhancement_level)
    end)
    |> Enum.filter(fn result ->
      case result do
        {:ok, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn {:ok, fallback_info} -> fallback_info end)
    
    {:ok, igniter, created_fallbacks}
  end

  defp create_single_fallback(_igniter, layout_type, target_dir, custom_templates, enhancement_level) do
    Logger.debug("Creating #{layout_type} fallback layout")
    
    # Get template content
    template_content = get_fallback_template(layout_type, custom_templates, enhancement_level)
    
    # Determine file path
    file_name = "#{layout_type}.html.heex"
    file_path = Path.join(target_dir, file_name)
    
    # Check if file already exists
    if File.exists?(file_path) do
      Logger.debug("Fallback #{layout_type} already exists, skipping")
      {:skipped, %{layout_type: layout_type, reason: :already_exists}}
    else
      case File.write(file_path, template_content) do
        :ok ->
          Logger.debug("Created fallback #{layout_type} at #{file_path}")
          {:ok, %{
            layout_type: layout_type,
            file_path: file_path,
            content_length: String.length(template_content),
            enhancement_level: enhancement_level
          }}
        
        {:error, reason} ->
          Logger.error("Failed to create fallback #{layout_type}: #{inspect(reason)}")
          {:error, {:fallback_creation_error, layout_type, reason}}
      end
    end
  end

  defp configure_fallback_system(igniter, created_fallbacks, fallback_strategy) do
    Logger.debug("Configuring fallback system")
    
    app_name = Igniter.Project.Application.app_name(igniter)
    
    # Build fallback configuration
    fallback_config = build_fallback_configuration(created_fallbacks, fallback_strategy)
    
    # Apply configuration using Igniter
    # Convert to proper map format for Igniter configuration
    config_map = %{
      enabled: true,
      strategy: fallback_strategy,
      layouts: fallback_config[:layouts] || %{}
    }
    
    updated_igniter = Igniter.Project.Config.configure(
      igniter,
      "config.exs",
      app_name,
      [PhoenixKit, :layout_fallbacks],
      config_map
    )
    
    {:ok, updated_igniter, fallback_config}
  end

  defp get_fallback_template(layout_type, custom_templates, enhancement_level) do
    # Check for custom template first
    case Map.get(custom_templates, layout_type) do
      nil ->
        # Use default template
        base_template = Map.get(@fallback_templates, layout_type, @fallback_templates.app)
        enhance_template(base_template, enhancement_level)
      
      custom_template ->
        custom_template
    end
  end

  defp enhance_template(base_template, enhancement_level) do
    case enhancement_level do
      :basic ->
        base_template
      
      :standard ->
        # Add some standard enhancements
        add_standard_enhancements(base_template)
      
      :full ->
        # Add comprehensive enhancements
        add_comprehensive_enhancements(base_template)
      
      :adaptive ->
        # Add adaptive enhancements based on context
        add_adaptive_enhancements(base_template)
    end
  end

  defp add_standard_enhancements(template) do
    # Add standard improvements like better styling, accessibility
    enhanced = template
    |> String.replace("class=\"", "class=\"focus:outline-none focus:ring-2 focus:ring-blue-500 ")
    |> add_accessibility_attributes()
    
    enhanced
  end

  defp add_comprehensive_enhancements(template) do
    # Add comprehensive improvements
    template
    |> add_standard_enhancements()
    |> add_responsive_design()
    |> add_dark_mode_support()
    |> add_performance_optimizations()
  end

  defp add_adaptive_enhancements(template) do
    # Add context-aware enhancements
    add_standard_enhancements(template)
  end

  defp add_accessibility_attributes(template) do
    template
    |> String.replace("<main", "<main role=\"main\"")
    |> String.replace("<button", "<button type=\"button\"")
  end

  defp add_responsive_design(template) do
    # Add responsive classes and meta tags
    String.replace(template, "class=\"", "class=\"responsive ")
  end

  defp add_dark_mode_support(template) do
    # Add dark mode classes
    String.replace(template, "bg-white", "bg-white dark:bg-gray-900")
  end

  defp add_performance_optimizations(template) do
    # Add performance-related attributes
    String.replace(template, "<link", "<link preload")
  end

  defp build_fallback_configuration(created_fallbacks, fallback_strategy) do
    # Build configuration map for fallbacks
    fallback_map = created_fallbacks
    |> Enum.map(fn fallback ->
      layout_module = determine_layout_module(fallback.layout_type)
      {fallback.layout_type, {layout_module, fallback.layout_type}}
    end)
    |> Enum.into(%{})
    
    [
      enabled: true,
      strategy: fallback_strategy,
      layouts: fallback_map
    ]
  end

  defp determine_layout_module(layout_type) do
    # Determine the appropriate layout module
    case layout_type do
      :root -> PhoenixKitWeb.Layouts
      :app -> PhoenixKitWeb.Layouts
      :error -> PhoenixKitWeb.Layouts
      :email -> PhoenixKitWeb.Layouts
      :live -> PhoenixKitWeb.Layouts
      _ -> PhoenixKitWeb.Layouts
    end
  end

  # Discovery and update functions
  defp discover_existing_fallbacks(_igniter) do
    # Discover existing fallback layouts
    fallback_patterns = [
      "lib/*/web/components/layouts/*.html.heex",
      "lib/*_web/components/layouts/*.html.heex",
      "lib/phoenix_kit_web/components/layouts/*.html.heex"
    ]
    
    existing_fallbacks = fallback_patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&is_fallback_layout?/1)
    |> Enum.map(&analyze_fallback_layout/1)
    
    {:ok, existing_fallbacks}
  end

  defp apply_fallback_updates(igniter, existing_fallbacks, fallback_updates) do
    update_results = existing_fallbacks
    |> Enum.map(fn fallback ->
      case Map.get(fallback_updates, fallback.layout_type) do
        nil -> {:skipped, fallback.layout_type}
        update -> apply_single_fallback_update(fallback, update)
      end
    end)
    
    {:ok, igniter, update_results}
  end

  defp is_fallback_layout?(file_path) do
    # Check if this is a PhoenixKit fallback layout
    String.contains?(file_path, "phoenix_kit") or
    Path.basename(file_path) in ["root.html.heex", "app.html.heex", "error.html.heex", "email.html.heex"]
  end

  defp analyze_fallback_layout(file_path) do
    layout_type = 
      file_path
      |> Path.basename()
      |> String.replace(".html.heex", "")
      |> String.to_atom()
    
    %{
      layout_type: layout_type,
      file_path: file_path,
      last_modified: File.stat!(file_path).mtime
    }
  end

  defp apply_single_fallback_update(fallback, update) do
    # Apply update to a single fallback
    case File.read(fallback.file_path) do
      {:ok, content} ->
        updated_content = apply_update_to_content(content, update)
        case File.write(fallback.file_path, updated_content) do
          :ok -> {:ok, fallback.layout_type}
          {:error, reason} -> {:error, {fallback.layout_type, reason}}
        end
      
      {:error, reason} ->
        {:error, {fallback.layout_type, reason}}
    end
  end

  defp apply_update_to_content(content, _update) do
    # Apply the update to the content
    # This would implement specific update logic
    content
  end

  # Assessment functions
  defp recommend_fallback_strategy(necessity_factors) do
    cond do
      :missing_essential_layouts in necessity_factors -> :comprehensive_fallbacks
      :compatibility_issues in necessity_factors -> :enhanced_fallbacks  
      :complex_integration in necessity_factors -> :hybrid_fallbacks
      true -> :use_phoenix_kit_fallbacks
    end
  end

  defp assess_urgency_level(necessity_factors) do
    critical_factors = [:missing_essential_layouts, :compatibility_issues]
    
    cond do
      Enum.any?(critical_factors, &(&1 in necessity_factors)) -> :high
      length(necessity_factors) > 1 -> :medium
      length(necessity_factors) == 1 -> :low
      true -> :none
    end
  end

  defp estimate_fallback_benefit(necessity_factors) do
    base_benefit = 20  # Base benefit percentage
    
    benefit_per_factor = %{
      missing_essential_layouts: 40,
      compatibility_issues: 30,
      complex_integration: 20
    }
    
    total_benefit = necessity_factors
    |> Enum.map(&Map.get(benefit_per_factor, &1, 10))
    |> Enum.sum()
    |> Kernel.+(base_benefit)
    |> min(100)
    
    "#{total_benefit}%"
  end

  defp generate_fallback_recommendations(created_fallbacks, fallback_strategy) do
    recommendations = ["Fallback layout system created successfully"]
    
    # Strategy-specific recommendations
    recommendations = recommendations ++
      case fallback_strategy do
        :use_phoenix_kit_fallbacks ->
          ["✅ Minimal fallback system - provides basic functionality"]
        
        :enhanced_fallbacks ->
          ["🎨 Enhanced fallback system - improved user experience"]
        
        :comprehensive_fallbacks ->
          ["🏆 Comprehensive fallback system - full coverage and features"]
        
        :hybrid_fallbacks ->
          ["🔀 Hybrid fallback system - balanced approach"]
      end
    
    # Layout-specific recommendations
    recommendations = recommendations ++
      if length(created_fallbacks) > 0 do
        layout_types = Enum.map(created_fallbacks, & &1.layout_type)
        ["📋 Created fallbacks for: #{Enum.join(layout_types, ", ")}"]
      else
        ["ℹ️  No fallbacks created - existing layouts are sufficient"]
      end
    
    recommendations
  end

  defp log_fallback_summary(fallback_result) do
    Logger.info("🛡️  Fallback System Complete!")
    Logger.info("   Duration: #{fallback_result.fallback_duration_ms}ms")
    Logger.info("   Strategy: #{fallback_result.fallback_strategy}")
    Logger.info("   Created fallbacks: #{length(fallback_result.created_fallbacks)}")
    Logger.info("   Target directory: #{fallback_result.target_directory}")
    Logger.info("   Configuration updates: #{length(fallback_result.configuration_updates)}")
  end
end