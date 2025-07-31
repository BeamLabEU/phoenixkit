defmodule PhoenixKit.Install.LayoutIntegration.LayoutDetector do
  @moduledoc """
  Обнаруживает и анализирует существующие layout'ы в Phoenix приложении.

  Этот модуль:
  - Сканирует файловую структуру для поиска layout файлов
  - Анализирует содержимое layout'ов для определения их структуры
  - Определяет Phoenix версию и используемые технологии
  - Выявляет совместимость с PhoenixKit компонентами
  - Предоставляет рекомендации по интеграции
  """

  require Logger

  # Оптимизация: кэш для результатов анализа layout'ов
  @table_name :phoenix_kit_layout_cache

  def start_cache do
    :ets.new(@table_name, [:set, :named_table, :public])
  rescue
    ArgumentError -> :already_exists
  end

  defp get_cached_layout_analysis(file_path) do
    start_cache()

    case :ets.lookup(@table_name, file_path) do
      [{^file_path, result}] -> {:ok, result}
      [] -> :not_found
    end
  end

  defp cache_layout_analysis(file_path, result) do
    start_cache()
    :ets.insert(@table_name, {file_path, result})
    result
  end

  @layout_directories [
    "lib/*/web/components/layouts/",
    "lib/*_web/components/layouts/",
    # Legacy Phoenix
    "lib/*/web/templates/layout/",
    # Legacy Phoenix
    "lib/*_web/templates/layout/"
  ]

  @layout_file_patterns [
    "*.html.heex",
    "*.html.eex",
    "*.html.leex"
  ]

  @essential_layouts %{
    root: ["root.html.heex", "root.html.eex"],
    app: ["app.html.heex", "app.html.eex"],
    live: ["live.html.heex", "live.html.eex"],
    email: ["email.html.heex", "email.html.eex"]
  }

  @layout_features_patterns %{
    # Phoenix LiveView patterns
    liveview: [
      {~r/<\.live_title/, :live_title_component},
      {~r/<\.flash/, :flash_component},
      {~r/<\.live_component/, :live_component_usage},
      {~r/phx-/, :liveview_attributes},
      {~r/@conn/, :conn_assigns}
    ],

    # CSS Framework patterns
    css_frameworks: [
      {~r/tailwind|tw-/, :tailwind},
      {~r/bootstrap|bs-/, :bootstrap},
      {~r/bulma/, :bulma},
      {~r/foundation/, :foundation}
    ],

    # Component system patterns
    components: [
      {~r/<\.header/, :header_component},
      {~r/<\.navbar/, :navbar_component},
      {~r/<\.sidebar/, :sidebar_component},
      {~r/<\.footer/, :footer_component},
      {~r/Components\./, :component_module_usage}
    ],

    # Authentication patterns
    auth_integration: [
      {~r/@current_user/, :current_user_usage},
      {~r/user_signed_in/, :auth_helper_usage},
      {~r/log_out/, :logout_links},
      {~r/sign_in/, :signin_links},
      {~r/register/, :register_links}
    ],

    # Flash message patterns
    flash_messages: [
      {~r/flash\[:info\]/, :flash_info_usage},
      {~r/flash\[:error\]/, :flash_error_usage},
      {~r/flash\[:notice\]/, :flash_notice_usage},
      {~r/put_flash/, :flash_usage}
    ]
  }

  @doc """
  Обнаруживает и анализирует все существующие layout'ы в Phoenix приложении.

  ## Parameters

  - `igniter` - Igniter context (для будущих расширений)

  ## Returns

  - `{:ok, layout_analysis}` - детальный анализ найденных layout'ов
  - `{:error, reason}` - ошибка при обнаружении

  ## Examples

      iex> LayoutDetector.detect_existing_layouts(igniter)
      {:ok, %{
        detected_layouts: [...],
        layout_structure: %{...},
        compatibility_analysis: %{...},
        recommendations: [...]
      }}
  """
  def detect_existing_layouts(_igniter) do
    Logger.info("🔍 Starting comprehensive layout detection")

    detection_start_time = System.monotonic_time(:millisecond)

    with {:ok, layout_files} <- discover_layout_files(),
         {:ok, layout_analysis} <- analyze_layout_files(layout_files),
         {:ok, structure_analysis} <- analyze_layout_structure(layout_files),
         {:ok, feature_analysis} <- analyze_layout_features(layout_files),
         {:ok, compatibility_analysis} <-
           assess_phoenix_kit_compatibility(layout_analysis, feature_analysis) do
      detection_duration = System.monotonic_time(:millisecond) - detection_start_time

      comprehensive_analysis = %{
        detection_timestamp: DateTime.utc_now(),
        detection_duration_ms: detection_duration,
        detected_layouts: layout_files,
        layout_analysis: layout_analysis,
        structure_analysis: structure_analysis,
        feature_analysis: feature_analysis,
        compatibility_analysis: compatibility_analysis,
        has_complete_layout_system: has_complete_layout_system?(structure_analysis),
        has_partial_layouts: has_partial_layouts?(structure_analysis),
        has_no_layouts: has_no_layouts?(layout_files),
        compatibility_issues: has_compatibility_issues?(compatibility_analysis),
        integration_complexity: assess_integration_complexity(layout_analysis, feature_analysis),
        recommendations:
          generate_detection_recommendations(
            layout_analysis,
            structure_analysis,
            compatibility_analysis
          )
      }

      log_detection_summary(comprehensive_analysis)
      {:ok, comprehensive_analysis}
    else
      error ->
        Logger.error("❌ Layout detection failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Анализирует конкретный layout файл для определения его особенностей.
  Оптимизированная версия с кэшированием content и результатов анализа.
  """
  def analyze_specific_layout(file_path) do
    # Оптимизация: проверяем кэш сначала
    case get_cached_layout_analysis(file_path) do
      {:ok, cached_result} ->
        Logger.debug("Using cached layout analysis for #{file_path}")
        {:ok, cached_result}

      :not_found ->
        case File.read(file_path) do
          {:ok, content} ->
            # Оптимизация: передаем content во все функции анализа
            # чтобы избежать повторного чтения файла
            analysis = %{
              file_path: file_path,
              file_type: determine_file_type(file_path),
              layout_type: determine_layout_type(file_path),
              content_analysis: analyze_layout_content(content),
              features: extract_layout_features(content),
              dependencies: extract_layout_dependencies(content),
              phoenix_version: detect_phoenix_version_from_layout(content)
            }

            cache_layout_analysis(file_path, analysis)
            {:ok, analysis}

          {:error, reason} ->
            {:error, {:file_read_error, file_path, reason}}
        end
    end
  end

  @doc """
  Определяет оптимальную стратегию интеграции на основе анализа layout'ов.
  """
  def suggest_integration_strategy(layout_analysis) do
    cond do
      layout_analysis.has_complete_layout_system and
          layout_analysis.compatibility_analysis.overall_compatibility_score > 80 ->
        {:use_existing, "Existing layouts are comprehensive and highly compatible"}

      layout_analysis.has_partial_layouts and
          layout_analysis.compatibility_analysis.overall_compatibility_score > 60 ->
        {:enhance_existing, "Existing layouts can be enhanced for full compatibility"}

      layout_analysis.has_no_layouts or
          layout_analysis.compatibility_analysis.overall_compatibility_score < 40 ->
        {:create_new, "Create new PhoenixKit-optimized layouts"}

      true ->
        {:hybrid_approach, "Combine existing layouts with PhoenixKit enhancements"}
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp discover_layout_files do
    Logger.debug("Discovering layout files in Phoenix application...")

    try do
      layout_files =
        @layout_directories
        |> Enum.flat_map(fn dir_pattern ->
          @layout_file_patterns
          |> Enum.flat_map(fn file_pattern ->
            Path.wildcard("#{dir_pattern}#{file_pattern}")
          end)
        end)
        |> Enum.uniq()
        |> Enum.filter(&File.exists?/1)
        |> Enum.sort()

      Logger.debug("Found #{length(layout_files)} layout files")
      {:ok, layout_files}
    rescue
      error ->
        {:error, {:file_discovery_error, error}}
    end
  end

  defp analyze_layout_files(layout_files) do
    Logger.debug("Analyzing #{length(layout_files)} layout files...")

    # Оптимизация: увеличиваем параллелизм для больших проектов
    max_concurrency = min(System.schedulers_online() * 2, 8)

    layout_analyses =
      layout_files
      |> Task.async_stream(
        fn file_path ->
          case analyze_specific_layout(file_path) do
            {:ok, analysis} ->
              {file_path, analysis}

            {:error, reason} ->
              Logger.warning("Could not analyze #{file_path}: #{inspect(reason)}")
              {file_path, %{error: reason}}
          end
        end,
        max_concurrency: max_concurrency,
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, result} -> result end)
      |> Enum.into(%{})

    {:ok, layout_analyses}
  end

  defp analyze_layout_structure(layout_files) do
    Logger.debug("Analyzing layout structure...")

    structure_analysis = %{
      total_layouts: length(layout_files),
      has_root_layout: has_layout_type?(layout_files, :root),
      has_app_layout: has_layout_type?(layout_files, :app),
      has_live_layout: has_layout_type?(layout_files, :live),
      has_email_layout: has_layout_type?(layout_files, :email),
      layout_distribution: analyze_layout_distribution(layout_files),
      file_types: analyze_file_types(layout_files),
      directory_structure: analyze_directory_structure(layout_files)
    }

    {:ok, structure_analysis}
  end

  defp analyze_layout_features(layout_files) do
    Logger.debug("Analyzing layout features...")

    # Оптимизация: пакетное чтение файлов для уменьшения I/O операций
    feature_analysis =
      layout_files
      # Обрабатываем файлы пакетами
      |> Enum.chunk_every(4)
      |> Task.async_stream(
        fn file_batch ->
          Enum.map(file_batch, fn file_path ->
            case File.read(file_path) do
              {:ok, content} ->
                {file_path, extract_all_features(content)}

              {:error, _} ->
                {file_path, %{}}
            end
          end)
        end,
        max_concurrency: 2,
        timeout: 30_000
      )
      |> Enum.flat_map(fn {:ok, batch_results} -> batch_results end)
      |> Enum.into(%{})

    aggregated_features = aggregate_features_across_layouts(feature_analysis)

    {:ok,
     %{
       per_layout_features: feature_analysis,
       aggregated_features: aggregated_features,
       technology_stack: determine_technology_stack(aggregated_features),
       authentication_integration: assess_auth_integration(aggregated_features)
     }}
  end

  defp assess_phoenix_kit_compatibility(_layout_analysis, feature_analysis) do
    Logger.debug("Assessing PhoenixKit compatibility...")

    compatibility_checks = %{
      phoenix_version_compatible: check_phoenix_version_compatibility(feature_analysis),
      liveview_compatible: check_liveview_compatibility(feature_analysis),
      component_system_compatible: check_component_compatibility(feature_analysis),
      css_framework_compatible: check_css_framework_compatibility(feature_analysis),
      flash_system_compatible: check_flash_system_compatibility(feature_analysis),
      auth_integration_ready: check_auth_integration_readiness(feature_analysis)
    }

    overall_score = calculate_compatibility_score(compatibility_checks)
    blocking_issues = identify_blocking_issues(compatibility_checks)

    {:ok,
     %{
       individual_checks: compatibility_checks,
       overall_compatibility_score: overall_score,
       blocking_issues: blocking_issues,
       enhancement_opportunities: identify_enhancement_opportunities(compatibility_checks),
       integration_recommendations: generate_compatibility_recommendations(compatibility_checks)
     }}
  end

  defp determine_file_type(file_path) do
    cond do
      String.ends_with?(file_path, ".html.heex") -> :heex
      String.ends_with?(file_path, ".html.eex") -> :eex
      String.ends_with?(file_path, ".html.leex") -> :leex
      true -> :unknown
    end
  end

  defp determine_layout_type(file_path) do
    file_name = Path.basename(file_path, Path.extname(file_path))

    cond do
      String.contains?(file_name, "root") -> :root
      String.contains?(file_name, "app") -> :app
      String.contains?(file_name, "live") -> :live
      String.contains?(file_name, "email") -> :email
      true -> :custom
    end
  end

  defp analyze_layout_content(content) do
    %{
      line_count: length(String.split(content, "\n")),
      has_doctype: String.contains?(content, "<!DOCTYPE"),
      has_html_tag: String.contains?(content, "<html"),
      has_head_section: String.contains?(content, "<head>"),
      has_body_section: String.contains?(content, "<body>"),
      has_main_content:
        String.contains?(content, "@inner_content") or String.contains?(content, "render"),
      uses_assigns: String.contains?(content, "@"),
      uses_components: String.contains?(content, "<."),
      complexity_score: calculate_content_complexity(content)
    }
  end

  defp extract_layout_features(content) do
    @layout_features_patterns
    |> Enum.map(fn {category, patterns} ->
      found_features =
        patterns
        |> Enum.map(fn {regex, feature_name} ->
          if Regex.match?(regex, content) do
            {feature_name, true}
          else
            {feature_name, false}
          end
        end)
        |> Enum.into(%{})

      {category, found_features}
    end)
    |> Enum.into(%{})
  end

  defp extract_layout_dependencies(content) do
    # Извлекаем зависимости из layout'а (imports, aliases, etc.)
    dependencies = []

    # Phoenix dependencies
    dependencies =
      if String.contains?(content, "Phoenix.") do
        dependencies ++ [:phoenix]
      else
        dependencies
      end

    # LiveView dependencies
    dependencies =
      if String.contains?(content, "live_") or String.contains?(content, "phx-") do
        dependencies ++ [:phoenix_live_view]
      else
        dependencies
      end

    # Component dependencies
    dependencies =
      if String.match?(content, ~r/<\.[a-z]/) do
        dependencies ++ [:phoenix_components]
      else
        dependencies
      end

    Enum.uniq(dependencies)
  end

  defp detect_phoenix_version_from_layout(content) do
    cond do
      String.contains?(content, "live_title") -> "1.7+"
      String.contains?(content, ".heex") -> "1.6+"
      String.contains?(content, "live_component") -> "1.5+"
      String.contains?(content, "@conn") -> "1.0-1.4"
      true -> :unknown
    end
  end

  defp has_layout_type?(layout_files, layout_type) do
    essential_files = Map.get(@essential_layouts, layout_type, [])

    Enum.any?(layout_files, fn file_path ->
      file_name = Path.basename(file_path)

      Enum.any?(essential_files, fn essential_file ->
        String.contains?(file_name, String.replace(essential_file, ~r/\.\w+$/, ""))
      end)
    end)
  end

  defp analyze_layout_distribution(layout_files) do
    layout_files
    |> Enum.map(&determine_layout_type/1)
    |> Enum.frequencies()
  end

  defp analyze_file_types(layout_files) do
    layout_files
    |> Enum.map(&determine_file_type/1)
    |> Enum.frequencies()
  end

  defp analyze_directory_structure(layout_files) do
    layout_files
    |> Enum.map(&Path.dirname/1)
    |> Enum.frequencies()
  end

  defp extract_all_features(content) do
    @layout_features_patterns
    |> Enum.map(fn {category, patterns} ->
      features =
        patterns
        |> Enum.filter(fn {regex, _feature_name} ->
          Regex.match?(regex, content)
        end)
        |> Enum.map(fn {_regex, feature_name} -> feature_name end)

      {category, features}
    end)
    |> Enum.into(%{})
  end

  defp aggregate_features_across_layouts(feature_analysis) do
    feature_analysis
    |> Enum.reduce(%{}, fn {_file_path, features}, acc ->
      Map.merge(acc, features, fn _key, acc_features, file_features ->
        Enum.uniq(acc_features ++ file_features)
      end)
    end)
  end

  defp determine_technology_stack(aggregated_features) do
    %{
      phoenix_version: detect_phoenix_version_from_features(aggregated_features),
      uses_liveview: length(Map.get(aggregated_features, :liveview, [])) > 0,
      css_framework: detect_primary_css_framework(aggregated_features),
      component_system: detect_component_system(aggregated_features),
      template_engine: detect_template_engine(aggregated_features)
    }
  end

  defp assess_auth_integration(aggregated_features) do
    auth_features = Map.get(aggregated_features, :auth_integration, [])

    %{
      has_existing_auth: length(auth_features) > 0,
      auth_features: auth_features,
      integration_complexity: assess_auth_integration_complexity(auth_features)
    }
  end

  # Compatibility check functions
  defp check_phoenix_version_compatibility(feature_analysis) do
    # PhoenixKit требует Phoenix 1.6+
    tech_stack = feature_analysis.technology_stack

    case tech_stack.phoenix_version do
      version when version >= "1.6" -> true
      # Assume compatibility if unknown
      :unknown -> true
      _ -> false
    end
  end

  defp check_liveview_compatibility(feature_analysis) do
    # PhoenixKit оптимизирован для LiveView
    feature_analysis.technology_stack.uses_liveview
  end

  defp check_component_compatibility(feature_analysis) do
    # Проверяем совместимость component системы
    components = Map.get(feature_analysis.aggregated_features, :components, [])
    length(components) > 0
  end

  defp check_css_framework_compatibility(_feature_analysis) do
    # PhoenixKit работает с любыми CSS фреймворками
    true
  end

  defp check_flash_system_compatibility(feature_analysis) do
    # Проверяем совместимость flash message системы
    flash_features = Map.get(feature_analysis.aggregated_features, :flash_messages, [])
    length(flash_features) > 0
  end

  defp check_auth_integration_readiness(feature_analysis) do
    # Проверяем готовность к интеграции аутентификации
    auth_integration = feature_analysis.authentication_integration
    auth_integration.integration_complexity in [:low, :medium]
  end

  defp calculate_compatibility_score(compatibility_checks) do
    passed_checks = compatibility_checks |> Map.values() |> Enum.count(& &1)
    total_checks = map_size(compatibility_checks)

    (passed_checks / total_checks * 100) |> round()
  end

  defp identify_blocking_issues(compatibility_checks) do
    compatibility_checks
    |> Enum.filter(fn {_check, passed} -> not passed end)
    |> Enum.map(fn {check, _} -> "#{check} incompatibility" end)
  end

  defp identify_enhancement_opportunities(_compatibility_checks) do
    # TODO: Implement enhancement opportunity identification
    []
  end

  defp generate_compatibility_recommendations(compatibility_checks) do
    compatibility_checks
    |> Enum.flat_map(fn {check, passed} ->
      if not passed do
        case check do
          :phoenix_version_compatible ->
            ["📈 Consider upgrading to Phoenix 1.6+ for full PhoenixKit compatibility"]

          :liveview_compatible ->
            ["⚡ Add Phoenix LiveView for enhanced PhoenixKit features"]

          :component_system_compatible ->
            ["🧩 Implement Phoenix component system for better integration"]

          _ ->
            ["🔧 Address #{check} for improved PhoenixKit integration"]
        end
      else
        []
      end
    end)
  end

  # Assessment helper functions
  defp has_complete_layout_system?(structure_analysis) do
    structure_analysis.has_root_layout and structure_analysis.has_app_layout
  end

  defp has_partial_layouts?(structure_analysis) do
    structure_analysis.total_layouts > 0 and not has_complete_layout_system?(structure_analysis)
  end

  defp has_no_layouts?(layout_files) do
    length(layout_files) == 0
  end

  defp has_compatibility_issues?(compatibility_analysis) do
    compatibility_analysis.overall_compatibility_score < 70
  end

  defp assess_integration_complexity(layout_analysis, feature_analysis) do
    complexity_factors = []

    # Layout structure complexity
    layout_count = map_size(layout_analysis)

    complexity_factors =
      complexity_factors ++
        if layout_count > 5, do: [:many_layouts], else: []

    # Technology stack complexity
    tech_stack = feature_analysis.technology_stack

    complexity_factors =
      complexity_factors ++
        if not tech_stack.uses_liveview, do: [:no_liveview], else: []

    # Feature analysis complexity
    auth_integration = feature_analysis.authentication_integration

    complexity_factors =
      complexity_factors ++
        if auth_integration.has_existing_auth, do: [:existing_auth], else: []

    case length(complexity_factors) do
      0 -> :simple
      count when count <= 2 -> :moderate
      _ -> :complex
    end
  end

  defp generate_detection_recommendations(
         _layout_analysis,
         structure_analysis,
         compatibility_analysis
       ) do
    recommendations = ["Layout detection completed successfully"]

    # Structure recommendations
    recommendations =
      recommendations ++
        if structure_analysis.has_root_layout and structure_analysis.has_app_layout do
          ["✅ Complete layout structure detected - ideal for PhoenixKit integration"]
        else
          ["📝 Partial layout structure - enhancement opportunities available"]
        end

    # Compatibility recommendations
    recommendations =
      recommendations ++
        if compatibility_analysis.overall_compatibility_score > 80 do
          ["🎯 High compatibility score - seamless integration expected"]
        else
          ["⚠️  Some compatibility issues found - review recommendations"]
        end

    recommendations ++ compatibility_analysis.integration_recommendations
  end

  # Helper functions for feature detection
  defp detect_phoenix_version_from_features(aggregated_features) do
    liveview_features = Map.get(aggregated_features, :liveview, [])

    cond do
      :live_title_component in liveview_features -> "1.7+"
      :live_component_usage in liveview_features -> "1.5+"
      :liveview_attributes in liveview_features -> "1.5+"
      true -> :unknown
    end
  end

  defp detect_primary_css_framework(aggregated_features) do
    css_features = Map.get(aggregated_features, :css_frameworks, [])

    cond do
      :tailwind in css_features -> :tailwind
      :bootstrap in css_features -> :bootstrap
      :bulma in css_features -> :bulma
      :foundation in css_features -> :foundation
      true -> :none
    end
  end

  defp detect_component_system(aggregated_features) do
    component_features = Map.get(aggregated_features, :components, [])

    cond do
      :header_component in component_features -> :phoenix_components
      :component_module_usage in component_features -> :custom_components
      length(component_features) > 0 -> :basic_components
      true -> :none
    end
  end

  defp detect_template_engine(_aggregated_features) do
    # Можно определить из анализа файлов
    # Default assumption for modern Phoenix
    :heex
  end

  defp assess_auth_integration_complexity(auth_features) do
    case length(auth_features) do
      0 -> :none
      count when count <= 2 -> :low
      count when count <= 4 -> :medium
      _ -> :high
    end
  end

  defp calculate_content_complexity(content) do
    # Простая оценка сложности на основе длины и количества элементов
    line_count = length(String.split(content, "\n"))
    component_count = length(Regex.scan(~r/<\./, content))
    assign_count = length(Regex.scan(~r/@\w+/, content))

    base_score = div(line_count, 5)
    component_score = component_count * 2
    assign_score = assign_count

    base_score + component_score + assign_score
  end

  defp log_detection_summary(analysis) do
    Logger.info("🎨 Layout Detection Summary:")
    Logger.info("   Duration: #{analysis.detection_duration_ms}ms")
    Logger.info("   Detected layouts: #{length(analysis.detected_layouts)}")
    Logger.info("   Has complete system: #{analysis.has_complete_layout_system}")
    Logger.info("   Has partial layouts: #{analysis.has_partial_layouts}")
    Logger.info("   Integration complexity: #{analysis.integration_complexity}")

    Logger.info(
      "   Compatibility score: #{analysis.compatibility_analysis.overall_compatibility_score}%"
    )

    if analysis.compatibility_issues do
      Logger.warning("⚠️  Some compatibility issues detected - review recommendations")
    end
  end
end
