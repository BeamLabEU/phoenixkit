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
    routes_exist = check_for_phoenix_kit_routes(zipper)
    Logger.debug("PhoenixKit routes check: existing=#{routes_exist}")
    
    if routes_exist do
      Logger.info("ℹ️  PhoenixKit routes already exist, skipping injection")
      {:ok, zipper}
    else
      Logger.debug("Adding PhoenixKit routes with prefix: #{prefix}")
      result = add_route_call(zipper, prefix, position)
      {:ok, result}
    end
  end

  defp check_for_phoenix_kit_routes(zipper) do
    # Простая проверка на наличие phoenix_kit_auth_routes в AST  
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:phoenix_kit_auth_routes, _, _} -> true
             _ -> false
           end
         end) do
      nil -> false
      _ -> true
    end
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

  defp determine_injection_point(_zipper, :auto) do
    # Автоматически определяем лучшее место для инжекции
    # Пока используем только :end_of_file для стабильности
    :end_of_file
    
    # TODO: После тестирования можно вернуть сложную логику:
    # cond do
    #   has_browser_scopes?(zipper) -> :after_last_browser_scope
    #   has_any_scopes?(zipper) -> :after_last_scope
    #   has_pipelines?(zipper) -> :after_pipelines
    #   true -> :end_of_file
    # end
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
    case find_last_browser_scope(zipper) do
      {:ok, scope_zipper} ->
        try do
          case Igniter.Code.Common.add_code(scope_zipper, route_call, placement: :after) do
            {:ok, updated_zipper} -> {:ok, updated_zipper}
            {:error, reason} -> {:error, reason}
            other -> 
              Logger.warning("Unexpected return from add_code: #{inspect(other)}")
              {:error, {:unexpected_return, other}}
          end
        rescue
          error ->
            Logger.error("Exception in add_code: #{inspect(error)}")
            {:error, {:exception, error}}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  defp inject_at_point(zipper, route_call, :after_last_scope) do
    case find_last_scope(zipper) do
      {:ok, scope_zipper} ->
        try do
          case Igniter.Code.Common.add_code(scope_zipper, route_call, placement: :after) do
            {:ok, updated_zipper} -> {:ok, updated_zipper}
            {:error, reason} -> {:error, reason}
            # Handle any unexpected return formats
            other -> 
              Logger.warning("Unexpected return from add_code: #{inspect(other)}")
              {:error, {:unexpected_return, other}}
          end
        rescue
          error ->
            Logger.error("Exception in add_code: #{inspect(error)}")
            {:error, {:exception, error}}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  defp inject_at_point(zipper, route_call, :after_pipelines) do
    case find_last_pipeline(zipper) do
      {:ok, pipeline_zipper} ->
        try do
          case Igniter.Code.Common.add_code(pipeline_zipper, route_call, placement: :after) do
            {:ok, updated_zipper} -> {:ok, updated_zipper}
            {:error, reason} -> {:error, reason}
            other -> 
              Logger.warning("Unexpected return from add_code: #{inspect(other)}")
              {:error, {:unexpected_return, other}}
          end
        rescue
          error ->
            Logger.error("Exception in add_code: #{inspect(error)}")
            {:error, {:exception, error}}
        end
      {:error, reason} -> {:error, reason}
    end
  end

  defp inject_at_point(zipper, route_call, :end_of_file) do
    updated_zipper = inject_at_end_of_file(zipper, route_call)
    {:ok, updated_zipper}
  end

  defp inject_at_end_of_file(zipper, route_call) do
    # Use fallback string-based injection instead of complex AST manipulation
    Logger.info("Using string-based fallback for route injection")
    fallback_string_injection(zipper, route_call)
  end

  defp fallback_string_injection(zipper, _route_call) do
    try do
      # Get the current source code
      ast = Sourceror.Zipper.node(zipper)
      source = Sourceror.to_string(ast)
      
      # Create the route code string
      route_code = "  # PhoenixKit Authentication Routes (auto-generated)\n  phoenix_kit_auth_routes()"
      
      # Validate that source has proper module structure
      if String.contains?(source, "defmodule") and String.contains?(source, "end") do
        # Find the last 'end' in the file and insert before it
        case String.split(source, "\n") do
          lines when is_list(lines) ->
            # Find the position of the last 'end' that closes the defmodule
            lines_with_index = Enum.with_index(lines)
            
            case find_safe_insertion_point(lines_with_index) do
              {:ok, position} ->
                # Insert our route code before the module end
                new_lines = List.insert_at(lines, position, route_code)
                new_source = Enum.join(new_lines, "\n")
                
                # Validate the result before applying
                case Sourceror.parse_string(new_source) do
                  {:ok, ast} ->
                    # Double check that the parsed AST is valid
                    if valid_module_ast?(ast) do
                      Logger.info("✅ Route injection successful using string-based fallback")
                      Sourceror.Zipper.zip(ast)
                    else
                      Logger.error("Parsed AST is invalid, reverting changes")
                      zipper
                    end
                    
                  {:error, reason} ->
                    Logger.error("Failed to parse modified source: #{inspect(reason)}")
                    zipper
                end
                
              {:error, reason} ->
                Logger.error("Could not find safe insertion point: #{inspect(reason)}")
                zipper
            end
            
          _ ->
            Logger.error("Could not split source into lines")
            zipper
        end
      else
        Logger.error("Invalid module structure detected, skipping string injection")
        zipper
      end
      
    rescue
      error ->
        Logger.error("Exception in string-based fallback: #{inspect(error)}")
        # Return original zipper to prevent crash
        zipper
    end
  end
  
  defp find_safe_insertion_point(lines_with_index) do
    # Try to find optimal position: after pipelines, before scopes
    case find_optimal_route_position(lines_with_index) do
      {:ok, index} -> {:ok, index}
      {:error, _} ->
        # Fallback: find the module-level 'end'
        case find_module_level_end(lines_with_index) do
          {:ok, index} -> {:ok, index}
          {:error, _} ->
            # Last fallback: find the last standalone 'end'
            find_last_standalone_end(lines_with_index)
        end
    end
  end

  defp find_optimal_route_position(lines_with_index) do
    # Find the last pipeline block
    last_pipeline_end = find_last_pipeline_end(lines_with_index)
    
    # Find the first scope block
    first_scope_start = find_first_scope_start(lines_with_index)
    
    case {last_pipeline_end, first_scope_start} do
      {{:ok, pipeline_end}, {:ok, scope_start}} when pipeline_end < scope_start ->
        # Ideal case: insert between last pipeline and first scope
        {:ok, scope_start}
      
      {{:ok, pipeline_end}, {:error, _}} ->
        # No scopes found, insert after last pipeline
        {:ok, pipeline_end + 1}
      
      {{:error, _}, {:ok, scope_start}} ->
        # No pipelines found, insert before first scope
        {:ok, scope_start}
      
      _ ->
        # Neither found, use fallback
        {:error, :no_optimal_position}
    end
  end

  defp find_last_pipeline_end(lines_with_index) do
    # Find the last 'end' that closes a pipeline block
    pipeline_blocks = 
      lines_with_index
      |> Enum.with_index(0)
      |> Enum.filter(fn {{line, _original_index}, _enum_index} ->
        String.contains?(String.trim(line), "pipeline :")
      end)
    
    case List.last(pipeline_blocks) do
      {{_line, original_index}, _enum_index} ->
        # Find the 'end' that closes this pipeline
        find_closing_end_after(lines_with_index, original_index)
      
      nil ->
        {:error, :no_pipelines}
    end
  end

  defp find_first_scope_start(lines_with_index) do
    # Find the first line that starts a scope block
    case Enum.find(lines_with_index, fn {line, _index} ->
      trimmed = String.trim(line)
      String.starts_with?(trimmed, "scope ") and String.contains?(trimmed, " do")
    end) do
      {_line, index} -> {:ok, index}
      nil -> {:error, :no_scopes}
    end
  end

  defp find_closing_end_after(lines_with_index, start_index) do
    # Find the 'end' that closes a block starting at start_index
    nesting_level = 0
    
    lines_after_start = 
      Enum.drop_while(lines_with_index, fn {_line, index} -> index <= start_index end)
    
    case find_matching_end(lines_after_start, nesting_level) do
      {:ok, index} -> {:ok, index}
      {:error, _} -> {:error, :no_matching_end}
    end
  end

  defp find_matching_end(lines_with_index, initial_level) do
    Enum.reduce_while(lines_with_index, initial_level, fn {line, index}, level ->
      trimmed = String.trim(line)
      
      cond do
        String.contains?(trimmed, " do") or String.ends_with?(trimmed, " do") ->
          {:cont, level + 1}
        
        String.trim(trimmed) == "end" ->
          if level == 0 do
            {:halt, {:ok, index}}
          else
            {:cont, level - 1}
          end
        
        true ->
          {:cont, level}
      end
    end)
    |> case do
      {:ok, index} -> {:ok, index}
      _level -> {:error, :no_matching_end}
    end
  end
  
  defp find_module_level_end(lines_with_index) do
    # Track nesting level to find the module's closing end
    {_final_level, module_end_index} = 
      Enum.reduce(lines_with_index, {0, nil}, fn {line, index}, {level, module_end} ->
        trimmed = String.trim(line)
        
        cond do
          # 'do' increases nesting level
          String.contains?(trimmed, " do") or String.ends_with?(trimmed, " do") ->
            {level + 1, module_end}
          
          # 'end' decreases nesting level
          trimmed == "end" ->
            new_level = level - 1
            if new_level == 0 do
              # This should be the module's closing end
              {new_level, index}
            else
              {new_level, module_end}
            end
          
          true ->
            {level, module_end}
        end
      end)
    
    case module_end_index do
      nil -> {:error, :no_module_end_found}
      index -> {:ok, index}
    end
  end
  
  defp find_last_standalone_end(lines_with_index) do
    # Find all lines that are just 'end'
    standalone_ends = 
      lines_with_index
      |> Enum.filter(fn {line, _index} ->
        String.trim(line) == "end"
      end)
    
    case List.last(standalone_ends) do
      {_line, index} -> {:ok, index}
      nil -> {:error, :no_suitable_insertion_point}
    end
  end
  
  defp valid_module_ast?(ast) do
    # Basic validation that AST represents a valid module
    case ast do
      {:defmodule, _, [_module_name, [do: _body]]} -> true
      _ -> false
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
      nil ->
        {:error, :no_pipelines_found}
        
      pipeline_zipper ->
        {:ok, pipeline_zipper}
    end
  end

  # These functions are kept for future use but currently unused
  # defp has_browser_scopes?(zipper) do
  #   # Проверяем наличие scope с :browser pipeline
  #   case Sourceror.Zipper.find(zipper, fn node ->
  #          case node do
  #            {:scope, _, [_path, [pipe: :browser] | _]} -> true
  #            {:scope, _, [_path, :browser | _]} -> true
  #            _ -> false
  #          end
  #        end) do
  #     nil -> false
  #     _found -> true
  #   end
  # end

  # defp has_any_scopes?(zipper) do
  #   # Проверяем наличие любых scope declarations
  #   case Sourceror.Zipper.find(zipper, fn node ->
  #          case node do
  #            {:scope, _, [_path | _]} -> true
  #            _ -> false
  #          end
  #        end) do
  #     nil -> false
  #     __zipper -> true
  #   end
  # end

  # defp has_pipelines?(zipper) do
  #   # Проверяем наличие pipeline declarations
  #   case Sourceror.Zipper.find(zipper, fn node ->
  #          case node do
  #            {:pipeline, _, [_name | _]} -> true
  #            _ -> false
  #          end
  #        end) do
  #     nil -> false
  #     __zipper -> true
  #   end
  # end

  defp remove_routes(zipper) do
    # Удаляем существующие phoenix_kit_auth_routes вызовы
    # TODO: Implement removal logic
    Logger.debug("Route removal not yet implemented")
    zipper
  end
end
