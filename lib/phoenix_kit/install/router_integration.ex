defmodule PhoenixKit.Install.RouterIntegration do
  @moduledoc """
  Главный модуль для интеграции PhoenixKit routes в Phoenix router через AST модификацию.
  
  Этот модуль координирует работу всех компонентов router integration:
  - AST анализ существующего router
  - Обнаружение и разрешение конфликтов
  - Автоматическое добавление imports и route calls
  - Валидация результатов интеграции
  
  Предоставляет высокоуровневый API для Professional Installer.
  """

  require Logger

  alias PhoenixKit.Install.RouterIntegration.{
    ASTAnalyzer,
    ImportInjector,
    RouteInjector,
    ConflictResolver,
    Validator
  }

  @doc """
  Выполняет полную интеграцию PhoenixKit routes в router.
  
  ## Parameters
  
  - `igniter` - Igniter context
  - `opts` - Опции интеграции:
    - `:prefix` - URL prefix для PhoenixKit routes (default: "/phoenix_kit")
    - `:auto_resolve_conflicts` - Автоматически разрешать конфликты (default: true)
    - `:validate_integration` - Валидировать результат (default: true)
    - `:skip_if_exists` - Пропустить если routes уже установлены (default: true)
  
  ## Returns
  
  - `{:ok, igniter, integration_result}` - интеграция успешна
  - `{:error, reason}` - ошибка при интеграции
  - `{:skipped, reason}` - интеграция пропущена
  
  ## Examples
  
      iex> RouterIntegration.perform_full_integration(igniter)
      {:ok, updated_igniter, %{
        router_module: MyAppWeb.Router,
        conflicts_resolved: [],
        validation_passed: true
      }}
  """
  def perform_full_integration(igniter, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "/phoenix_kit")
    auto_resolve = Keyword.get(opts, :auto_resolve_conflicts, true)
    validate = Keyword.get(opts, :validate_integration, true)
    skip_if_exists = Keyword.get(opts, :skip_if_exists, true)
    
    Logger.info("🚀 Starting PhoenixKit router integration")
    Logger.info("   Prefix: #{prefix}")
    Logger.info("   Auto-resolve conflicts: #{auto_resolve}")
    Logger.info("   Validate: #{validate}")
    
    with {:ok, router_info} <- ASTAnalyzer.find_and_analyze_router(igniter),
         {:ok, igniter, skip_result} <- maybe_skip_if_exists(igniter, router_info, skip_if_exists),
         {:ok, igniter, conflict_resolution} <- resolve_conflicts_if_needed(igniter, router_info, prefix, auto_resolve),
         {:ok, igniter} <- add_import_statement(igniter, router_info.module),
         {:ok, igniter} <- add_route_call(igniter, router_info.module, prefix),
         {:ok, validation_result} <- validate_if_requested(igniter, router_info.module, validate) do
      
      integration_result = %{
        router_module: router_info.module,
        router_path: router_info.file_path,
        prefix: prefix,
        conflicts_resolved: conflict_resolution.resolutions,
        skip_result: skip_result,
        validation_result: validation_result,
        success: true
      }
      
      Logger.info("✅ PhoenixKit router integration completed successfully")
      {:ok, igniter, integration_result}
    else
      {:skipped, reason} = skip_result ->
        Logger.info("⏭️  PhoenixKit router integration skipped: #{inspect(reason)}")
        skip_result
      
      {:error, reason} = error ->
        Logger.error("❌ PhoenixKit router integration failed: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Проверяет, возможна ли интеграция PhoenixKit в данный router.
  
  Быстрая проверка без модификации файлов.
  """
  def check_integration_feasibility(igniter, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "/phoenix_kit")
    
    with {:ok, router_info} <- ASTAnalyzer.find_and_analyze_router(igniter) do
      conflicts = ConflictResolver.detect_all_conflicts(router_info, prefix)
      
      feasibility = %{
        router_found: true,
        router_module: router_info.module,
        conflicts: conflicts,
        auto_resolvable_conflicts: Enum.count(conflicts, & &1.auto_resolvable),
        manual_conflicts: Enum.count(conflicts, &(not &1.auto_resolvable)),
        feasible: Enum.all?(conflicts, & &1.auto_resolvable),
        recommendations: generate_feasibility_recommendations(conflicts)
      }
      
      {:ok, feasibility}
    else
      error ->
        {:error, %{
          router_found: false,
          error: error,
          feasible: false,
          recommendations: ["Ensure your Phoenix application has a properly structured router.ex file"]
        }}
    end
  end

  @doc """
  Отменяет интеграцию PhoenixKit routes (для debugging или переустановки).
  """
  def rollback_integration(igniter, _opts \\ []) do
    Logger.info("🔄 Rolling back PhoenixKit router integration")
    
    with {:ok, router_info} <- ASTAnalyzer.find_and_analyze_router(igniter),
         {:ok, igniter} <- RouteInjector.remove_phoenix_kit_routes(igniter, router_info.module) do
      
      # Note: We don't remove imports as they might be used elsewhere
      Logger.info("✅ PhoenixKit routes removed from router")
      {:ok, igniter}
    else
      error ->
        Logger.error("❌ Failed to rollback router integration: #{inspect(error)}")
        error
    end
  end

  @doc """
  Генерирует детальный отчет о состоянии router интеграции.
  """
  def generate_integration_report(igniter, _opts \\ []) do
    case ASTAnalyzer.find_and_analyze_router(igniter) do
      {:ok, router_info} ->
        diagnostic_report = Validator.generate_diagnostic_report(igniter, router_info.module)
        quick_validation = Validator.quick_validate(igniter, router_info.module)
        
        %{
          timestamp: DateTime.utc_now(),
          router_info: router_info,
          diagnostic_report: diagnostic_report,
          quick_validation: quick_validation,
          integration_status: determine_integration_status(quick_validation)
        }
      
      {:error, reason} ->
        %{
          timestamp: DateTime.utc_now(),
          error: reason,
          integration_status: :error
        }
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp maybe_skip_if_exists(igniter, _router_info, false) do
    {:ok, igniter, %{skipped: false}}
  end

  defp maybe_skip_if_exists(igniter, router_info, true) do
    if router_info.has_phoenix_kit_routes do
      {:skipped, :already_integrated}
    else
      {:ok, igniter, %{skipped: false}}
    end
  end

  defp resolve_conflicts_if_needed(igniter, router_info, prefix, auto_resolve) do
    case ConflictResolver.resolve_router_conflicts(igniter, router_info, 
           auto_resolve: auto_resolve, prefix: prefix) do
      {:ok, updated_igniter, resolution_info} ->
        {:ok, updated_igniter, resolution_info}
      
      {:error, unresolved_conflicts} ->
        Logger.error("Unresolved router conflicts: #{inspect(unresolved_conflicts)}")
        {:error, {:unresolved_conflicts, unresolved_conflicts}}
    end
  end

  defp add_import_statement(igniter, router_module) do
    case ImportInjector.add_phoenix_kit_import(igniter, router_module) do
      {:ok, updated_igniter} ->
        {:ok, updated_igniter}
      
      {:error, reason} ->
        Logger.error("Failed to add import: #{inspect(reason)}")
        {:error, {:import_injection_failed, reason}}
    end
  end

  defp add_route_call(igniter, router_module, prefix) do
    case RouteInjector.inject_phoenix_kit_routes(igniter, router_module, prefix: prefix) do
      {:ok, updated_igniter} ->
        {:ok, updated_igniter}
      
      {:error, reason} ->
        Logger.error("Failed to inject routes: #{inspect(reason)}")
        {:error, {:route_injection_failed, reason}}
    end
  end

  defp validate_if_requested(_igniter, _router_module, false) do
    {:ok, %{validation_skipped: true}}
  end

  defp validate_if_requested(igniter, router_module, true) do
    case Validator.validate_router_integration(igniter, router_module) do
      {:ok, validation_result} ->
        {:ok, validation_result}
      
      {:error, validation_errors} ->
        Logger.warning("Router integration validation failed: #{inspect(validation_errors)}")
        # We don't fail the entire integration for validation errors
        {:ok, %{validation_failed: true, errors: validation_errors}}
    end
  end

  defp generate_feasibility_recommendations(conflicts) do
    base_recs = ["PhoenixKit router integration is feasible"]
    
    conflict_recs = conflicts
    |> Enum.group_by(& &1.type)
    |> Enum.flat_map(fn {type, _conflicts_of_type} ->
      case type do
        :duplicate_path ->
          ["Consider using a different prefix to avoid path conflicts"]
        
        :missing_pipeline ->
          ["Ensure your router has the required pipelines: :browser"]
        
        :conflicting_scope ->
          ["Existing scopes may need to be adjusted"]
        
        _ ->
          ["Manual review recommended for #{type} conflicts"]
      end
    end)
    
    base_recs ++ conflict_recs
  end

  defp determine_integration_status(quick_validation) do
    cond do
      Map.has_key?(quick_validation, :error) ->
        :error
      
      quick_validation.has_phoenix_kit_import and quick_validation.has_phoenix_kit_routes ->
        :fully_integrated
      
      quick_validation.has_phoenix_kit_import ->
        :partially_integrated
      
      true ->
        :not_integrated
    end
  end
end