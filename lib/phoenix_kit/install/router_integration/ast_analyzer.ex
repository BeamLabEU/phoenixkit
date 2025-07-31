defmodule PhoenixKit.Install.RouterIntegration.ASTAnalyzer do
  @moduledoc """
  Анализирует AST структуру Phoenix router для интеграции PhoenixKit routes.

  Этот модуль:
  - Находит router module в Phoenix приложении
  - Анализирует структуру существующих routes и pipelines  
  - Определяет оптимальные точки для инжекции PhoenixKit кода
  - Выявляет потенциальные конфликты
  """

  require Logger

  # Оптимизация: кэш для результатов анализа
  @table_name :phoenix_kit_analysis_cache

  def start_cache do
    :ets.new(@table_name, [:set, :named_table, :public])
  rescue
    ArgumentError -> :already_exists
  end

  defp get_cached_result(key) do
    start_cache()

    case :ets.lookup(@table_name, key) do
      [{^key, result}] -> {:ok, result}
      [] -> :not_found
    end
  end

  defp cache_result(key, result) do
    start_cache()
    :ets.insert(@table_name, {key, result})
    result
  end

  @router_patterns [
    "lib/*_web/router.ex",
    "lib/*/router.ex",
    "lib/*_web/**/router.ex",
    "lib/**/router.ex"
  ]

  @doc """
  Находит и анализирует router module в Phoenix приложении.

  ## Returns

  - `{:ok, router_info}` - успешно найден и проанализирован router
  - `{:error, reason}` - router не найден или не может быть проанализирован

  ## Examples

      iex> ASTAnalyzer.find_and_analyze_router(igniter)
      {:ok, %{
        module: MyAppWeb.Router,
        file_path: "lib/my_app_web/router.ex",
        existing_scopes: [...],
        pipelines: [...],
        injection_point: :after_browser_pipeline,
        conflicts: []
      }}
  """
  def find_and_analyze_router(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)
    cache_key = {:router_analysis, app_name}

    # Оптимизация: проверяем кэш сначала
    case get_cached_result(cache_key) do
      {:ok, cached_result} ->
        Logger.debug("Using cached router analysis for #{app_name}")
        {:ok, cached_result}

      :not_found ->
        # Выполняем анализ и кэшируем результат
        case perform_router_analysis(igniter) do
          {:ok, router_info} = result ->
            cache_result(cache_key, router_info)
            Logger.info("✅ Router found and analyzed: #{inspect(router_info.module)}")
            result

          {:error, reason} = error ->
            Logger.error("❌ Router analysis failed: #{inspect(reason)}")
            error
        end
    end
  end

  defp perform_router_analysis(igniter) do
    with {:ok, router_path} <- find_router_file(igniter),
         {:ok, router_module} <- extract_router_module(igniter, router_path),
         {:ok, router_info} <- analyze_router_structure(igniter, router_module, router_path) do
      {:ok, router_info}
    else
      error -> error
    end
  end

  @doc """
  Находит файл router.ex в Phoenix приложении используя glob patterns.
  """
  def find_router_file(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)

    # Оптимизированный порядок: наиболее вероятные паттерны сначала
    high_priority_patterns = [
      # Стандартный Phoenix паттерн
      "lib/#{app_name}_web/router.ex",
      # Старый Phoenix паттерн
      "lib/#{app_name}/web/router.ex"
    ]

    # Быстрая проверка наиболее вероятных мест
    case find_first_existing_file(high_priority_patterns) do
      {:ok, path} ->
        Logger.debug("Router file found quickly: #{path}")
        {:ok, path}

      :error ->
        # Fallback: полный поиск только если быстрая проверка не сработала
        all_patterns = high_priority_patterns ++ @router_patterns

        case find_first_existing_file(@router_patterns) do
          {:ok, path} ->
            Logger.debug("Router file found after extensive search: #{path}")
            {:ok, path}

          :error ->
            {:error,
             {:router_not_found,
              %{
                searched_patterns: all_patterns,
                suggestion:
                  "Ensure your Phoenix application has a router.ex file in standard location"
              }}}
        end
    end
  end

  @doc """
  Извлекает router module из найденного файла.
  """
  def extract_router_module(igniter, router_path) do
    case File.read(router_path) do
      {:ok, content} ->
        case extract_module_name_from_content(content) do
          {:ok, module_name} ->
            module = Igniter.Project.Module.parse(module_name)

            # Проверяем, что модуль действительно существует в Igniter контексте
            case Igniter.Project.Module.module_exists(igniter, module) do
              {true, _igniter} ->
                {:ok, module}

              {false, _} ->
                {:error, {:module_not_found, module}}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  @doc """
  Анализирует структуру router для определения оптимальных точек инжекции.
  """
  def analyze_router_structure(igniter, router_module, router_path) do
    with {:ok, {_, _, zipper}} <- Igniter.Project.Module.find_module(igniter, router_module) do
      analysis = %{
        module: router_module,
        file_path: router_path,
        existing_scopes: analyze_existing_scopes(zipper),
        pipelines: analyze_existing_pipelines(zipper),
        injection_point: determine_injection_point(zipper),
        conflicts: detect_potential_conflicts(zipper),
        has_browser_pipeline: has_browser_pipeline?(zipper),
        has_phoenix_kit_routes: has_phoenix_kit_routes?(zipper)
      }

      Logger.debug("Router analysis complete: #{inspect(analysis, pretty: true)}")
      {:ok, analysis}
    else
      error ->
        {:error, {:ast_analysis_failed, error}}
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp find_first_existing_file(patterns) do
    Enum.find_value(patterns, :error, fn pattern ->
      case Path.wildcard(pattern) do
        [path | _] -> {:ok, path}
        [] -> nil
      end
    end)
  end

  defp extract_module_name_from_content(content) do
    # Ищем defmodule в начале файла
    case Regex.run(~r/^\s*defmodule\s+([A-Za-z][A-Za-z0-9_.]*)\s+do/m, content) do
      [_, module_name] ->
        {:ok, module_name}

      nil ->
        {:error, :module_definition_not_found}
    end
  end

  defp analyze_existing_scopes(_zipper) do
    # Анализируем существующие scope declarations
    scopes = []

    # TODO: Implement scope analysis using Igniter zipper navigation
    # zipper
    # |> Igniter.Code.Common.move_to_pattern(quote(do: scope(unquote_splicing(Macro.generate_arguments(2, __MODULE__)))))

    scopes
  end

  defp analyze_existing_pipelines(_zipper) do
    # Анализируем существующие pipeline declarations
    pipelines = []

    # TODO: Implement pipeline analysis
    # Искать pattern: pipeline :name do ... end

    pipelines
  end

  defp determine_injection_point(zipper) do
    # Определяем лучшее место для добавления PhoenixKit routes
    cond do
      has_browser_pipeline?(zipper) -> :after_browser_pipeline
      has_api_pipeline?(zipper) -> :before_api_pipeline
      true -> :end_of_file
    end
  end

  defp detect_potential_conflicts(_zipper) do
    conflicts = []

    # TODO: Detect conflicts like:
    # - Existing /auth routes
    # - Existing /phoenix_kit routes
    # - Conflicting pipeline names
    # - Missing required pipelines

    conflicts
  end

  defp has_browser_pipeline?(zipper) do
    # Проверяем наличие pipeline :browser
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:pipeline, _, [:browser | _]} -> true
             _ -> false
           end
         end) do
      nil -> false
      _found -> true
    end
  end

  defp has_api_pipeline?(zipper) do
    # Проверяем наличие pipeline :api
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:pipeline, _, [:api | _]} -> true
             _ -> false
           end
         end) do
      nil -> false
      _found -> true
    end
  end

  defp has_phoenix_kit_routes?(_zipper) do
    # Проверяем, уже ли добавлены PhoenixKit routes
    # TODO: Implement detection of phoenix_kit_auth_routes() calls
    # Placeholder
    false
  end
end
