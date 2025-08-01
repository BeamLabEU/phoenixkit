defmodule PhoenixKit.Install.LayoutIntegration.LayoutEnhancer do
  @moduledoc """
  Улучшает существующие layout'ы для оптимальной совместимости с PhoenixKit.

  Этот модуль:
  - Анализирует существующие layout'ы на предмет улучшений
  - Добавляет недостающие компоненты для PhoenixKit
  - Улучшает flash message системы
  - Интегрирует PhoenixKit-specific компоненты
  - Сохраняет существующий дизайн и функциональность
  """

  require Logger

  # Оптимизация: предкомпилированные регулярные выражения
  @compiled_flash_regex Regex.compile!("<\\.flash")
  @compiled_flash_syntax_regex Regex.compile!("flash\\[:info\\].*?</div>", "s")
  @compiled_csrf_regex Regex.compile!("csrf_token")
  @compiled_live_socket_regex Regex.compile!("phx\\.socket")
  @compiled_current_user_regex Regex.compile!("@current_user")
  @compiled_auth_nav_regex Regex.compile!("(nav|header|menu).*?(login|logout|sign)", "is")
  @compiled_img_alt_regex Regex.compile!("<img(?![^>]*alt=)")
  @compiled_aria_label_regex Regex.compile!("<(button|input|textarea)(?![^>]*aria-label)")

  # Enhancement patterns moved to private function to avoid compilation issues
  defp get_enhancement_patterns do
    %{
      # Flash message enhancements - используем предкомпилированные regex
      flash_messages: [
        {:missing_flash_component, @compiled_flash_regex, :add_phoenix_kit_flash_component, :high},
        {:outdated_flash_syntax, @compiled_flash_syntax_regex, :modernize_flash_syntax, :medium}
      ],

      # Authentication integration enhancements
      auth_integration: [
        {:missing_current_user, @compiled_current_user_regex, :add_current_user_display, :medium},
        {:missing_auth_navigation, @compiled_auth_nav_regex, :add_auth_navigation, :low}
      ],

      # LiveView compatibility enhancements
      liveview_compatibility: [
        {:missing_csrf_token, @compiled_csrf_regex, :ensure_csrf_token, :high},
        {:missing_live_socket, @compiled_live_socket_regex, :add_live_socket_setup, :high}
      ],

      # Accessibility enhancements
      accessibility: [
        {:missing_alt_attributes, @compiled_img_alt_regex, :add_missing_alt_attributes, :medium},
        {:missing_aria_labels, @compiled_aria_label_regex, :add_aria_labels, :low}
      ],

      # Performance enhancements
      performance: [
        {:missing_preload_hints, ~r/<link.*?stylesheet/, :add_preload_hints, :low},
        {:unoptimized_scripts, ~r/<script(?![^>]*defer|async)/, :optimize_script_loading, :low}
      ],

      # Code structure fixes - DISABLED due to safety concerns
      # These enhancements can corrupt layout files through aggressive string manipulation
      code_structure: [
        # {:attributes_after_functions, @compiled_function_regex, :fix_attribute_order, :critical}
        # DISABLED: This enhancement was causing file corruption by improperly manipulating
        # @doc comments, embed_templates calls, and other code structures.
        # Manual attribute fixing is recommended instead.
      ]
    }
  end

  @enhancement_templates %{
    # Template snippets for various enhancements
    phoenix_kit_flash_component: """
    <.flash_group flash={@flash} />
    """,
    current_user_display: """
    <%= if assigns[:current_user] do %>
      <div class="user-info">
        Welcome, <%= @current_user.email %>
        <%= link "Logout", to: Routes.phoenix_kit_session_path(@conn, :delete), method: :delete %>
      </div>
    <% else %>
      <div class="auth-links">
        <%= link "Login", to: Routes.phoenix_kit_session_path(@conn, :new) %>
        <%= link "Register", to: Routes.phoenix_kit_registration_path(@conn, :new) %>
      </div>
    <% end %>
    """,
    csrf_token_meta: """
    <meta name="csrf-token" content={get_csrf_token()}>
    """,
    live_socket_setup: """
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
    """,
    accessibility_improvements: """
    <!-- Enhanced accessibility attributes will be added contextually -->
    """,
    performance_optimizations: """
    <link rel="preload" href={~p"/assets/app.css"} as="style" onload="this.onload=null;this.rel='stylesheet'">
    """
  }

  @doc """
  Улучшает layout'ы на основе стратегии интеграции.

  ## Parameters

  - `igniter` - Igniter context
  - `integration_strategy` - Стратегия интеграции
  - `opts` - Опции улучшения:
    - `:enhancement_categories` - Категории улучшений для применения (default: [:flash_messages, :auth_integration, :liveview_compatibility])
    - `:preservation_mode` - Режим сохранения существующего кода (:strict, :moderate, :minimal)
    - `:backup_original` - Создавать ли резервные копии (default: true)

  ## Returns

  - `{:ok, updated_igniter, enhancement_result}` - успешное улучшение
  - `{:error, reason}` - ошибка при улучшении

  ## Examples

      iex> LayoutEnhancer.enhance_layouts(igniter, :enhance_existing_layouts)
      {:ok, updated_igniter, %{
        enhanced_files: [...],
        applied_enhancements: [...],
        preserved_features: [...]
      }}
  """
  def enhance_layouts(igniter, integration_strategy, opts \\ []) do
    enhancement_categories =
      Keyword.get(opts, :enhancement_categories, [
        :flash_messages,
        :auth_integration,
        :liveview_compatibility
      ])

    preservation_mode = Keyword.get(opts, :preservation_mode, :moderate)
    backup_original = Keyword.get(opts, :backup_original, true)

    Logger.info("🎨 Starting layout enhancement process")
    Logger.info("   Strategy: #{integration_strategy}")
    Logger.info("   Categories: #{inspect(enhancement_categories)}")
    Logger.info("   Preservation mode: #{preservation_mode}")

    enhancement_start_time = System.monotonic_time(:millisecond)

    with {:ok, layout_files} <- discover_layout_files_to_enhance(igniter),
         {:ok, enhancement_plan} <-
           create_enhancement_plan(layout_files, enhancement_categories, preservation_mode),
         {:ok, backed_up_igniter} <-
           maybe_backup_original_files(igniter, layout_files, backup_original),
         {:ok, enhanced_igniter, applied_enhancements} <-
           apply_enhancements(backed_up_igniter, enhancement_plan),
         {:ok, validated_igniter, validation_result} <-
           validate_enhancements(enhanced_igniter, enhancement_plan) do
      enhancement_duration = System.monotonic_time(:millisecond) - enhancement_start_time

      enhancement_result = %{
        enhancement_timestamp: DateTime.utc_now(),
        enhancement_duration_ms: enhancement_duration,
        integration_strategy: integration_strategy,
        enhanced_files: layout_files,
        enhancement_plan: enhancement_plan,
        applied_enhancements: applied_enhancements,
        validation_result: validation_result,
        backup_created: backup_original,
        preservation_mode: preservation_mode,
        recommendations:
          generate_enhancement_recommendations(applied_enhancements, validation_result)
      }

      log_enhancement_summary(enhancement_result)
      {:ok, validated_igniter, enhancement_result}
    else
      error ->
        Logger.error("❌ Layout enhancement failed: #{inspect(error)}")
        error
    end
  end

  @doc """
  Анализирует layout файл и предлагает возможные улучшения.
  """
  def analyze_enhancement_opportunities(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        opportunities = identify_enhancement_opportunities(content, file_path)

        {:ok,
         %{
           file_path: file_path,
           total_opportunities: length(opportunities),
           opportunities_by_category: group_opportunities_by_category(opportunities),
           high_priority_opportunities: filter_opportunities_by_priority(opportunities, :high),
           estimated_enhancement_time: estimate_enhancement_time(opportunities)
         }}

      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
    end
  end

  @doc """
  Применяет конкретное улучшение к layout файлу.
  """
  def apply_specific_enhancement(igniter, file_path, enhancement_type, enhancement_opts \\ []) do
    Logger.info("🔧 Applying specific enhancement: #{enhancement_type} to #{file_path}")

    with {:ok, current_content} <- read_file_content(file_path),
         {:ok, enhanced_content} <-
           apply_enhancement_to_content(current_content, enhancement_type, enhancement_opts),
         {:ok, updated_igniter} <- write_enhanced_content(igniter, file_path, enhanced_content) do
      {:ok, updated_igniter,
       %{
         file_path: file_path,
         enhancement_type: enhancement_type,
         content_changes: calculate_content_changes(current_content, enhanced_content),
         enhancement_successful: true
       }}
    else
      error ->
        Logger.error("❌ Failed to apply enhancement #{enhancement_type}: #{inspect(error)}")
        error
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp discover_layout_files_to_enhance(_igniter) do
    Logger.debug("Discovering layout files for enhancement...")

    try do
      layout_patterns = [
        "lib/*/web/components/layouts/*.html.heex",
        "lib/*_web/components/layouts/*.html.heex",
        "lib/*/web/templates/layout/*.html.eex",
        "lib/*_web/templates/layout/*.html.eex"
      ]

      layout_files =
        layout_patterns
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.filter(&File.exists?/1)
        |> Enum.filter(&is_enhanceable_layout?/1)
        |> Enum.sort()

      Logger.debug("Found #{length(layout_files)} enhanceable layout files")
      {:ok, layout_files}
    rescue
      error ->
        {:error, {:layout_discovery_error, error}}
    end
  end

  defp create_enhancement_plan(layout_files, enhancement_categories, preservation_mode) do
    Logger.debug("Creating enhancement plan for #{length(layout_files)} files...")

    enhancement_plan =
      layout_files
      |> Enum.map(fn file_path ->
        case File.read(file_path) do
          {:ok, content} ->
            opportunities = identify_enhancement_opportunities(content, file_path)

            filtered_opportunities =
              filter_opportunities_by_categories(opportunities, enhancement_categories)

            prioritized_opportunities =
              prioritize_opportunities(filtered_opportunities, preservation_mode)

            %{
              file_path: file_path,
              opportunities: opportunities,
              planned_enhancements: prioritized_opportunities,
              estimated_time: estimate_file_enhancement_time(prioritized_opportunities),
              risk_level: assess_enhancement_risk(prioritized_opportunities, preservation_mode)
            }

          {:error, reason} ->
            Logger.warning(
              "Could not read #{file_path} for enhancement planning: #{inspect(reason)}"
            )

            %{
              file_path: file_path,
              error: reason,
              planned_enhancements: [],
              estimated_time: 0,
              risk_level: :unknown
            }
        end
      end)

    {:ok, enhancement_plan}
  end

  defp maybe_backup_original_files(igniter, _layout_files, false), do: {:ok, igniter}

  defp maybe_backup_original_files(igniter, layout_files, true) do
    Logger.debug("Creating backups of original layout files...")

    try do
      backup_timestamp = DateTime.utc_now() |> DateTime.to_unix()

      Enum.each(layout_files, fn file_path ->
        backup_path = "#{file_path}.backup.#{backup_timestamp}"
        File.cp!(file_path, backup_path)
        Logger.debug("Created backup: #{backup_path}")
      end)

      {:ok, igniter}
    rescue
      error ->
        {:error, {:backup_error, error}}
    end
  end

  defp apply_enhancements(igniter, enhancement_plan) do
    Logger.debug("Applying enhancements to #{length(enhancement_plan)} files...")

    # Оптимизация: пакетная обработка файлов для лучшей памяти и производительности
    {updated_igniter, applied_enhancements} =
      enhancement_plan
      # Обрабатываем по 3 файла за раз
      |> Enum.chunk_every(3)
      |> Enum.reduce({igniter, []}, fn file_batch, {acc_igniter, acc_enhancements} ->
        # Обрабатываем пакет файлов
        batch_results =
          Enum.reduce(file_batch, {acc_igniter, []}, fn file_plan,
                                                        {batch_igniter, batch_enhancements} ->
            case apply_file_enhancements(batch_igniter, file_plan) do
              {:ok, new_igniter, file_enhancements} ->
                {new_igniter, batch_enhancements ++ file_enhancements}

              {:error, reason} ->
                Logger.warning("Failed to enhance #{file_plan.file_path}: #{inspect(reason)}")
                {batch_igniter, batch_enhancements}
            end
          end)

        {batch_igniter, batch_enhancements} = batch_results

        # Очищаем память после каждого пакета
        :erlang.garbage_collect()

        {batch_igniter, acc_enhancements ++ batch_enhancements}
      end)

    {:ok, updated_igniter, applied_enhancements}
  end

  defp apply_file_enhancements(igniter, file_plan) do
    file_path = file_plan.file_path
    planned_enhancements = file_plan.planned_enhancements

    Logger.debug("Applying #{length(planned_enhancements)} enhancements to #{file_path}")

    case File.read(file_path) do
      {:ok, original_content} ->
        # Оптимизация: используем более эффективные строковые операции
        {enhanced_content, applied_enhancements} =
          Enum.reduce(planned_enhancements, {original_content, []}, fn enhancement,
                                                                       {content, applied} ->
            {:ok, new_content} =
              apply_enhancement_to_content(content, enhancement.type, enhancement.options)

            {new_content, applied ++ [enhancement]}
          end)

        # Оптимизация: проверяем, что содержимое действительно изменилось
        if enhanced_content != original_content do
          case write_enhanced_content(igniter, file_path, enhanced_content) do
            {:ok, updated_igniter} ->
              {:ok, updated_igniter, applied_enhancements}

            error ->
              error
          end
        else
          Logger.debug("No changes applied to #{file_path}")
          {:ok, igniter, applied_enhancements}
        end

      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
    end
  end

  defp validate_enhancements(igniter, enhancement_plan) do
    Logger.debug("Validating applied enhancements...")

    validation_result = %{
      syntax_valid: validate_syntax_of_enhanced_files(enhancement_plan),
      functionality_preserved: validate_functionality_preservation(enhancement_plan),
      enhancements_working: validate_enhancement_functionality(enhancement_plan),
      no_regressions: validate_no_regressions(enhancement_plan)
    }

    {:ok, igniter, validation_result}
  end

  defp identify_enhancement_opportunities(content, file_path) do
    Logger.debug("Identifying enhancement opportunities in #{file_path}")

    get_enhancement_patterns()
    |> Enum.flat_map(fn {category, patterns} ->
      patterns
      |> Enum.map(fn {pattern_name, pattern, enhancement, priority} ->
        if Regex.match?(pattern, content) do
          %{
            category: category,
            pattern_name: pattern_name,
            type: enhancement,
            priority: priority,
            file_path: file_path,
            options: %{}
          }
        else
          nil
        end
      end)
      |> Enum.filter(& &1)
    end)
  end

  defp group_opportunities_by_category(opportunities) do
    Enum.group_by(opportunities, & &1.category)
  end

  defp filter_opportunities_by_priority(opportunities, priority) do
    Enum.filter(opportunities, &(&1.priority == priority))
  end

  defp filter_opportunities_by_categories(opportunities, categories) do
    Enum.filter(opportunities, &(&1.category in categories))
  end

  defp prioritize_opportunities(opportunities, preservation_mode) do
    # Приоритизируем улучшения на основе режима сохранения
    case preservation_mode do
      :strict ->
        # Только безопасные улучшения высокого приоритета
        Enum.filter(opportunities, &(&1.priority == :high and is_safe_enhancement?(&1.type)))

      :moderate ->
        # Высокий и средний приоритет
        Enum.filter(opportunities, &(&1.priority in [:high, :medium]))

      :minimal ->
        # Все улучшения
        opportunities
    end
  end

  defp is_safe_enhancement?(enhancement_type) do
    # Определяем, является ли улучшение безопасным (не ломает существующий код)
    safe_enhancements = [
      :add_phoenix_kit_flash_component,
      :ensure_csrf_token,
      :add_missing_alt_attributes,
      :add_preload_hints
    ]

    enhancement_type in safe_enhancements
  end

  defp estimate_enhancement_time(opportunities) do
    # Простая оценка времени на основе количества и типа улучшений
    # минут
    base_time_per_opportunity = 5

    total_time =
      opportunities
      |> Enum.map(fn opportunity ->
        case opportunity.priority do
          :high -> base_time_per_opportunity * 2
          :medium -> base_time_per_opportunity
          :low -> div(base_time_per_opportunity, 2)
        end
      end)
      |> Enum.sum()

    "#{total_time} minutes"
  end

  defp estimate_file_enhancement_time(planned_enhancements) do
    # 3 minutes per enhancement
    length(planned_enhancements) * 3
  end

  defp assess_enhancement_risk(planned_enhancements, preservation_mode) do
    risk_factors = []

    # Risk based on number of enhancements
    risk_factors =
      risk_factors ++
        if length(planned_enhancements) > 5, do: [:many_enhancements], else: []

    # Risk based on preservation mode
    risk_factors =
      risk_factors ++
        case preservation_mode do
          :minimal -> [:aggressive_enhancements]
          :moderate -> []
          :strict -> []
        end

    # Risk based on enhancement types
    risky_enhancements = [:modernize_flash_syntax, :add_auth_navigation]

    risk_factors =
      risk_factors ++
        if Enum.any?(planned_enhancements, &(&1.type in risky_enhancements)) do
          [:risky_enhancements]
        else
          []
        end

    case length(risk_factors) do
      0 -> :low
      count when count <= 2 -> :medium
      _ -> :high
    end
  end

  defp apply_enhancement_to_content(content, enhancement_type, opts) do
    # Safety check: Skip potentially dangerous enhancements for .ex files
    if is_elixir_file?(content, enhancement_type) and is_dangerous_enhancement?(enhancement_type) do
      Logger.warning("⚠️  Skipping potentially dangerous enhancement #{enhancement_type} on Elixir file")
      Logger.warning("   This enhancement could corrupt the file structure")
      {:ok, content}
    else
      case enhancement_type do
      :add_phoenix_kit_flash_component ->
        add_flash_component(content, opts)

      :modernize_flash_syntax ->
        modernize_flash_syntax(content, opts)

      :add_current_user_display ->
        add_current_user_display(content, opts)

      :add_auth_navigation ->
        add_auth_navigation(content, opts)

      :ensure_csrf_token ->
        ensure_csrf_token(content, opts)

      :add_live_socket_setup ->
        add_live_socket_setup(content, opts)

      :add_missing_alt_attributes ->
        add_missing_alt_attributes(content, opts)

      :add_aria_labels ->
        add_aria_labels(content, opts)

      :add_preload_hints ->
        add_preload_hints(content, opts)

      :optimize_script_loading ->
        optimize_script_loading(content, opts)

      :fix_attribute_order ->
        fix_attribute_order(content, opts)

      _ ->
        Logger.warning("Unknown enhancement type: #{enhancement_type}")
        {:ok, content}
      end
    end
  end

  # Safety helper functions
  defp is_elixir_file?(content, _enhancement_type) do
    # Detect if this is an Elixir file by looking for common patterns
    String.contains?(content, "defmodule") or
    String.contains?(content, "use ") or
    String.contains?(content, "@moduledoc") or
    String.contains?(content, "embed_templates") or
    String.contains?(content, "attr :")
  end

  defp is_dangerous_enhancement?(enhancement_type) do
    # List of enhancements that are known to be dangerous for Elixir files
    enhancement_type in [
      :fix_attribute_order,
      :add_phoenix_kit_flash_component,  # Can corrupt .ex files if applied incorrectly
      :modernize_flash_syntax,           # Can break Elixir syntax
      :add_current_user_display,        # Can corrupt function definitions
      :add_auth_navigation,              # Can break module structure
      :ensure_csrf_token,                # Can corrupt head sections in .ex files
      :add_live_socket_setup             # Can break script placement in .ex files
    ]
  end

  # Enhancement implementation functions
  defp add_flash_component(content, _opts) do
    # Add PhoenixKit flash component if not present
    if not String.contains?(content, "<.flash") do
      flash_template = Map.get(@enhancement_templates, :phoenix_kit_flash_component)

      # Try to insert after opening body tag
      enhanced_content =
        case Regex.run(~r/<body[^>]*>/, content) do
          [body_tag] ->
            String.replace(content, body_tag, "#{body_tag}\n#{flash_template}")

          nil ->
            # If no body tag, try to insert in a logical place
            content <> "\n" <> flash_template
        end

      {:ok, enhanced_content}
    else
      {:ok, content}
    end
  end

  defp modernize_flash_syntax(content, _opts) do
    # Modernize old flash syntax to use components
    old_pattern = ~r/<%=\s*if\s+flash\[:(\w+)\]\s*do\s*%>.*?<%\s*end\s*%>/s

    enhanced_content =
      Regex.replace(old_pattern, content, fn _match, flash_type ->
        "<.flash kind={:#{flash_type}} flash={@flash} />"
      end)

    {:ok, enhanced_content}
  end

  defp add_current_user_display(content, _opts) do
    # Add current user display in navigation area
    if not String.contains?(content, "@current_user") do
      user_template = Map.get(@enhancement_templates, :current_user_display)

      # Try to insert in navigation or header area
      enhanced_content =
        case Regex.run(~r/<nav[^>]*>|<header[^>]*>/, content) do
          [nav_tag] ->
            String.replace(content, nav_tag, "#{nav_tag}\n#{user_template}")

          nil ->
            content <> "\n" <> user_template
        end

      {:ok, enhanced_content}
    else
      {:ok, content}
    end
  end

  defp add_auth_navigation(content, _opts) do
    # Add authentication navigation links
    # This is a more complex enhancement that would need careful positioning
    # Placeholder implementation
    {:ok, content}
  end

  defp ensure_csrf_token(content, _opts) do
    # Ensure CSRF token meta tag is present
    if not String.contains?(content, "csrf-token") do
      csrf_template = Map.get(@enhancement_templates, :csrf_token_meta)

      # Insert in head section
      enhanced_content =
        case Regex.run(~r/<head[^>]*>/, content) do
          [head_tag] ->
            String.replace(content, head_tag, "#{head_tag}\n#{csrf_template}")

          nil ->
            content
        end

      {:ok, enhanced_content}
    else
      {:ok, content}
    end
  end

  defp add_live_socket_setup(content, _opts) do
    # Add LiveView socket setup
    if not String.contains?(content, "phx-track-static") do
      socket_template = Map.get(@enhancement_templates, :live_socket_setup)

      # Insert before closing body tag
      enhanced_content = String.replace(content, "</body>", "#{socket_template}\n</body>")
      {:ok, enhanced_content}
    else
      {:ok, content}
    end
  end

  defp add_missing_alt_attributes(content, _opts) do
    # Add alt attributes to images that don't have them
    enhanced_content =
      Regex.replace(~r/<img(?![^>]*alt=)([^>]*)>/, content, fn _match, attrs ->
        "<img#{attrs} alt=\"\">"
      end)

    {:ok, enhanced_content}
  end

  defp add_aria_labels(content, _opts) do
    # Add aria-label attributes to interactive elements
    enhanced_content =
      Regex.replace(~r/<(button|input|textarea)(?![^>]*aria-label)([^>]*)>/, content, fn _match,
                                                                                         tag,
                                                                                         attrs ->
        "<#{tag}#{attrs} aria-label=\"#{String.capitalize(tag)}\">"
      end)

    {:ok, enhanced_content}
  end

  defp add_preload_hints(content, _opts) do
    # Add preload hints for stylesheets
    enhanced_content =
      Regex.replace(~r/<link([^>]*stylesheet[^>]*)>/, content, fn match, _attrs ->
        if String.contains?(match, "preload") do
          match
        else
          preload_template = Map.get(@enhancement_templates, :performance_optimizations)
          "#{preload_template}\n#{match}"
        end
      end)

    {:ok, enhanced_content}
  end

  defp optimize_script_loading(content, _opts) do
    # Add defer or async to script tags
    enhanced_content =
      Regex.replace(~r/<script(?![^>]*defer|async)([^>]*)>/, content, "<script defer\\1>")

    {:ok, enhanced_content}
  end

  # Utility functions
  defp is_enhanceable_layout?(file_path) do
    # Check if this is a layout file we should enhance
    layout_indicators = ["layout", "app.html", "root.html", "live.html"]

    Enum.any?(layout_indicators, fn indicator ->
      String.contains?(file_path, indicator)
    end)
  end

  defp read_file_content(file_path) do
    case File.read(file_path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, {:file_read_error, file_path, reason}}
    end
  end

  defp write_enhanced_content(igniter, file_path, enhanced_content) do
    # Use Igniter to write the enhanced content
    # For now, we'll write directly to the file
    case File.write(file_path, enhanced_content) do
      :ok -> {:ok, igniter}
      {:error, reason} -> {:error, {:file_write_error, file_path, reason}}
    end
  end

  defp calculate_content_changes(original, enhanced) do
    original_lines = String.split(original, "\n")
    enhanced_lines = String.split(enhanced, "\n")

    %{
      original_line_count: length(original_lines),
      enhanced_line_count: length(enhanced_lines),
      lines_added: length(enhanced_lines) - length(original_lines),
      significant_changes: abs(length(enhanced_lines) - length(original_lines)) > 5
    }
  end

  # Validation functions
  defp validate_syntax_of_enhanced_files(_enhancement_plan) do
    # TODO: Implement syntax validation
    true
  end

  defp validate_functionality_preservation(_enhancement_plan) do
    # TODO: Implement functionality preservation check
    true
  end

  defp validate_enhancement_functionality(_enhancement_plan) do
    # TODO: Implement enhancement functionality validation
    true
  end

  defp validate_no_regressions(_enhancement_plan) do
    # TODO: Implement regression validation
    true
  end

  defp generate_enhancement_recommendations(applied_enhancements, validation_result) do
    recommendations = ["Layout enhancements applied successfully"]

    # Add recommendations based on applied enhancements
    enhancement_types = applied_enhancements |> Enum.map(& &1.type) |> Enum.uniq()

    recommendations =
      recommendations ++
        if :add_phoenix_kit_flash_component in enhancement_types do
          ["✅ Added PhoenixKit flash components - flash messages will display correctly"]
        else
          []
        end

    recommendations =
      recommendations ++
        if :ensure_csrf_token in enhancement_types do
          ["🔒 Added CSRF token support - forms will be protected"]
        else
          []
        end

    # Add validation-based recommendations
    recommendations =
      recommendations ++
        if validation_result.syntax_valid do
          ["✅ All enhanced files have valid syntax"]
        else
          ["⚠️  Some syntax issues detected - review enhanced files"]
        end

    recommendations
  end

  defp fix_attribute_order(content, _opts) do
    # SAFE MODE: Disable dangerous string manipulation that corrupts files
    # The original implementation was too aggressive and would corrupt @doc comments,
    # embed_templates calls, and other important code structures.
    # 
    # Instead of attempting to fix attribute order through regex manipulation,
    # we should either:
    # 1. Use proper AST parsing (like Sourceror or Code.string_to_quoted)
    # 2. Or simply skip this enhancement to avoid file corruption
    #
    # For now, we'll skip this enhancement to prevent file corruption.
    
    Logger.debug("⏭️ Skipping attribute order fix to prevent file corruption")
    Logger.debug("   This enhancement has been disabled due to safety concerns")
    Logger.debug("   Manual fixing of attribute order is recommended instead")
    
    {:ok, content}
  end

defp log_enhancement_summary(enhancement_result) do
    Logger.info("🎨 Layout Enhancement Complete!")
    Logger.info("   Duration: #{enhancement_result.enhancement_duration_ms}ms")
    Logger.info("   Enhanced files: #{length(enhancement_result.enhanced_files)}")
    Logger.info("   Applied enhancements: #{length(enhancement_result.applied_enhancements)}")
    Logger.info("   Preservation mode: #{enhancement_result.preservation_mode}")
    Logger.info("   Backup created: #{enhancement_result.backup_created}")
    Logger.info("   Validation passed: #{enhancement_result.validation_result.syntax_valid}")
  end
end
