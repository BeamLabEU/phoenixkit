defmodule PhoenixKit.Install.ConflictDetection.DependencyAnalyzer do
  @moduledoc """
  Анализирует зависимости Phoenix приложения для выявления конфликтующих auth библиотек.

  Этот модуль:
  - Сканирует mix.exs и mix.lock для поиска известных auth библиотек
  - Классифицирует найденные зависимости по уровню конфликта
  - Анализирует транзитивные зависимости
  - Предоставляет рекомендации по разрешению конфликтов
  """

  require Logger

  # Оптимизация: группируем библиотеки по уровню конфликта для быстрого доступа
  @high_conflict_libs [:pow, :guardian, :coherence, :sentinel, :uberauth]
  @medium_conflict_libs [:authex, :basic_auth, :passport]
  @low_conflict_libs [:ueberauth, :ueberauth_google, :ueberauth_github]
  @no_conflict_libs [:comeonin, :bcrypt_elixir, :pbkdf2_elixir, :argon2_elixir]

  @auth_libraries %{
    # JWT-based authentication
    guardian: %{
      type: :jwt,
      conflict_level: :high,
      description: "JWT-based authentication library",
      migration_complexity: :medium,
      can_coexist: true,
      coexistence_strategy: "Use Guardian for API, PhoenixKit for web"
    },

    # Session-based authentication  
    pow: %{
      type: :session,
      conflict_level: :high,
      description: "Modular and extendable authentication system",
      migration_complexity: :high,
      can_coexist: false,
      coexistence_strategy: "Complete replacement required - data migration needed"
    },

    # Legacy Phoenix authentication
    coherence: %{
      type: :legacy,
      conflict_level: :medium,
      description: "Legacy Phoenix authentication (deprecated)",
      migration_complexity: :low,
      can_coexist: false,
      coexistence_strategy: nil
    },

    # OAuth libraries
    ueberauth: %{
      type: :oauth,
      conflict_level: :low,
      description: "OAuth strategy collection",
      migration_complexity: :none,
      can_coexist: true,
      coexistence_strategy: "PhoenixKit can use Ueberauth for OAuth"
    },

    # Password hashing (usually safe)
    comeonin: %{
      type: :password_hashing,
      conflict_level: :none,
      description: "Password hashing library",
      migration_complexity: :none,
      can_coexist: true,
      coexistence_strategy: "No conflicts, both can be used"
    },
    
    # bcrypt password hashing
    bcrypt_elixir: %{
      type: :password_hashing,
      conflict_level: :none,
      description: "bcrypt password hashing for Elixir",
      migration_complexity: :none,
      can_coexist: true,
      coexistence_strategy: "No conflicts, compatible with PhoenixKit"
    },
    
    # Other password hashing libraries
    pbkdf2_elixir: %{
      type: :password_hashing,
      conflict_level: :none,
      description: "PBKDF2 password hashing",
      migration_complexity: :none,
      can_coexist: true,
      coexistence_strategy: "No conflicts, both can be used"
    },
    
    argon2_elixir: %{
      type: :password_hashing,
      conflict_level: :none,
      description: "Argon2 password hashing",
      migration_complexity: :none,
      can_coexist: true,
      coexistence_strategy: "No conflicts, both can be used"
    },

    # Other authentication libraries
    authex: %{
      type: :custom,
      conflict_level: :medium,
      description: "Custom authentication library",
      migration_complexity: :medium,
      can_coexist: true,
      coexistence_strategy: "Review implementation for conflicts"
    },

    # Database authentication
    devise_type: %{
      type: :database_auth,
      conflict_level: :high,
      description: "Database-based authentication patterns",
      migration_complexity: :high,
      can_coexist: false,
      coexistence_strategy: nil
    }
  }

  @doc """
  Анализирует все зависимости проекта для поиска auth библиотек.

  ## Parameters

  - `igniter` - Igniter context

  ## Returns

  - `{:ok, analysis_result}` - результат анализа зависимостей
  - `{:error, reason}` - ошибка при анализе

  ## Examples

      iex> DependencyAnalyzer.analyze_auth_dependencies(igniter)
      {:ok, %{
        found_libraries: [:guardian, :ueberauth],
        conflicts: [%{library: :guardian, level: :high, ...}],
        recommendations: [...]
      }}
  """
  def analyze_auth_dependencies(igniter) do
    Logger.debug("🔍 Analyzing project dependencies for auth libraries")

    with {:ok, mix_exs_deps} <- extract_mix_exs_dependencies(igniter),
         {:ok, mix_lock_deps} <- extract_mix_lock_dependencies(igniter) do
      all_deps = combine_dependencies(mix_exs_deps, mix_lock_deps)
      
      # Добавляем защиту от ошибок при анализе auth зависимостей
      auth_deps = 
        try do
          identify_auth_dependencies(all_deps)
        rescue
          error ->
            Logger.error("Error identifying auth dependencies: #{inspect(error)}")
            Logger.debug("Dependencies that caused error: #{inspect(all_deps)}")
            []
        end
      
      conflicts = analyze_conflicts(auth_deps)
      recommendations = generate_recommendations(conflicts)

      analysis_result = %{
        total_dependencies: length(all_deps),
        found_auth_libraries: Enum.map(auth_deps, & &1.name),
        auth_dependencies: auth_deps,
        conflicts: conflicts,
        high_conflict_count: count_conflicts_by_level(conflicts, :high),
        medium_conflict_count: count_conflicts_by_level(conflicts, :medium),
        low_conflict_count: count_conflicts_by_level(conflicts, :low),
        recommendations: recommendations,
        migration_required: has_migration_required_conflicts?(conflicts),
        can_auto_resolve: can_auto_resolve_all_conflicts?(conflicts)
      }

      log_analysis_summary(analysis_result)
      {:ok, analysis_result}
    else
      error ->
        Logger.error("❌ Failed to analyze dependencies: #{inspect(error)}")
        error
    end
  end

  @doc """
  Проверяет конкретную зависимость на конфликты с PhoenixKit.
  """
  def check_specific_dependency(dependency_name) when is_atom(dependency_name) do
    case Map.get(@auth_libraries, dependency_name) do
      nil ->
        {:ok, %{conflict_level: :none, is_auth_library: false}}

      library_info ->
        {:ok, Map.put(library_info, :is_auth_library, true)}
    end
  end

  @doc """
  Получает список всех известных auth библиотек.
  """
  def get_known_auth_libraries do
    @auth_libraries
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp extract_mix_exs_dependencies(_igniter) do
    case find_mix_exs_file() do
      {:ok, mix_path} ->
        parse_mix_exs_dependencies(mix_path)

      {:error, _} = error ->
        error
    end
  end

  defp extract_mix_lock_dependencies(_igniter) do
    case find_mix_lock_file() do
      {:ok, lock_path} ->
        parse_mix_lock_dependencies(lock_path)

      {:error, _} = _error ->
        # mix.lock может не существовать, это не критично
        Logger.debug("mix.lock not found, skipping lock analysis")
        {:ok, []}
    end
  end

  @doc """
  Быстрое определение уровня конфликта для библиотеки.
  Оптимизированная версия для избежания полного поиска в @auth_libraries.
  """
  def quick_conflict_level(lib_name) when is_atom(lib_name) do
    cond do
      lib_name in @high_conflict_libs -> :high
      lib_name in @medium_conflict_libs -> :medium
      lib_name in @low_conflict_libs -> :low
      lib_name in @no_conflict_libs -> :none
      true -> :unknown
    end
  end

  def quick_conflict_level(lib_name) when is_binary(lib_name) do
    quick_conflict_level(String.to_atom(lib_name))
  end

  defp find_mix_exs_file do
    case File.exists?("mix.exs") do
      true -> {:ok, "mix.exs"}
      false -> {:error, :mix_exs_not_found}
    end
  end

  defp find_mix_lock_file do
    case File.exists?("mix.lock") do
      true -> {:ok, "mix.lock"}
      false -> {:error, :mix_lock_not_found}
    end
  end

  defp parse_mix_exs_dependencies(mix_path) do
    try do
      # Читаем и парсим mix.exs файл
      case File.read(mix_path) do
        {:ok, content} ->
          deps = extract_deps_from_mix_content(content)
          {:ok, deps}

        {:error, reason} ->
          {:error, {:file_read_error, reason}}
      end
    rescue
      error ->
        {:error, {:parse_error, error}}
    end
  end

  defp parse_mix_lock_dependencies(lock_path) do
    try do
      case File.read(lock_path) do
        {:ok, content} ->
          # mix.lock содержит данные в формате Elixir terms
          case Code.eval_string(content) do
            {lock_data, _} when is_map(lock_data) ->
              deps = extract_deps_from_lock_data(lock_data)
              {:ok, deps}

            _ ->
              {:error, :invalid_lock_format}
          end

        {:error, reason} ->
          {:error, {:file_read_error, reason}}
      end
    rescue
      error ->
        {:error, {:parse_error, error}}
    end
  end

  defp extract_deps_from_mix_content(content) do
    # Используем regex для поиска deps функции
    case Regex.run(~r/defp deps.*?do\s*(.*?)\s*end/s, content) do
      [_, deps_content] ->
        parse_deps_list(deps_content)

      nil ->
        Logger.warning("Could not find deps function in mix.exs")
        []
    end
  end

  defp parse_deps_list(deps_content) do
    # Оптимизированный парсинг списка зависимостей с параллельной обработкой
    # TODO: Implement more robust parsing using Code.string_to_quoted

    deps_content
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn line -> String.starts_with?(line, "{:") end)
    |> Task.async_stream(&parse_dependency_line/1, max_concurrency: 4, timeout: 5_000)
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.filter(& &1)
  end

  defp parse_dependency_line(line) do
    # Парсим строку типа "{:guardian, "~> 2.0"}"
    case Regex.run(~r/\{:(\w+).*?\}/, line) do
      [_, dep_name] ->
        %{
          name: String.to_atom(dep_name),
          source: :mix_exs,
          line: line
        }

      nil ->
        nil
    end
  end

  defp extract_deps_from_lock_data(lock_data) do
    lock_data
    |> Enum.map(fn {dep_name, _lock_info} ->
      %{
        name: dep_name,
        source: :mix_lock,
        locked: true
      }
    end)
  end

  defp combine_dependencies(mix_deps, lock_deps) do
    # Объединяем зависимости из mix.exs и mix.lock
    all_names =
      (Enum.map(mix_deps, & &1.name) ++ Enum.map(lock_deps, & &1.name))
      |> Enum.uniq()

    Enum.map(all_names, fn name ->
      mix_info = Enum.find(mix_deps, &(&1.name == name))
      lock_info = Enum.find(lock_deps, &(&1.name == name))

      %{
        name: name,
        in_mix_exs: not is_nil(mix_info),
        in_mix_lock: not is_nil(lock_info),
        mix_info: mix_info,
        lock_info: lock_info
      }
    end)
  end

  defp identify_auth_dependencies(all_deps) do
    # Оптимизация: используем быструю проверку conflict level перед полным поиском
    all_deps
    |> Enum.filter(fn dep ->
      # Быстрая проверка сначала
      case quick_conflict_level(dep.name) do
        :unknown -> 
          # Для неизвестных библиотек проверяем, есть ли они в списке auth библиотек
          Map.has_key?(@auth_libraries, dep.name)
        _ -> 
          # Для известных библиотек всегда включаем в анализ
          true
      end
    end)
    |> Enum.map(fn dep ->
      library_info = Map.get(@auth_libraries, dep.name)
      case library_info do
        nil -> 
          # Если библиотека не найдена в списке известных auth библиотек,
          # добавляем минимальную информацию
          Map.merge(dep, %{
            type: :unknown,
            conflict_level: :none,
            description: "Unknown library",
            migration_complexity: :none,
            can_coexist: true,
            coexistence_strategy: "No known conflicts"
          })
        library_info when is_map(library_info) ->
          Map.merge(dep, library_info)
      end
    end)
  end

  defp analyze_conflicts(auth_deps) do
    auth_deps
    |> Enum.map(fn dep ->
      %{
        library: dep.name,
        conflict_level: dep.conflict_level,
        type: dep.type,
        description: dep.description,
        migration_complexity: dep.migration_complexity,
        can_coexist: dep.can_coexist,
        coexistence_strategy: dep.coexistence_strategy,
        auto_resolvable: can_auto_resolve_conflict?(dep),
        resolution_steps: generate_resolution_steps(dep)
      }
    end)
    |> Enum.filter(fn conflict -> conflict.conflict_level != :none end)
  end

  defp generate_recommendations(conflicts) do
    base_recommendations = [
      "PhoenixKit dependency analysis completed"
    ]

    # Оптимизация: группируем конфликты по уровню для более эффективной обработки
    conflicts_by_level = Enum.group_by(conflicts, & &1.conflict_level)

    conflict_recommendations =
      Enum.flat_map([:high, :medium, :low], fn level ->
        conflicts_for_level = Map.get(conflicts_by_level, level, [])

        Enum.flat_map(conflicts_for_level, fn conflict ->
          case level do
            :high ->
              case conflict.library do
                :pow ->
                  [
                    "🚨 CRITICAL CONFLICT: Pow detected - complete replacement required",
                    "Data migration planning essential - backup user data first",
                    "Consider professional migration services for production systems"
                  ]
                _ ->
                  [
                    "⚠️  HIGH CONFLICT: #{conflict.library} requires careful migration planning",
                    "Consider: #{conflict.coexistence_strategy || "Replace with PhoenixKit"}"
                  ]
              end

            :medium ->
              [
                "⚠️  MEDIUM CONFLICT: #{conflict.library} may need adjustment",
                "Recommendation: Review #{conflict.library} usage patterns"
              ]

            :low ->
              [
                "ℹ️  LOW CONFLICT: #{conflict.library} should coexist well",
                "Action: Monitor for any integration issues"
              ]
          end
        end)
      end)

    base_recommendations ++ conflict_recommendations
  end

  defp count_conflicts_by_level(conflicts, level) do
    Enum.count(conflicts, fn conflict -> conflict.conflict_level == level end)
  end

  defp has_migration_required_conflicts?(conflicts) do
    Enum.any?(conflicts, fn conflict ->
      conflict.migration_complexity in [:medium, :high]
    end)
  end

  defp can_auto_resolve_all_conflicts?(conflicts) do
    Enum.all?(conflicts, fn conflict -> conflict.auto_resolvable end)
  end

  defp can_auto_resolve_conflict?(dep) do
    # Автоматически разрешимы только конфликты низкого уровня или те, что могут сосуществовать
    dep.conflict_level in [:none, :low] or dep.can_coexist
  end

  defp generate_resolution_steps(dep) do
    case dep.conflict_level do
      :high when not dep.can_coexist ->
        [
          "1. Backup existing #{dep.name} configuration",
          "2. Plan user data migration strategy",
          "3. Replace #{dep.name} with PhoenixKit",
          "4. Test authentication flows thoroughly"
        ]

      :high when dep.can_coexist ->
        [
          "1. Review #{dep.name} and PhoenixKit integration points",
          "2. Configure separate authentication scopes",
          "3. Update routing to avoid conflicts",
          "4. Test both authentication systems"
        ]

      :medium ->
        [
          "1. Analyze #{dep.name} usage in codebase",
          "2. Identify potential integration issues",
          "3. Plan gradual migration if needed"
        ]

      :low ->
        [
          "1. Monitor for any integration issues",
          "2. Update configuration if needed"
        ]

      _ ->
        ["No action required"]
    end
  end

  defp log_analysis_summary(result) do
    # Краткая сводка только для важной информации
    if result.high_conflict_count > 0 or result.medium_conflict_count > 0 do
      Logger.info("⚠️  Dependency conflicts detected:")
      if result.high_conflict_count > 0, do: Logger.info("   High conflicts: #{result.high_conflict_count}")
      if result.medium_conflict_count > 0, do: Logger.info("   Medium conflicts: #{result.medium_conflict_count}")
      if result.migration_required, do: Logger.info("   Migration required: #{result.migration_required}")
    else
      Logger.info("✅ No dependency conflicts detected")
    end

    # Показываем найденные auth библиотеки только если есть конфликты или в debug режиме  
    if length(result.found_auth_libraries) > 0 and (result.high_conflict_count > 0 or result.medium_conflict_count > 0) do
      Logger.info("   Found libraries: #{inspect(result.found_auth_libraries)}")
    end
  end
end
