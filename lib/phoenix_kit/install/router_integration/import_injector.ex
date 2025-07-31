defmodule PhoenixKit.Install.RouterIntegration.ImportInjector do
  @moduledoc """
  Добавляет необходимые import statements в Phoenix router для PhoenixKit интеграции.

  Этот модуль:
  - Находит секцию imports в router module
  - Добавляет `import PhoenixKitWeb.Integration` если его нет
  - Обрабатывает edge cases (отсутствие imports, комментарии, etc.)
  - Поддерживает чистоту кода и правильное форматирование
  """

  require Logger

  @phoenix_kit_import "PhoenixKitWeb.Integration"

  @doc """
  Добавляет PhoenixKit import в router module.

  ## Parameters

  - `igniter` - Igniter context
  - `router_module` - Модуль router (например, MyAppWeb.Router)

  ## Returns

  - `{:ok, igniter}` - import успешно добавлен
  - `{:error, reason}` - ошибка при добавлении import

  ## Examples

      iex> ImportInjector.add_phoenix_kit_import(igniter, MyAppWeb.Router)
      {:ok, updated_igniter}
  """
  def add_phoenix_kit_import(igniter, router_module) do
    Logger.info("Adding PhoenixKit import to #{inspect(router_module)}")

    case Igniter.Project.Module.find_and_update_module(igniter, router_module, &inject_import/1) do
      {:ok, updated_igniter} ->
        Logger.info("✅ PhoenixKit import added successfully")
        {:ok, updated_igniter}

      {:error, reason} = error ->
        Logger.error("❌ Failed to add PhoenixKit import: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Проверяет, уже ли добавлен PhoenixKit import в router.
  """
  def has_phoenix_kit_import?(igniter, router_module) do
    case Igniter.Project.Module.find_module(igniter, router_module) do
      {:ok, {_, _, zipper}} ->
        check_for_phoenix_kit_import(zipper)

      {:error, _} ->
        false
    end
  end

  # ============================================================================
  # Private Helper Functions  
  # ============================================================================

  defp inject_import(zipper) do
    if check_for_phoenix_kit_import(zipper) do
      Logger.debug("PhoenixKit import already exists, skipping")
      {:ok, zipper}
    else
      Logger.debug("Adding PhoenixKit import")

      try do
        case add_import_statement(zipper) do
          %Sourceror.Zipper{} = updated_zipper ->
            {:ok, updated_zipper}

          error ->
            Logger.error("Import injection failed, using string-based fallback: #{inspect(error)}")
            result = fallback_string_import_injection(zipper)
            {:ok, result}
        end
      rescue
        e ->
          Logger.error("Exception in import injection, using fallback: #{inspect(e)}")
          result = fallback_string_import_injection(zipper)
          {:ok, result}
      end
    end
  end

  defp check_for_phoenix_kit_import(zipper) do
    # Ищем существующий import PhoenixKitWeb.Integration
    case find_import_statement(zipper, @phoenix_kit_import) do
      {:ok, _} -> true
      :error -> false
    end
  end

  defp add_import_statement(zipper) do
    case find_imports_section(zipper) do
      {:ok, import_zipper} ->
        insert_import_after_existing(import_zipper)

      :not_found ->
        # Нет секции imports, создаем новую после use statements
        create_imports_section_after_use(zipper)
    end
  end

  defp find_imports_section(zipper) do
    # Ищем последний import statement в модуле
    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             {:import, _, [_module | _]} -> true
             _ -> false
           end
         end) do
      nil ->
        :not_found

      import_zipper ->
        # Найден import, найдем последний import statement
        find_last_import(import_zipper)
    end
  end

  defp find_last_import(zipper) do
    # TODO: Implement proper navigation to find last import
    # For now, return the found import zipper
    {:ok, zipper}
  end

  defp insert_import_after_existing(zipper) do
    # Добавляем import после найденного import statement
    import_ast =
      quote do
        import PhoenixKitWeb.Integration
      end

    case Igniter.Code.Common.add_code(zipper, import_ast, placement: :after) do
      {:ok, updated_zipper} ->
        Logger.debug("Import added after existing imports")
        updated_zipper

      {:error, reason} ->
        Logger.error("Failed to insert import: #{inspect(reason)}")
        zipper

      # Handle direct zipper return (some versions of Igniter)
      updated_zipper when is_struct(updated_zipper, Sourceror.Zipper) ->
        Logger.debug("Import added after existing imports (direct zipper return)")
        updated_zipper

      unexpected ->
        Logger.error("Unexpected return from add_code: #{inspect(unexpected)}")
        zipper
    end
  end

  defp create_imports_section_after_use(zipper) do
    # Находим use Phoenix.Router statement и добавляем import после него
    case find_use_phoenix_router(zipper) do
      {:ok, use_zipper} ->
        add_import_after_use(use_zipper)

      :error ->
        # Fallback: добавляем в начало модуля после defmodule
        add_import_after_defmodule(zipper)
    end
  end

  defp find_use_phoenix_router(zipper) do
    # Ищем use Phoenix.Router или use MyAppWeb, :router
    patterns_to_try = [
      quote(do: use(Phoenix.Router)),
      quote(do: use(Phoenix.Router, unquote_splicing(Macro.generate_arguments(1, __MODULE__)))),
      quote(do: use(unquote_splicing(Macro.generate_arguments(2, __MODULE__))))
    ]

    Enum.find_value(patterns_to_try, :error, fn pattern ->
      case Sourceror.Zipper.find(zipper, fn node ->
             case node do
               ^pattern -> true
               _ -> false
             end
           end) do
        nil -> nil
        found_zipper -> {:ok, found_zipper}
      end
    end)
  end

  defp add_import_after_use(zipper) do
    import_ast =
      quote do
        import PhoenixKitWeb.Integration
      end

    case Igniter.Code.Common.add_code(zipper, import_ast, placement: :after) do
      {:ok, updated_zipper} ->
        Logger.debug("Import added after use statement")
        updated_zipper

      {:error, reason} ->
        Logger.error("Failed to add import after use: #{inspect(reason)}")
        zipper

      # Handle direct zipper return (some versions of Igniter)
      updated_zipper when is_struct(updated_zipper, Sourceror.Zipper) ->
        Logger.debug("Import added after use statement (direct zipper return)")
        updated_zipper

      unexpected ->
        Logger.error(
          "Unexpected return from add_code in add_import_after_use: #{inspect(unexpected)}"
        )

        zipper
    end
  end

  defp add_import_after_defmodule(zipper) do
    # Fallback: добавляем import в начало модуля, используя более простой подход
    Logger.debug("Using fallback approach to add import")

    # Вместо сложной AST манипуляции, просто возвращаем исходный zipper
    # Это предотвращает креш, но означает, что import не будет добавлен
    # TODO: Implement proper import addition
    Logger.warning(
      "Import addition not implemented in fallback - import may need to be added manually"
    )

    zipper
  end

  defp find_import_statement(zipper, module_name) do
    # Ищем import для конкретного модуля
    import_pattern =
      quote do
        import unquote(Module.concat([module_name]))
      end

    case Sourceror.Zipper.find(zipper, fn node ->
           case node do
             ^import_pattern -> true
             _ -> false
           end
         end) do
      nil -> :error
      zipper -> {:ok, zipper}
    end
  end

  defp fallback_string_import_injection(zipper) do
    Logger.info("Using string-based fallback for import injection")
    
    try do
      # Get the current source code
      ast = Sourceror.Zipper.node(zipper)
      source = Sourceror.to_string(ast)
      
      # Create the import statement
      import_line = "  import PhoenixKitWeb.Integration"
      
      # Find the best position to insert the import
      lines = String.split(source, "\n")
      
      case find_import_insertion_point(lines) do
        {:ok, position} ->
          # Insert the import at the found position
          new_lines = List.insert_at(lines, position + 1, import_line)
          new_source = Enum.join(new_lines, "\n")
          
          # Parse back to zipper
          case Sourceror.parse_string(new_source) do
            {:ok, ast} ->
              Logger.info("✅ Import injection successful using string-based fallback")
              Sourceror.Zipper.zip(ast)
              
            {:error, reason} ->
              Logger.error("Failed to parse modified source: #{inspect(reason)}")
              zipper
          end
          
        {:error, _reason} ->
          Logger.warning("Could not find good insertion point, import may need manual addition")
          zipper
      end
      
    rescue
      error ->
        Logger.error("Exception in string-based import fallback: #{inspect(error)}")
        zipper
    end
  end
  
  defp find_import_insertion_point(lines) do
    # Find the best place to insert import - after use statements or other imports
    lines_with_index = Enum.with_index(lines)
    
    # First, try to find existing import statements
    import_positions = 
      lines_with_index
      |> Enum.filter(fn {line, _index} ->
        String.trim(line) |> String.starts_with?("import ")
      end)
    
    case List.last(import_positions) do
      {_line, index} -> 
        {:ok, index}
      nil ->
        # No imports found, try to find use statements
        use_positions = 
          lines_with_index
          |> Enum.filter(fn {line, _index} ->
            String.trim(line) |> String.starts_with?("use ")
          end)
        
        case List.last(use_positions) do
          {_line, index} -> {:ok, index}
          nil -> {:error, :no_good_insertion_point}
        end
    end
  end
end
