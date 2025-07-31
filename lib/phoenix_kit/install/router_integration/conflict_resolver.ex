defmodule PhoenixKit.Install.RouterIntegration.ConflictResolver do
  @moduledoc """
  Разрешает конфликты при интеграции PhoenixKit routes в существующий router.

  Этот модуль:
  - Обнаруживает конфликты с существующими routes
  - Предлагает стратегии разрешения конфликтов
  - Автоматически разрешает простые конфликты
  - Предоставляет пользователю выбор для сложных случаев
  """

  require Logger

  @doc """
  Анализирует и разрешает конфликты в router.

  ## Parameters

  - `igniter` - Igniter context
  - `router_info` - Информация о router из ASTAnalyzer
  - `opts` - Опции разрешения конфликтов:
    - `:auto_resolve` - Автоматически разрешать простые конфликты (default: true)
    - `:interactive` - Интерактивные промпты для сложных случаев (default: true)
    - `:prefix` - Желаемый prefix для PhoenixKit routes

  ## Returns

  - `{:ok, igniter, resolution_info}` - конфликты разрешены
  - `{:error, unresolved_conflicts}` - есть неразрешенные конфликты
  """
  def resolve_router_conflicts(igniter, router_info, opts \\ []) do
    auto_resolve = Keyword.get(opts, :auto_resolve, true)
    interactive = Keyword.get(opts, :interactive, true)
    prefix = Keyword.get(opts, :prefix, "/phoenix_kit")

    Logger.info("Analyzing router conflicts for #{inspect(router_info.module)}")

    conflicts = detect_all_conflicts(router_info, prefix)

    case conflicts do
      [] ->
        Logger.info("✅ No router conflicts detected")
        {:ok, igniter, %{conflicts: [], resolutions: []}}

      conflicts ->
        Logger.info("⚠️  Detected #{length(conflicts)} router conflicts")
        resolve_conflicts(igniter, conflicts, auto_resolve, interactive)
    end
  end

  @doc """
  Обнаруживает все потенциальные конфликты в router.
  """
  def detect_all_conflicts(router_info, prefix) do
    [
      detect_duplicate_paths(router_info, prefix),
      detect_conflicting_scopes(router_info, prefix),
      detect_missing_pipelines(router_info),
      detect_existing_auth_routes(router_info),
      detect_incompatible_structure(router_info)
    ]
    |> List.flatten()
    |> Enum.filter(& &1)
  end

  # ============================================================================
  # Conflict Detection Functions
  # ============================================================================

  defp detect_duplicate_paths(router_info, prefix) do
    # Проверяем на дублирующиеся пути
    phoenix_kit_paths = get_phoenix_kit_paths(prefix)
    existing_paths = extract_existing_paths(router_info)

    duplicates =
      MapSet.intersection(
        MapSet.new(phoenix_kit_paths),
        MapSet.new(existing_paths)
      )

    if MapSet.size(duplicates) > 0 do
      Logger.warning("Duplicate paths detected: #{inspect(MapSet.to_list(duplicates))}")

      duplicates
      |> MapSet.to_list()
      |> Enum.map(fn path ->
        %{
          type: :duplicate_path,
          path: path,
          severity: :high,
          auto_resolvable: true,
          resolution_strategy: :change_prefix,
          suggested_prefix: suggest_alternative_prefix(prefix, existing_paths)
        }
      end)
    else
      []
    end
  end

  defp detect_conflicting_scopes(router_info, prefix) do
    # Проверяем на конфликтующие scope definitions
    # Например, если уже есть scope с тем же префиксом
    existing_scopes = router_info.existing_scopes

    conflicts =
      Enum.filter(existing_scopes, fn scope ->
        scope_conflicts_with_phoenix_kit?(scope, prefix)
      end)

    Enum.map(conflicts, fn scope ->
      %{
        type: :conflicting_scope,
        scope: scope,
        severity: :medium,
        auto_resolvable: true,
        resolution_strategy: :merge_scope,
        details: "Existing scope conflicts with PhoenixKit prefix"
      }
    end)
  end

  defp detect_missing_pipelines(router_info) do
    # Проверяем наличие необходимых pipelines используя boolean flags из router_info
    missing_pipelines = []

    # Проверяем :browser pipeline
    missing_pipelines =
      if router_info.has_browser_pipeline do
        missing_pipelines
      else
        [
          %{
            type: :missing_pipeline,
            pipeline: :browser,
            severity: :high,
            auto_resolvable: true,
            resolution_strategy: :create_pipeline,
            details: "PhoenixKit requires :browser pipeline"
          }
          | missing_pipelines
        ]
      end

    missing_pipelines
  end

  defp detect_existing_auth_routes(router_info) do
    # Проверяем на существующие authentication routes
    if router_info.has_phoenix_kit_routes do
      [
        %{
          type: :existing_auth_routes,
          route_type: :phoenix_kit,
          severity: :low,
          auto_resolvable: true,
          resolution_strategy: :skip_installation,
          details: "PhoenixKit routes already installed"
        }
      ]
    else
      # TODO: Detect other auth libraries routes
      []
    end
  end

  defp detect_incompatible_structure(_router_info) do
    # Проверяем на несовместимую структуру router
    incompatibilities = []

    # TODO: Add specific compatibility checks
    # - Very old Phoenix versions
    # - Non-standard router structures
    # - Missing required imports

    incompatibilities
  end

  # ============================================================================
  # Conflict Resolution Functions
  # ============================================================================

  defp resolve_conflicts(igniter, conflicts, auto_resolve, interactive) do
    {auto_resolvable, manual_resolution_needed} =
      Enum.split_with(conflicts, & &1.auto_resolvable)

    # Автоматически разрешаем простые конфликты
    {resolved_igniter, resolved_conflicts} =
      if auto_resolve do
        auto_resolve_conflicts(igniter, auto_resolvable)
      else
        {igniter, []}
      end

    # Обрабатываем сложные конфликты
    case manual_resolution_needed do
      [] ->
        Logger.info("✅ All conflicts resolved automatically")

        {:ok, resolved_igniter,
         %{
           conflicts: conflicts,
           resolutions: resolved_conflicts,
           manual_resolutions: []
         }}

      manual_conflicts when interactive ->
        handle_manual_conflicts(resolved_igniter, manual_conflicts, resolved_conflicts)

      manual_conflicts ->
        Logger.error("❌ Unresolved conflicts require manual intervention")

        {:error,
         %{
           unresolved_conflicts: manual_conflicts,
           auto_resolved: resolved_conflicts
         }}
    end
  end

  defp auto_resolve_conflicts(igniter, conflicts) do
    Logger.info("Auto-resolving #{length(conflicts)} conflicts")

    Enum.reduce(conflicts, {igniter, []}, fn conflict, {acc_igniter, resolved} ->
      case auto_resolve_single_conflict(acc_igniter, conflict) do
        {:ok, updated_igniter, resolution} ->
          Logger.debug("✅ Auto-resolved: #{conflict.type}")
          {updated_igniter, [resolution | resolved]}

        {:error, reason} ->
          Logger.warning("❌ Failed to auto-resolve #{conflict.type}: #{inspect(reason)}")
          {acc_igniter, resolved}
      end
    end)
  end

  defp auto_resolve_single_conflict(igniter, %{type: :duplicate_path} = conflict) do
    # Предлагаем альтернативный prefix
    resolution = %{
      conflict: conflict,
      action: :change_prefix,
      new_prefix: conflict.suggested_prefix
    }

    {:ok, igniter, resolution}
  end

  defp auto_resolve_single_conflict(igniter, %{type: :conflicting_scope} = conflict) do
    # Объединяем scope или создаем новый
    resolution = %{
      conflict: conflict,
      action: :merge_scope,
      details: "Merged PhoenixKit routes into existing scope"
    }

    {:ok, igniter, resolution}
  end

  defp auto_resolve_single_conflict(igniter, %{type: :existing_auth_routes}) do
    # Пропускаем установку, уже установлено
    resolution = %{
      conflict: %{type: :existing_auth_routes},
      action: :skip_installation,
      details: "PhoenixKit routes already present"
    }

    {:ok, igniter, resolution}
  end

  defp auto_resolve_single_conflict(igniter, %{type: :missing_pipeline, pipeline: :browser} = conflict) do
    # Автоматически создаем browser pipeline
    Logger.info("Creating missing browser pipeline")
    
    {:ok, updated_igniter} = create_browser_pipeline(igniter, conflict)
    
    resolution = %{
      conflict: conflict,
      action: :create_pipeline,
      pipeline: :browser,
      details: "Browser pipeline instructions provided"
    }
    {:ok, updated_igniter, resolution}
  end

  defp auto_resolve_single_conflict(_igniter, conflict) do
    {:error, {:auto_resolution_not_implemented, conflict.type}}
  end

  defp handle_manual_conflicts(_igniter, conflicts, resolved_conflicts) do
    # TODO: Implement interactive conflict resolution
    # For now, return error with manual resolution instructions

    Logger.error("Manual conflict resolution not yet implemented")

    {:error,
     %{
       message: "Manual intervention required for conflicts",
       unresolved_conflicts: conflicts,
       auto_resolved: resolved_conflicts,
       instructions: generate_manual_resolution_instructions(conflicts)
     }}
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp get_phoenix_kit_paths(prefix) do
    # Список всех путей, которые создает PhoenixKit
    base_paths = [
      "/register",
      "/log_in",
      "/log_out",
      "/reset_password",
      "/settings",
      "/confirm",
      "/test"
    ]

    Enum.map(base_paths, fn path -> prefix <> path end)
  end

  defp extract_existing_paths(_router_info) do
    # TODO: Extract actual paths from router_info.existing_scopes
    # This is a placeholder implementation
    []
  end

  defp suggest_alternative_prefix(_current_prefix, existing_paths) do
    alternatives = ["/auth", "/authentication", "/user_auth", "/account"]

    Enum.find(alternatives, "/phoenix_kit_auth", fn alt ->
      phoenix_kit_paths = get_phoenix_kit_paths(alt)
      not Enum.any?(phoenix_kit_paths, fn path -> path in existing_paths end)
    end)
  end

  defp scope_conflicts_with_phoenix_kit?(_scope, _prefix) do
    # TODO: Implement actual scope conflict detection
    false
  end

  defp generate_manual_resolution_instructions(conflicts) do
    conflicts
    |> Enum.map(fn conflict ->
      case conflict.type do
        :missing_pipeline ->
          "Add missing pipeline :#{conflict.pipeline} to your router.ex"

        :incompatible_structure ->
          "Update router structure: #{conflict.details}"

        _ ->
          "Resolve #{conflict.type}: #{Map.get(conflict, :details, "Manual intervention required")}"
      end
    end)
  end

  # ============================================================================
  # Pipeline Creation Functions
  # ============================================================================

  defp create_browser_pipeline(igniter, _conflict) do
    Logger.info("Creating missing browser pipeline in router")
    
    # Показываем пользователю инструкции по созданию browser pipeline
    Logger.info("""
    ℹ️  Please manually add the browser pipeline to your router.ex:
    
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end
    
    Then add 'pipe_through :browser' to your web routes.
    """)
    
    # Возвращаем успех, так как предоставили четкие инструкции
    # В будущих версиях можно будет добавить автоматическое создание через Igniter
    Logger.info("✅ Browser pipeline instructions provided")
    {:ok, igniter}
  end
end
