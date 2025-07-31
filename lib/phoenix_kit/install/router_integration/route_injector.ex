defmodule PhoenixKit.Install.RouterIntegration.RouteInjector do
  @moduledoc """
  Инжектирует PhoenixKit authentication routes в Phoenix router.

  Этот модуль:
  - Находит оптимальное место для добавления PhoenixKit routes
  - Добавляет вызов phoenix_kit_auth_routes() с правильным префиксом
  - Обрабатывает различные сценарии router структур
  - Поддерживает настройку custom префиксов
  """

  require Logger

  @default_prefix "/phoenix_kit"

  @doc """
  Инжектирует PhoenixKit routes в router module.

  ## Parameters

  - `igniter` - Igniter context
  - `router_module` - Модуль router (например, MyAppWeb.Router)  
  - `opts` - Опции конфигурации:
    - `:prefix` - URL prefix для PhoenixKit routes (default: "/phoenix_kit")
    - `:position` - Позиция для инжекции (:auto, :after_browser, :before_api, :end)

  ## Returns

  - `{:ok, igniter}` - routes успешно добавлены
  - `{:error, reason}` - ошибка при добавлении routes

  ## Examples

      iex> RouteInjector.inject_phoenix_kit_routes(igniter, MyAppWeb.Router)
      {:ok, updated_igniter}
      
      iex> RouteInjector.inject_phoenix_kit_routes(igniter, MyAppWeb.Router, prefix: "/auth")
      {:ok, updated_igniter}
  """
  def inject_phoenix_kit_routes(igniter, router_module, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, @default_prefix)
    position = Keyword.get(opts, :position, :auto)

    Logger.info(
      "Injecting PhoenixKit routes into #{inspect(router_module)} with prefix '#{prefix}'"
    )

    case Igniter.Project.Module.find_and_update_module(
           igniter,
           router_module,
           &inject_routes(&1, prefix, position)
         ) do
      {:ok, updated_igniter} ->
        Logger.info("✅ PhoenixKit routes injected successfully")
        {:ok, updated_igniter}

      {:error, reason} = error ->
        Logger.error("❌ Failed to inject PhoenixKit routes: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Проверяет, уже ли добавлены PhoenixKit routes в router.
  """
  def has_phoenix_kit_routes?(igniter, router_module) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        check_for_phoenix_kit_routes(zipper)

      {:error, _} ->
        false
    end
  end

  @doc """
  Удаляет существующие PhoenixKit routes из router (для переустановки).
  """
  def remove_phoenix_kit_routes(igniter, router_module) do
    Logger.info("Removing existing PhoenixKit routes from #{inspect(router_module)}")

    case Igniter.Project.Module.find_and_update_module(igniter, router_module, &remove_routes/1) do
      {:ok, updated_igniter} ->
        Logger.info("✅ PhoenixKit routes removed successfully")
        {:ok, updated_igniter}

      {:error, reason} = error ->
        Logger.error("❌ Failed to remove PhoenixKit routes: #{inspect(reason)}")
        error
    end
  end

  # ============================================================================
  # Private Helper Functions
  # ============================================================================

  defp inject_routes(zipper, prefix, position) do
    if check_for_phoenix_kit_routes(zipper) do
      Logger.debug("PhoenixKit routes already exist, skipping injection")
      zipper
    else
      Logger.debug("Adding PhoenixKit routes with prefix: #{prefix}")
      add_route_call(zipper, prefix, position)
    end
  end

  defp check_for_phoenix_kit_routes(zipper) do
    # Ищем существующий вызов phoenix_kit_auth_routes
    route_patterns = [
      quote(do: phoenix_kit_auth_routes()),
      quote(
        do: phoenix_kit_auth_routes(unquote_splicing(Macro.generate_arguments(1, __MODULE__)))
      )
    ]

    Enum.any?(route_patterns, fn pattern ->
      case Sourceror.Zipper.find(zipper, fn node ->
             Sourceror.postwalk(node, false, fn
               ^pattern, _acc -> {node, true}
               node, acc -> {node, acc}
             end)
             |> elem(1)
           end) do
        nil -> false
        _ -> true
      end
    end)
  end

  defp add_route_call(zipper, prefix, position) do
    injection_point = determine_injection_point(zipper, position)
    route_call = build_route_call(prefix)

    case inject_at_point(zipper, route_call, injection_point) do
      {:ok, updated_zipper} ->
        Logger.debug("Route call injected at #{injection_point}")
        updated_zipper

      {:error, reason} ->
        Logger.error("Failed to inject route call: #{inspect(reason)}")
        # Fallback to end of file injection
        inject_at_end_of_file(zipper, route_call)
    end
  end

  defp determine_injection_point(zipper, :auto) do
    # Автоматически определяем лучшее место для инжекции
    cond do
      has_browser_scopes?(zipper) -> :after_last_browser_scope
      has_any_scopes?(zipper) -> :after_last_scope
      has_pipelines?(zipper) -> :after_pipelines
      true -> :end_of_file
    end
  end

  defp determine_injection_point(_zipper, position)
       when position in [:after_browser, :before_api, :end] do
    position
  end

  defp build_route_call(prefix) when prefix == @default_prefix do
    # Используем default prefix, можем не указывать параметр
    quote do
      # PhoenixKit Authentication Routes (auto-generated)
      phoenix_kit_auth_routes()
    end
  end

  defp build_route_call(prefix) do
    # Custom prefix, указываем явно
    quote do
      # PhoenixKit Authentication Routes (auto-generated)
      phoenix_kit_auth_routes(unquote(prefix))
    end
  end

  defp inject_at_point(zipper, route_call, :after_last_browser_scope) do
    with {:ok, scope_zipper} <- find_last_browser_scope(zipper) do
      Igniter.Code.Common.add_code(scope_zipper, route_call, :after)
    end
  end

  defp inject_at_point(zipper, route_call, :after_last_scope) do
    with {:ok, scope_zipper} <- find_last_scope(zipper) do
      Igniter.Code.Common.add_code(scope_zipper, route_call, :after)
    end
  end

  defp inject_at_point(zipper, route_call, :after_pipelines) do
    with {:ok, pipeline_zipper} <- find_last_pipeline(zipper) do
      Igniter.Code.Common.add_code(pipeline_zipper, route_call, :after)
    end
  end

  defp inject_at_point(zipper, route_call, :end_of_file) do
    inject_at_end_of_file(zipper, route_call)
  end

  defp inject_at_end_of_file(zipper, route_call) do
    # Добавляем в конец модуля, перед closing end
    case Igniter.Code.Common.add_code(zipper, route_call, :before_end) do
      {:ok, updated_zipper} ->
        Logger.debug("Route call added at end of file")
        updated_zipper

      {:error, reason} ->
        Logger.error("Failed to add at end of file: #{inspect(reason)}")
        zipper
    end
  end

  defp find_last_browser_scope(zipper) do
    # Ищем последний scope с :browser pipeline
    # TODO: Implement proper scope detection with browser pipeline
    find_last_scope(zipper)
  end

  defp find_last_scope(zipper) do
    # Ищем последний scope в router
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:scope, _, [_path | _]} -> true
             _ -> false
           end
         end) do
      nil ->
        {:error, :no_scopes_found}

      scope_zipper ->
        # Возвращаем найденный scope zipper
        {:ok, scope_zipper}
    end
  end

  defp find_last_pipeline(zipper) do
    # Ищем последний pipeline в router
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:pipeline, _, [_name | _]} -> true
             _ -> false
           end
         end) do
      {:ok, pipeline_zipper} ->
        {:ok, pipeline_zipper}

      :error ->
        {:error, :no_pipelines_found}
    end
  end

  defp has_browser_scopes?(zipper) do
    # Проверяем наличие scope с :browser pipeline
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:scope, _, [_path, [pipe: :browser] | _]} -> true
             {:scope, _, [_path, :browser | _]} -> true
             _ -> false
           end
         end) do
      nil -> false
      _found -> true
    end
  end

  defp has_any_scopes?(zipper) do
    # Проверяем наличие любых scope declarations
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:scope, _, [_path | _]} -> true
             _ -> false
           end
         end) do
      nil -> false
      __zipper -> true
    end
  end

  defp has_pipelines?(zipper) do
    # Проверяем наличие pipeline declarations
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:pipeline, _, [_name | _]} -> true
             _ -> false
           end
         end) do
      nil -> false
      __zipper -> true
    end
  end

  defp remove_routes(zipper) do
    # Удаляем существующие phoenix_kit_auth_routes вызовы
    # TODO: Implement removal logic
    Logger.debug("Route removal not yet implemented")
    zipper
  end
end
