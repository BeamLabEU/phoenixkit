defmodule PhoenixKit.Install.RouterIntegration.Validator do
  @moduledoc """
  Валидирует успешность интеграции PhoenixKit routes в Phoenix router.
  
  Этот модуль:
  - Проверяет синтаксическую корректность router после модификации
  - Валидирует наличие необходимых imports и route calls
  - Проверяет отсутствие дублирования
  - Предоставляет диагностическую информацию
  """

  require Logger

  @required_imports ["PhoenixKitWeb.Integration"]
  @required_route_calls ["phoenix_kit_auth_routes"]

  @doc """
  Валидирует интеграцию PhoenixKit в router.
  
  ## Parameters
  
  - `igniter` - Igniter context после модификации
  - `router_module` - Модуль router для валидации
  - `integration_info` - Информация о выполненной интеграции
  
  ## Returns
  
  - `{:ok, validation_result}` - валидация успешна
  - `{:error, validation_errors}` - обнаружены ошибки
  
  ## Examples
  
      iex> Validator.validate_router_integration(igniter, MyAppWeb.Router, integration_info)
      {:ok, %{
        syntax_valid: true,
        imports_present: true,
        routes_present: true,
        no_duplicates: true,
        warnings: []
      }}
  """
  def validate_router_integration(igniter, router_module, integration_info \\ %{}) do
    Logger.info("Validating PhoenixKit integration in #{inspect(router_module)}")
    
    validation_steps = [
      {:syntax_validation, &validate_syntax/3},
      {:import_validation, &validate_imports/3},
      {:route_validation, &validate_routes/3},
      {:duplicate_validation, &validate_no_duplicates/3},
      {:structure_validation, &validate_structure/3}
    ]
    
    case run_validation_steps(igniter, router_module, integration_info, validation_steps) do
      {:ok, results} ->
        summary = compile_validation_summary(results)
        
        if summary.overall_success do
          Logger.info("✅ PhoenixKit router integration validation passed")
          {:ok, summary}
        else
          Logger.error("❌ PhoenixKit router integration validation failed")
          {:error, summary}
        end
      
      {:error, reason} = error ->
        Logger.error("❌ Validation process failed: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Быстрая проверка основных требований интеграции.
  """
  def quick_validate(igniter, router_module) do
    with {:ok, {_, _, zipper}} <- Igniter.Project.Module.find_module(igniter, router_module) do
      %{
        has_phoenix_kit_import: has_required_import?(zipper),
        has_phoenix_kit_routes: has_required_routes?(zipper),
        syntax_seems_valid: basic_syntax_check(zipper)
      }
    else
      error ->
        Logger.error("Quick validation failed: #{inspect(error)}")
        %{error: error}
    end
  end

  @doc """
  Генерирует диагностический отчет о состоянии router интеграции.
  """
  def generate_diagnostic_report(igniter, router_module) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        %{
          module: router_module,
          timestamp: DateTime.utc_now(),
          imports: analyze_imports(zipper),
          routes: analyze_routes(zipper),
          pipelines: analyze_pipelines(zipper),
          scopes: analyze_scopes(zipper),
          potential_issues: detect_potential_issues(zipper)
        }
      
      error ->
        %{
          module: router_module,
          error: error,
          timestamp: DateTime.utc_now()
        }
    end
  end

  # ============================================================================
  # Validation Step Functions  
  # ============================================================================

  defp run_validation_steps(igniter, router_module, integration_info, steps) do
    Enum.reduce_while(steps, {:ok, %{}}, fn {step_name, step_func}, {:ok, acc_results} ->
      case step_func.(igniter, router_module, integration_info) do
        {:ok, step_result} ->
          {:cont, {:ok, Map.put(acc_results, step_name, step_result)}}
        
        {:error, step_error} ->
          {:halt, {:error, %{failed_step: step_name, error: step_error, completed_steps: acc_results}}}
      end
    end)
  end

  # Валидация синтаксиса
  defp validate_syntax(igniter, router_module, _integration_info) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        # Базовая проверка на валидность AST
        if basic_syntax_check(zipper) do
          {:ok, %{syntax_valid: true, issues: []}}
        else
          {:error, %{syntax_valid: false, issues: ["Invalid AST structure detected"]}}
        end
      
      error ->
        {:error, %{syntax_valid: false, issues: ["Could not parse module: #{inspect(error)}"]}}
    end
  end

  # Валидация imports
  defp validate_imports(igniter, router_module, _integration_info) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        missing_imports = check_required_imports(zipper)
        duplicate_imports = check_duplicate_imports(zipper)
        
        {:ok, %{
          imports_present: length(missing_imports) == 0,
          missing_imports: missing_imports,
          duplicate_imports: duplicate_imports,
          issues: format_import_issues(missing_imports, duplicate_imports)
        }}
      
      error ->
        {:error, %{imports_validation_failed: error}}
    end
  end

  # Валидация routes
  defp validate_routes(igniter, router_module, _integration_info) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        missing_routes = check_required_routes(zipper)
        route_conflicts = check_route_conflicts(zipper)
        
        {:ok, %{
          routes_present: length(missing_routes) == 0,
          missing_routes: missing_routes,
          route_conflicts: route_conflicts,
          issues: format_route_issues(missing_routes, route_conflicts)
        }}
      
      error ->
        {:error, %{routes_validation_failed: error}}
    end
  end

  # Валидация дубликатов
  defp validate_no_duplicates(igniter, router_module, _integration_info) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        import_duplicates = find_duplicate_imports(zipper)
        route_duplicates = find_duplicate_routes(zipper)
        
        {:ok, %{
          no_duplicates: length(import_duplicates) == 0 and length(route_duplicates) == 0,
          duplicate_imports: import_duplicates,
          duplicate_routes: route_duplicates,
          issues: format_duplicate_issues(import_duplicates, route_duplicates)
        }}
      
      error ->
        {:error, %{duplicate_validation_failed: error}}
    end
  end

  # Валидация структуры
  defp validate_structure(igniter, router_module, _integration_info) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        structure_issues = analyze_router_structure_issues(zipper)
        
        {:ok, %{
          structure_valid: length(structure_issues) == 0,
          structure_issues: structure_issues,
          issues: structure_issues
        }}
      
      error ->
        {:error, %{structure_validation_failed: error}}
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp basic_syntax_check(zipper) do
    # Базовая проверка на валидность AST
    # TODO: Implement more thorough syntax validation
    not is_nil(zipper)
  end

  defp has_required_import?(zipper) do
    Enum.all?(@required_imports, fn import_module ->
      case find_import(zipper, import_module) do
        {:ok, _} -> true
        :error -> false
      end
    end)
  end

  defp has_required_routes?(zipper) do
    Enum.all?(@required_route_calls, fn route_call ->
      case find_route_call(zipper, route_call) do
        {:ok, _} -> true
        :error -> false
      end
    end)
  end

  defp check_required_imports(zipper) do
    @required_imports
    |> Enum.filter(fn import_module ->
      case find_import(zipper, import_module) do
        {:ok, _} -> false  # Found, so not missing
        :error -> true     # Not found, so missing
      end
    end)
  end

  defp check_duplicate_imports(_zipper) do
    # TODO: Implement duplicate import detection
    []
  end

  defp check_required_routes(zipper) do
    @required_route_calls
    |> Enum.filter(fn route_call ->
      case find_route_call(zipper, route_call) do
        {:ok, _} -> false  # Found, so not missing
        :error -> true     # Not found, so missing
      end
    end)
  end

  defp check_route_conflicts(_zipper) do
    # TODO: Implement route conflict detection
    []
  end

  defp find_duplicate_imports(_zipper) do
    # TODO: Implement comprehensive duplicate detection
    []
  end

  defp find_duplicate_routes(_zipper) do
    # TODO: Implement duplicate route detection
    []
  end

  defp analyze_router_structure_issues(_zipper) do
    issues = []
    
    # TODO: Add structure validation:
    # - Check for proper pipeline definitions
    # - Validate scope nesting
    # - Check for required Phoenix.Router imports
    
    issues
  end

  defp find_import(zipper, module_name) do
    import_pattern = quote do
      import unquote(Module.concat([module_name]))
    end
    
    case Sourceror.Zipper.find(zipper, fn node ->
      Sourceror.postwalk(node, false, fn
        ^import_pattern, _acc -> {node, true}
        node, acc -> {node, acc}
      end) |> elem(1)
    end) do
      nil -> :error
      found_zipper -> {:ok, found_zipper}
    end
  end

  defp find_route_call(zipper, function_name) do
    # Ищем вызов функции (например, phoenix_kit_auth_routes)
    patterns = [
      quote(do: unquote(String.to_atom(function_name))()), 
      quote(do: unquote(String.to_atom(function_name))(unquote_splicing(Macro.generate_arguments(1, __MODULE__))))
    ]
    
    Enum.find_value(patterns, :error, fn pattern ->
      case Sourceror.Zipper.find(zipper, fn node ->
        Sourceror.postwalk(node, false, fn
          ^pattern, _acc -> {node, true}
          node, acc -> {node, acc}
        end) |> elem(1)
      end) do
        nil -> nil
        found_zipper -> {:ok, found_zipper}
      end
    end)
  end

  defp analyze_imports(_zipper) do
    # TODO: Comprehensive import analysis
    %{total: 0, phoenix_kit_related: 0}
  end

  defp analyze_routes(_zipper) do
    # TODO: Comprehensive route analysis
    %{total: 0, phoenix_kit_related: 0}
  end

  defp analyze_pipelines(_zipper) do
    # TODO: Pipeline analysis
    %{total: 0, browser: false, api: false}
  end

  defp analyze_scopes(_zipper) do
    # TODO: Scope analysis
    %{total: 0, paths: []}
  end

  defp detect_potential_issues(_zipper) do
    # TODO: Detect potential issues
    []
  end

  defp compile_validation_summary(results) do
    errors = extract_errors_from_results(results)
    warnings = extract_warnings_from_results(results)
    
    %{
      overall_success: length(errors) == 0,
      validation_results: results,
      errors: errors,
      warnings: warnings,
      summary: generate_summary_text(results, errors, warnings)
    }
  end

  defp extract_errors_from_results(results) do
    results
    |> Enum.flat_map(fn {_step, result} ->
      Map.get(result, :issues, [])
      |> Enum.filter(fn issue -> Map.get(issue, :severity, :error) == :error end)
    end)
  end

  defp extract_warnings_from_results(results) do
    results
    |> Enum.flat_map(fn {_step, result} ->
      Map.get(result, :issues, [])
      |> Enum.filter(fn issue -> Map.get(issue, :severity, :error) == :warning end)
    end)
  end

  defp generate_summary_text(_results, errors, warnings) do
    "Validation completed with #{length(errors)} errors and #{length(warnings)} warnings"
  end

  defp format_import_issues(missing, duplicates) do
    (Enum.map(missing, &%{type: :missing_import, import: &1, severity: :error}) ++
     Enum.map(duplicates, &%{type: :duplicate_import, import: &1, severity: :warning}))
  end

  defp format_route_issues(missing, conflicts) do
    (Enum.map(missing, &%{type: :missing_route, route: &1, severity: :error}) ++
     Enum.map(conflicts, &%{type: :route_conflict, conflict: &1, severity: :error}))
  end

  defp format_duplicate_issues(import_dupes, route_dupes) do
    (Enum.map(import_dupes, &%{type: :duplicate_import, import: &1, severity: :warning}) ++
     Enum.map(route_dupes, &%{type: :duplicate_route, route: &1, severity: :warning}))
  end
end