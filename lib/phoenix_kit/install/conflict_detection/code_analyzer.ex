defmodule PhoenixKit.Install.ConflictDetection.CodeAnalyzer do
  @moduledoc """
  Анализирует исходный код Phoenix приложения для поиска существующих authentication patterns.

  Этот модуль:
  - Сканирует .ex файлы для поиска auth-related кода
  - Обнаруживает User schemas, authentication plugs, session management
  - Выявляет потенциальные конфликты в коде
  - Анализирует router routes для auth endpoints
  """

  require Logger

  @scan_directories [
    "lib/",
    # Legacy Phoenix structure
    "web/"
  ]

  @file_extensions [".ex", ".exs"]

  @auth_code_patterns %{
    # User schema patterns
    user_schemas: [
      {~r/defmodule\s+\w*\.User\s+do/, :user_module_definition},
      {~r/schema\s+"users"/, :users_table_schema},
      {~r/field\s+:email/, :email_field},
      {~r/field\s+:password_hash/, :password_hash_field},
      {~r/field\s+:encrypted_password/, :encrypted_password_field},
      {~r/field\s+:password/, :password_field},
      {~r/has_secure_password/, :secure_password_macro},
      {~r/unique_constraint.*email/, :email_unique_constraint}
    ],

    # Authentication plugs and functions
    auth_plugs: [
      {~r/plug\s+:authenticate/, :authenticate_plug},
      {~r/plug\s+.*Auth/, :auth_plug_pattern},
      {~r/plug\s+:ensure_authenticated/, :ensure_authenticated_plug},
      {~r/plug\s+:require_user/, :require_user_plug},
      {~r/def authenticate/, :authenticate_function},
      {~r/def login/, :login_function},
      {~r/def logout/, :logout_function},
      {~r/def sign_in/, :sign_in_function}
    ],

    # Session management
    session_management: [
      {~r/put_session/, :put_session_call},
      {~r/get_session/, :get_session_call},
      {~r/delete_session/, :delete_session_call},
      {~r/clear_session/, :clear_session_call},
      {~r/assign.*current_user/, :current_user_assign},
      {~r/@current_user/, :current_user_module_attribute}
    ],

    # Guardian-specific patterns
    guardian_code: [
      {~r/Guardian\.encode_and_sign/, :guardian_encode_sign},
      {~r/Guardian\.decode_and_verify/, :guardian_decode_verify},
      {~r/Guardian\.current_user/, :guardian_current_user},
      {~r/Guardian\.Plug/, :guardian_plug_usage},
      {~r/Guardian\.Phoenix/, :guardian_phoenix_usage}
    ],

    # Pow-specific patterns
    pow_code: [
      {~r/Pow\.Plug/, :pow_plug_usage},
      {~r/PowEmailConfirmation/, :pow_email_confirmation},
      {~r/PowPersistentSession/, :pow_persistent_session},
      {~r/pow_routes/, :pow_routes_macro}
    ],

    # Authentication routes
    auth_routes: [
      {~r/get.*login/, :login_route},
      {~r/post.*login/, :login_post_route},
      {~r/get.*logout/, :logout_route},
      {~r/delete.*logout/, :logout_delete_route},
      {~r/get.*register/, :register_route},
      {~r/post.*register/, :register_post_route},
      {~r/get.*password/, :password_route},
      {~r/scope.*auth/, :auth_scope}
    ],

    # Password hashing
    password_hashing: [
      {~r/Bcrypt\.hash_pwd_salt/, :bcrypt_hashing},
      {~r/Pbkdf2\.hash_pwd_salt/, :pbkdf2_hashing},
      {~r/Argon2\.hash_pwd_salt/, :argon2_hashing},
      {~r/Comeonin\./, :comeonin_usage},
      {~r/hash_password/, :generic_hash_password}
    ]
  }

  @doc """
  Анализирует весь код проекта для поиска authentication patterns.

  ## Parameters

  - `igniter` - Igniter context
  - `opts` - Опции анализа:
    - `:scan_test_files` - Включать ли test файлы в анализ (default: false)
    - `:max_files` - Максимальное количество файлов для сканирования (default: 1000)

  ## Returns

  - `{:ok, analysis_result}` - результат анализа кода
  - `{:error, reason}` - ошибка при анализе
  """
  def analyze_authentication_code(_igniter, opts \\ []) do
    scan_test_files = Keyword.get(opts, :scan_test_files, false)
    max_files = Keyword.get(opts, :max_files, 1000)

    Logger.info("🔍 Analyzing codebase for authentication patterns")
    Logger.info("   Scan test files: #{scan_test_files}")
    Logger.info("   Max files limit: #{max_files}")

    with {:ok, elixir_files} <- find_elixir_files(scan_test_files, max_files),
         {:ok, pattern_matches} <- scan_files_for_patterns(elixir_files) do
      conflicts = identify_code_conflicts(pattern_matches)
      user_schemas = extract_user_schemas(pattern_matches)
      auth_functions = extract_auth_functions(pattern_matches)
      recommendations = generate_code_recommendations(conflicts, pattern_matches)

      analysis_result = %{
        scanned_files: length(elixir_files),
        total_patterns_found: count_total_patterns(pattern_matches),
        pattern_matches: pattern_matches,
        user_schemas: user_schemas,
        auth_functions: auth_functions,
        conflicts: conflicts,
        critical_conflicts: filter_conflicts_by_severity(conflicts, :critical),
        major_conflicts: filter_conflicts_by_severity(conflicts, :major),
        minor_conflicts: filter_conflicts_by_severity(conflicts, :minor),
        recommendations: recommendations,
        migration_complexity: assess_migration_complexity(pattern_matches),
        requires_data_migration: requires_data_migration?(user_schemas)
      }

      log_code_analysis_summary(analysis_result)
      {:ok, analysis_result}
    else
      error ->
        Logger.error("❌ Failed to analyze code: #{inspect(error)}")
        error
    end
  end

  @doc """
  Анализирует конкретный файл для поиска authentication patterns.
  """
  def analyze_specific_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        matches = scan_content_for_auth_patterns(content, file_path)
        {:ok, %{file: file_path, matches: matches}}

      {:error, reason} ->
        {:error, {:file_read_error, file_path, reason}}
    end
  end

  @doc """
  Извлекает информацию о существующих User schemas.
  """
  def extract_user_schema_info(analysis_result) do
    user_schemas = analysis_result.user_schemas

    %{
      found_user_schemas: length(user_schemas),
      schema_files: Enum.map(user_schemas, & &1.file_path),
      has_email_field: has_pattern_type?(user_schemas, :email_field),
      has_password_field:
        has_pattern_type?(user_schemas, :password_hash_field) or
          has_pattern_type?(user_schemas, :encrypted_password_field),
      email_unique: has_pattern_type?(user_schemas, :email_unique_constraint),
      migration_needed: assess_user_schema_migration_need(user_schemas)
    }
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp find_elixir_files(scan_test_files, max_files) do
    try do
      files =
        @scan_directories
        |> Enum.filter(&File.exists?/1)
        |> Enum.flat_map(fn dir ->
          Path.wildcard("#{dir}/**/*{#{Enum.join(@file_extensions, ",")}}")
        end)
        |> filter_test_files(scan_test_files)
        |> Enum.take(max_files)
        |> Enum.sort()

      Logger.debug("Found #{length(files)} Elixir files to scan")
      {:ok, files}
    rescue
      error ->
        {:error, {:file_discovery_error, error}}
    end
  end

  defp filter_test_files(files, true), do: files

  defp filter_test_files(files, false) do
    Enum.reject(files, fn file ->
      String.contains?(file, "/test/") or String.ends_with?(file, "_test.exs")
    end)
  end

  defp scan_files_for_patterns(files) do
    Logger.debug("Scanning #{length(files)} files for auth patterns")

    pattern_matches =
      files
      |> Task.async_stream(
        fn file_path ->
          case File.read(file_path) do
            {:ok, content} ->
              matches = scan_content_for_auth_patterns(content, file_path)
              {file_path, matches}

            {:error, reason} ->
              Logger.warning("Could not read #{file_path}: #{inspect(reason)}")
              {file_path, []}
          end
        end,
        max_concurrency: 4,
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, result} -> result end)
      |> Enum.reject(fn {_file, matches} -> matches == [] end)
      |> group_patterns_by_category()

    {:ok, pattern_matches}
  end

  defp scan_content_for_auth_patterns(content, file_path) do
    @auth_code_patterns
    |> Enum.flat_map(fn {category, patterns} ->
      Enum.flat_map(patterns, fn {regex, pattern_type} ->
        case Regex.scan(regex, content, return: :index) do
          [] ->
            []

          matches ->
            Enum.map(matches, fn [{start, length}] ->
              matched_text = String.slice(content, start, length)
              line_number = count_lines_before_position(content, start)
              context = extract_context_around_match(content, start, length)

              %{
                category: category,
                pattern_type: pattern_type,
                file_path: file_path,
                line_number: line_number,
                matched_text: String.trim(matched_text),
                context: context,
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

  defp extract_context_around_match(content, start, _length) do
    # Извлекаем контекст вокруг найденного совпадения (3 строки до и после)
    lines = String.split(content, "\n")
    line_index = count_lines_before_position(content, start) - 1

    context_start = max(0, line_index - 3)
    context_end = min(length(lines) - 1, line_index + 3)

    lines
    |> Enum.slice(context_start..context_end)
    |> Enum.join("\n")
  end

  defp group_patterns_by_category(file_matches) do
    file_matches
    |> Enum.flat_map(fn {file_path, matches} ->
      Enum.map(matches, fn match -> Map.put(match, :file_path, file_path) end)
    end)
    |> Enum.group_by(& &1.category)
  end

  defp identify_code_conflicts(pattern_matches) do
    conflicts = []

    # Конфликт: Существующие User schemas
    conflicts = conflicts ++ detect_user_schema_conflicts(pattern_matches)

    # Конфликт: Существующие auth routes
    conflicts = conflicts ++ detect_auth_route_conflicts(pattern_matches)

    # Конфликт: Несовместимые auth libraries
    conflicts = conflicts ++ detect_incompatible_auth_libraries(pattern_matches)

    conflicts
  end

  defp detect_user_schema_conflicts(pattern_matches) do
    user_schemas = Map.get(pattern_matches, :user_schemas, [])

    case length(user_schemas) do
      0 ->
        []

      1 ->
        # Один User schema найден - проверяем совместимость
        schema = hd(user_schemas)
        check_user_schema_compatibility(schema)

      multiple ->
        [
          %{
            type: :multiple_user_schemas,
            severity: :major,
            description: "Multiple User schemas detected",
            count: multiple,
            schemas: user_schemas,
            resolution_strategy: :consolidate_or_choose_primary,
            auto_resolvable: false
          }
        ]
    end
  end

  defp detect_auth_route_conflicts(pattern_matches) do
    auth_routes = Map.get(pattern_matches, :auth_routes, [])

    conflicting_routes =
      Enum.filter(auth_routes, fn route ->
        conflicts_with_phoenix_kit_routes?(route)
      end)

    case conflicting_routes do
      [] ->
        []

      conflicts ->
        [
          %{
            type: :conflicting_auth_routes,
            severity: :major,
            description: "Existing auth routes conflict with PhoenixKit",
            conflicting_routes: conflicts,
            resolution_strategy: :change_phoenix_kit_prefix_or_modify_existing,
            auto_resolvable: true
          }
        ]
    end
  end

  defp detect_incompatible_auth_libraries(pattern_matches) do
    # Проверяем на несовместимые комбинации auth библиотек
    has_guardian = Map.has_key?(pattern_matches, :guardian_code)
    has_pow = Map.has_key?(pattern_matches, :pow_code)

    cond do
      has_guardian and has_pow ->
        [
          %{
            type: :incompatible_auth_libraries,
            severity: :critical,
            description: "Guardian and Pow both detected - high conflict risk",
            libraries: [:guardian, :pow],
            resolution_strategy: :choose_one_primary_system,
            auto_resolvable: false
          }
        ]

      true ->
        []
    end
  end

  defp check_user_schema_compatibility(_schema) do
    # Проверяем совместимость существующего User schema с PhoenixKit
    # TODO: Implement detailed compatibility check
    []
  end

  defp conflicts_with_phoenix_kit_routes?(route) do
    # Проверяем, конфликтует ли route с PhoenixKit routes
    phoenix_kit_paths = ["/register", "/log_in", "/log_out", "/reset_password", "/settings"]

    Enum.any?(phoenix_kit_paths, fn pk_path ->
      String.contains?(route.matched_text, pk_path)
    end)
  end

  defp extract_user_schemas(pattern_matches) do
    Map.get(pattern_matches, :user_schemas, [])
    |> Enum.group_by(& &1.file_path)
    |> Enum.map(fn {file_path, matches} ->
      %{
        file_path: file_path,
        patterns: matches,
        has_email: has_pattern_type?(matches, :email_field),
        has_password:
          has_pattern_type?(matches, :password_hash_field) or
            has_pattern_type?(matches, :encrypted_password_field),
        has_unique_email: has_pattern_type?(matches, :email_unique_constraint)
      }
    end)
  end

  defp extract_auth_functions(pattern_matches) do
    Map.get(pattern_matches, :auth_plugs, [])
    |> Enum.group_by(& &1.file_path)
    |> Enum.map(fn {file_path, matches} ->
      %{
        file_path: file_path,
        auth_functions: matches
      }
    end)
  end

  defp generate_code_recommendations(conflicts, pattern_matches) do
    base_recommendations = ["Code analysis completed"]

    conflict_recommendations =
      conflicts
      |> Enum.flat_map(fn conflict ->
        case conflict.type do
          :multiple_user_schemas ->
            [
              "⚠️  Multiple User schemas found - consolidation needed",
              "Action: Choose primary User schema or merge schemas"
            ]

          :conflicting_auth_routes ->
            [
              "⚠️  Existing auth routes conflict with PhoenixKit",
              "Action: Consider using custom prefix for PhoenixKit routes"
            ]

          :incompatible_auth_libraries ->
            [
              "🚨 Critical: Incompatible auth libraries detected",
              "Action: Choose one primary authentication system"
            ]

          _ ->
            ["Review code conflict: #{conflict.type}"]
        end
      end)

    pattern_recommendations = generate_pattern_recommendations(pattern_matches)

    base_recommendations ++ conflict_recommendations ++ pattern_recommendations
  end

  defp generate_pattern_recommendations(pattern_matches) do
    recommendations = []

    # Рекомендации на основе найденных patterns
    recommendations =
      if Map.has_key?(pattern_matches, :user_schemas) do
        recommendations ++
          [
            "✅ User schema detected - data migration may be needed"
          ]
      else
        recommendations
      end

    recommendations =
      if Map.has_key?(pattern_matches, :guardian_code) do
        recommendations ++
          [
            "ℹ️  Guardian code found - can coexist with PhoenixKit for API auth"
          ]
      else
        recommendations
      end

    recommendations =
      if Map.has_key?(pattern_matches, :pow_code) do
        recommendations ++
          [
            "⚠️  Pow code found - migration planning required"
          ]
      else
        recommendations
      end

    recommendations
  end

  defp count_total_patterns(pattern_matches) do
    pattern_matches
    |> Enum.map(fn {_category, matches} -> length(matches) end)
    |> Enum.sum()
  end

  defp filter_conflicts_by_severity(conflicts, severity) do
    Enum.filter(conflicts, fn conflict -> conflict.severity == severity end)
  end

  defp assess_migration_complexity(pattern_matches) do
    cond do
      Map.has_key?(pattern_matches, :pow_code) and Map.has_key?(pattern_matches, :user_schemas) ->
        :high

      Map.has_key?(pattern_matches, :user_schemas) ->
        :medium

      Map.has_key?(pattern_matches, :auth_plugs) ->
        :low

      true ->
        :none
    end
  end

  defp requires_data_migration?(user_schemas) do
    length(user_schemas) > 0
  end

  defp has_pattern_type?(patterns, pattern_type) do
    Enum.any?(patterns, fn pattern -> pattern.pattern_type == pattern_type end)
  end

  defp assess_user_schema_migration_need(user_schemas) do
    case length(user_schemas) do
      0 -> :none
      1 -> :data_migration_likely
      _ -> :complex_migration_required
    end
  end

  defp log_code_analysis_summary(result) do
    Logger.info("📊 Code Analysis Summary:")
    Logger.info("   Scanned files: #{result.scanned_files}")
    Logger.info("   Patterns found: #{result.total_patterns_found}")
    Logger.info("   User schemas: #{length(result.user_schemas)}")
    Logger.info("   Auth functions: #{length(result.auth_functions)}")
    Logger.info("   Total conflicts: #{length(result.conflicts)}")
    Logger.info("   Critical: #{length(result.critical_conflicts)}")
    Logger.info("   Major: #{length(result.major_conflicts)}")
    Logger.info("   Minor: #{length(result.minor_conflicts)}")
    Logger.info("   Migration complexity: #{result.migration_complexity}")
    Logger.info("   Data migration needed: #{result.requires_data_migration}")
  end
end
