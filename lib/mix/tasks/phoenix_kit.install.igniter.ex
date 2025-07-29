defmodule Mix.Tasks.PhoenixKit.Install.Igniter do
  @moduledoc """
  Igniter installer for PhoenixKit authentication system.

  This task automatically installs PhoenixKit into a Phoenix application by:
  1. Modifying the router to include PhoenixKit routes

  ## Usage

  ```bash
  mix phoenix_kit.install.igniter
  ```

  Or with custom router path:

  ```bash
  mix phoenix_kit.install.igniter --router-path lib/my_app_web/router.ex
  ```

  ## Options

  * `--router-path` - Specify custom path to router.ex file
  
  ## Note about warnings
  
  You may see a compiler warning about "unused import PhoenixKitWeb.Integration".
  This is normal behavior for Elixir macros and can be safely ignored.
  The `phoenix_kit_auth_routes()` macro is properly used and will expand correctly.
  """

  @shortdoc "Install PhoenixKit authentication system into a Phoenix application"

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_kit,
      example: "mix phoenix_kit.install.igniter",
      positional: [],
      schema: [
        router_path: :string
      ],
      aliases: [
        r: :router_path
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    opts = igniter.args.options
    
    igniter
    |> add_router_integration(opts[:router_path])
  end

  # Add PhoenixKit integration to router
  defp add_router_integration(igniter, custom_router_path) do
    case find_router(igniter, custom_router_path) do
      {igniter, nil} ->
        warning = """
        Could not find router. Please manually add the following to your router:

          import PhoenixKitWeb.Integration
          phoenix_kit_auth_routes()

        Note: You may see a warning about unused import - this is normal for macros.
        """
        Igniter.add_warning(igniter, warning)

      {igniter, router_module} ->
        modify_router(igniter, router_module)
    end
  end

  # Find router using Igniter.Libs.Phoenix or custom path
  defp find_router(igniter, nil) do
    case Igniter.Libs.Phoenix.list_routers(igniter) do
      {igniter, []} ->
        {igniter, nil}
      
      {igniter, routers} ->
        # Filter out PhoenixKit internal routers
        user_routers = Enum.reject(routers, fn router ->
          router_name = to_string(router)
          String.contains?(router_name, "PhoenixKit") or String.contains?(router_name, "PhoenixKitWeb")
        end)
        
        case user_routers do
          [] -> {igniter, nil}
          [router | _] -> {igniter, router}
        end
    end
  end
  
  defp find_router(igniter, custom_path) do
    if File.exists?(custom_path) do
      # Try to extract module name from file
      case extract_module_from_file(custom_path) do
        {:ok, module} -> {igniter, module}
        :error -> 
          Igniter.add_warning(igniter, "Could not determine module name from #{custom_path}")
          {igniter, nil}
      end
    else
      Igniter.add_warning(igniter, "Router file not found at #{custom_path}")
      {igniter, nil}
    end
  end

  # Extract module name from router file
  defp extract_module_from_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)/, content) do
          [_, module_name] -> {:ok, Module.concat([module_name])}
          _ -> :error
        end
      _ -> :error
    end
  end

  # Modify the router using proper Igniter API
  defp modify_router(igniter, router_module) do
    igniter
    |> add_import_to_router(router_module)
    |> add_routes_to_router(router_module)
  end

  # Add import statement to router
  defp add_import_to_router(igniter, router_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      case check_import_exists(zipper) do
        true ->
          # Import already exists, do nothing
          {:ok, zipper}
        
        false ->
          # Add import after use statement
          case add_import_after_use(zipper) do
            {:ok, updated_zipper} -> {:ok, updated_zipper}
            :error -> 
              {:warning, "Could not add import PhoenixKitWeb.Integration to router. Please add manually."}
          end
      end
    end)
  end

  # Add routes call to router
  defp add_routes_to_router(igniter, router_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      case check_routes_call_exists(zipper) do
        true ->
          # Routes call already exists, do nothing
          {:ok, zipper}
        
        false ->
          # Add routes call before last end
          {:ok, updated_zipper} = add_routes_before_last_end(zipper)
          {:ok, updated_zipper}
      end
    end)
  end

  # Check if import PhoenixKitWeb.Integration already exists
  defp check_import_exists(zipper) do
    Igniter.Code.Function.move_to_function_call(zipper, :import, 1, fn call_zipper ->
      case Igniter.Code.Function.move_to_nth_argument(call_zipper, 0) do
        {:ok, arg_zipper} ->
          Igniter.Code.Common.nodes_equal?(arg_zipper, PhoenixKitWeb.Integration)
        :error -> false
      end
    end)
    |> case do
      {:ok, _} -> true
      :error -> false
    end
  end

  # Check if phoenix_kit_auth_routes() call already exists
  defp check_routes_call_exists(zipper) do
    Igniter.Code.Function.move_to_function_call(zipper, :phoenix_kit_auth_routes, 0)
    |> case do
      {:ok, _} -> true
      :error -> false
    end
  end

  # Add import after use statement  
  defp add_import_after_use(zipper) do
    with {:ok, use_zipper} <- Igniter.Libs.Phoenix.move_to_router_use(Igniter.new(), zipper) do
      import_code = "import PhoenixKitWeb.Integration"
      {:ok, Igniter.Code.Common.add_code(use_zipper, import_code, placement: :after)}
    end
  end

  # Add routes call before the last end of the module
  defp add_routes_before_last_end(zipper) do
    routes_code = "phoenix_kit_auth_routes()"
    
    # Simply add the code at the end of the module
    {:ok, Igniter.Code.Common.add_code(zipper, routes_code, placement: :after)}
  end

end