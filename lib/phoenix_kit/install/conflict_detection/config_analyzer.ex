defmodule PhoenixKit.Install.ConflictDetection.ConfigAnalyzer do
  @moduledoc """
  Анализирует конфигурационные файлы Phoenix приложения для поиска существующих auth настроек.
  
  Этот модуль:
  - Сканирует config/*.exs файлы для поиска auth-related конфигураций
  - Обнаруживает конфигурации популярных auth библиотек
  - Выявляет потенциальные конфликты в настройках
  - Предоставляет рекомендации по интеграции с PhoenixKit
  """

  require Logger

  @config_files [
    "config/config.exs",
    "config/dev.exs", 
    "config/test.exs",
    "config/prod.exs",
    "config/runtime.exs"
  ]

  @auth_config_patterns %{
    # Guardian JWT configurations
    guardian: [
      {~r/config\s+:guardian/, :guardian_main_config},
      {~r/config\s+:\w+,\s+\w*Guardian/, :guardian_app_config},
      {~r/Guardian\.DB/, :guardian_db_config},
      {~r/Guardian\.Phoenix/, :guardian_phoenix_config},
      {~r/guardian_secret_key/, :guardian_secret}
    ],
    
    # Pow configurations
    pow: [
      {~r/config\s+:pow/, :pow_main_config},
      {~r/user:\s+\w+\.Users\.User/, :pow_user_schema},
      {~r/repo:\s+\w+\.Repo/, :pow_repo_config},
      {~r/Pow\.Store/, :pow_store_config},
      {~r/PowEmailConfirmation/, :pow_email_confirmation},
      {~r/PowPersistentSession/, :pow_persistent_session}
    ],
    
    # Coherence configurations (legacy)
    coherence: [
      {~r/config\s+:coherence/, :coherence_main_config},
      {~r/Coherence\.Schema/, :coherence_schema},
      {~r/Coherence\.Config/, :coherence_config_module}
    ],
    
    # Ueberauth OAuth configurations
    ueberauth: [
      {~r/config\s+:ueberauth/, :ueberauth_main_config},
      {~r/Ueberauth\.Strategy/, :ueberauth_strategy},
      {~r/github_client_id/, :ueberauth_github},
      {~r/google_client_id/, :ueberauth_google},
      {~r/facebook_app_id/, :ueberauth_facebook}
    ],
    
    # Generic authentication patterns
    generic: [
      {~r/password_hash/, :password_hashing},
      {~r/session_signing_salt/, :session_config},
      {~r/live_view_signing_salt/, :liveview_session},
      {~r/secret_key_base/, :app_secret},
      {~r/:fetch_session/, :session_plug},
      {~r/:protect_from_forgery/, :csrf_protection}
    ],
    
    # Database user schemas
    user_schemas: [
      {~r/schema\s+"users"/, :users_table_schema},
      {~r/defmodule\s+\w+\.User\s+do/, :user_module},
      {~r/field\s+:email/, :user_email_field},
      {~r/field\s+:password/, :user_password_field},
      {~r/has_secure_password/, :secure_password}
    ]
  }

  @doc """
  Анализирует все конфигурационные файлы для поиска auth настроек.
  
  ## Parameters
  
  - `igniter` - Igniter context (для будущих расширений)
  
  ## Returns
  
  - `{:ok, analysis_result}` - результат анализа конфигураций
  - `{:error, reason}` - ошибка при анализе
  
  ## Examples
  
      iex> ConfigAnalyzer.analyze_auth_configurations(igniter)
      {:ok, %{
        scanned_files: ["config/config.exs", ...],
        found_patterns: [...],
        conflicts: [...],
        recommendations: [...]
      }}
  """
  def analyze_auth_configurations(_igniter) do
    Logger.info("🔍 Analyzing configuration files for auth settings")
    
    with {:ok, config_contents} <- read_all_config_files(),
         {:ok, pattern_matches} <- scan_for_auth_patterns(config_contents) do
      
      conflicts = identify_configuration_conflicts(pattern_matches)
      recommendations = generate_config_recommendations(conflicts, pattern_matches)
      
      analysis_result = %{
        scanned_files: get_existing_config_files(),
        total_patterns_found: count_total_patterns(pattern_matches),
        found_libraries: extract_found_libraries(pattern_matches),
        pattern_matches: pattern_matches,
        conflicts: conflicts,
        high_priority_conflicts: filter_conflicts_by_priority(conflicts, :high),
        medium_priority_conflicts: filter_conflicts_by_priority(conflicts, :medium),
        recommendations: recommendations,
        requires_manual_review: has_complex_conflicts?(conflicts),
        safe_to_proceed: is_safe_to_proceed?(conflicts)
      }
      
      log_config_analysis_summary(analysis_result)
      {:ok, analysis_result}
    else
      error ->
        Logger.error("❌ Failed to analyze configurations: #{inspect(error)}")
        error
    end
  end

  @doc """
  Анализирует конкретный конфигурационный файл.
  """
  def analyze_specific_config_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        matches = scan_content_for_patterns(content, file_path)
        {:ok, %{file: file_path, matches: matches}}
      
      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
    end
  end

  @doc """
  Проверяет, есть ли конфликты PhoenixKit в существующих конфигурациях.
  """
  def check_phoenix_kit_conflicts(config_analysis) do
    existing_phoenix_kit = find_phoenix_kit_configs(config_analysis.pattern_matches)
    
    case existing_phoenix_kit do
      [] -> 
        {:ok, %{has_conflicts: false, existing_configs: []}}
      
      existing ->
        {:ok, %{
          has_conflicts: true,
          existing_configs: existing,
          conflict_type: :duplicate_phoenix_kit_config,
          resolution: "PhoenixKit configuration already exists"
        }}
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp read_all_config_files do
    results = Enum.map(@config_files, fn file_path ->
      case File.read(file_path) do
        {:ok, content} -> {file_path, content}
        {:error, :enoent} -> nil  # File doesn't exist, skip
        {:error, reason} -> {:error, {file_path, reason}}
      end
    end)
    
    errors = Enum.filter(results, &match?({:error, _}, &1))
    
    case errors do
      [] ->
        contents = results
                  |> Enum.filter(& &1)  # Remove nils
                  |> Enum.into(%{})
        {:ok, contents}
      
      errors ->
        {:error, {:file_read_errors, errors}}
    end
  end

  defp get_existing_config_files do
    @config_files
    |> Enum.filter(&File.exists?/1)
  end

  defp scan_for_auth_patterns(config_contents) do
    pattern_matches = config_contents
    |> Enum.flat_map(fn {file_path, content} ->
      scan_content_for_patterns(content, file_path)
    end)
    |> Enum.group_by(& &1.library)
    
    {:ok, pattern_matches}
  end

  defp scan_content_for_patterns(content, file_path) do
    @auth_config_patterns
    |> Enum.flat_map(fn {library, patterns} ->
      Enum.flat_map(patterns, fn {regex, pattern_type} ->
        case Regex.scan(regex, content, return: :index) do
          [] -> []
          matches ->
            Enum.map(matches, fn [{start, length}] ->
              matched_text = String.slice(content, start, length)
              line_number = count_lines_before_position(content, start)
              
              %{
                library: library,
                pattern_type: pattern_type,
                file_path: file_path,
                line_number: line_number,
                matched_text: String.trim(matched_text),
                start_position: start,
                length: length
              }
            end)
        end
      end)
    end)
  end

  defp count_lines_before_position(content, position) do
    content
    |> String.slice(0, position)
    |> String.split("\n")
    |> length()
  end

  defp identify_configuration_conflicts(pattern_matches) do
    conflicts = []
    
    # Конфликт: Множественные auth системы
    conflicts = conflicts ++ detect_multiple_auth_systems(pattern_matches)
    
    # Конфликт: Существующие PhoenixKit конфигурации
    conflicts = conflicts ++ detect_existing_phoenix_kit_configs(pattern_matches)
    
    # Конфликт: Несовместимые настройки
    conflicts = conflicts ++ detect_incompatible_settings(pattern_matches)
    
    conflicts
  end

  defp detect_multiple_auth_systems(pattern_matches) do
    auth_libraries = [:guardian, :pow, :coherence, :ueberauth]
    found_libraries = auth_libraries
                     |> Enum.filter(fn lib -> Map.has_key?(pattern_matches, lib) end)
    
    case length(found_libraries) do
      0 -> []
      1 -> []
      multiple_count ->
        [%{
          type: :multiple_auth_systems,
          priority: :high,
          description: "Multiple authentication systems detected",
          libraries: found_libraries,
          count: multiple_count,
          resolution_strategy: :choose_primary_auth_system,
          auto_resolvable: false
        }]
    end
  end

  defp detect_existing_phoenix_kit_configs(pattern_matches) do
    case find_phoenix_kit_configs(pattern_matches) do
      [] -> []
      existing_configs ->
        [%{
          type: :existing_phoenix_kit_config,
          priority: :medium,
          description: "PhoenixKit configuration already exists",
          existing_configs: existing_configs,
          resolution_strategy: :skip_or_update_config,
          auto_resolvable: true
        }]
    end
  end

  defp detect_incompatible_settings(_pattern_matches) do
    # TODO: Implement detection of specific incompatible settings
    # For example: conflicting session configurations, CSRF settings, etc.
    []
  end

  defp find_phoenix_kit_configs(pattern_matches) do
    # Ищем существующие PhoenixKit конфигурации
    pattern_matches
    |> Enum.flat_map(fn {_library, matches} ->
      Enum.filter(matches, fn match ->
        String.contains?(match.matched_text, "phoenix_kit") or 
        String.contains?(match.matched_text, "PhoenixKit")
      end)
    end)
  end

  defp generate_config_recommendations(conflicts, pattern_matches) do
    base_recommendations = ["Configuration analysis completed"]
    
    conflict_recommendations = conflicts
    |> Enum.flat_map(fn conflict ->
      case conflict.type do
        :multiple_auth_systems ->
          [
            "⚠️  Multiple auth systems detected: #{inspect(conflict.libraries)}",
            "Consider: Choose one primary system or plan coexistence strategy",
            "Action: Review #{conflict.count} authentication configurations"
          ]
        
        :existing_phoenix_kit_config ->
          [
            "ℹ️  PhoenixKit configuration already exists",
            "Action: Installation will skip or update existing configuration"
          ]
        
        _ ->
          ["Review #{conflict.type} configuration conflict"]
      end
    end)
    
    library_recommendations = generate_library_specific_recommendations(pattern_matches)
    
    base_recommendations ++ conflict_recommendations ++ library_recommendations
  end

  defp generate_library_specific_recommendations(pattern_matches) do
    pattern_matches
    |> Enum.flat_map(fn {library, _matches} ->
      case library do
        :guardian ->
          ["Consider: Guardian can coexist with PhoenixKit for API authentication"]
        
        :pow ->
          ["⚠️  Pow conflicts with PhoenixKit - migration planning required"]
        
        :coherence ->
          ["ℹ️  Coherence is deprecated - migration to PhoenixKit recommended"]
        
        :ueberauth ->
          ["✅ Ueberauth compatible - PhoenixKit can use OAuth strategies"]
        
        _ ->
          []
      end
    end)
    |> Enum.uniq()
  end

  defp count_total_patterns(pattern_matches) do
    pattern_matches
    |> Enum.map(fn {_library, matches} -> length(matches) end)
    |> Enum.sum()
  end

  defp extract_found_libraries(pattern_matches) do
    Map.keys(pattern_matches)
  end

  defp filter_conflicts_by_priority(conflicts, priority) do
    Enum.filter(conflicts, fn conflict -> conflict.priority == priority end)
  end

  defp has_complex_conflicts?(conflicts) do
    Enum.any?(conflicts, fn conflict ->
      conflict.priority == :high and not conflict.auto_resolvable
    end)
  end

  defp is_safe_to_proceed?(conflicts) do
    # Безопасно продолжать, если нет high priority конфликтов или все auto-resolvable
    high_priority_conflicts = filter_conflicts_by_priority(conflicts, :high)
    
    case high_priority_conflicts do
      [] -> true
      conflicts -> Enum.all?(conflicts, & &1.auto_resolvable)
    end
  end

  defp log_config_analysis_summary(result) do
    Logger.info("📊 Configuration Analysis Summary:")
    Logger.info("   Scanned files: #{length(result.scanned_files)}")
    Logger.info("   Patterns found: #{result.total_patterns_found}")
    Logger.info("   Auth libraries: #{inspect(result.found_libraries)}")
    Logger.info("   Total conflicts: #{length(result.conflicts)}")
    Logger.info("   High priority: #{length(result.high_priority_conflicts)}")
    Logger.info("   Medium priority: #{length(result.medium_priority_conflicts)}")
    Logger.info("   Manual review needed: #{result.requires_manual_review}")
    Logger.info("   Safe to proceed: #{result.safe_to_proceed}")
    
    if not result.safe_to_proceed do
      Logger.warning("⚠️  Manual intervention may be required before installation")
    end
  end
end