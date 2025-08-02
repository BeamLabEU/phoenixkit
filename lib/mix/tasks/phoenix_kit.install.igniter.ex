defmodule Mix.Tasks.PhoenixKit.Install.Igniter do
  @moduledoc """
  Igniter installer for PhoenixKit authentication system.

  This task automatically installs PhoenixKit into a Phoenix application by:
  1. Auto-detecting and configuring Ecto repo
  2. Setting up mailer configuration for development and production
  3. Modifying the router to include PhoenixKit routes

  ## Usage

  ```bash
  mix phoenix_kit.install.igniter
  ```

  With custom options:

  ```bash
  mix phoenix_kit.install.igniter --repo MyApp.Repo --router-path lib/my_app_web/router.ex
  ```

  ## Options

  * `--repo` - Specify Ecto repo module (auto-detected if not provided)
  * `--router-path` - Specify custom path to router.ex file
  
  ## Auto-detection
  
  The installer will automatically:
  - Detect Ecto repo from `:ecto_repos` config or common naming patterns (MyApp.Repo)
  - Find main router using Phoenix conventions (MyAppWeb.Router)
  - Configure Swoosh.Adapters.Local for development in config/dev.exs
  - Provide production mailer setup instructions
  
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
      example: "mix phoenix_kit.install.igniter --repo MyApp.Repo",
      positional: [],
      schema: [
        router_path: :string,
        repo: :string
      ],
      aliases: [
        r: :router_path,
        repo: :repo
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    opts = igniter.args.options
    
    igniter
    |> add_phoenix_kit_configuration(opts[:repo])
    |> add_mailer_configuration()
    |> add_router_integration(opts[:router_path])
  end

  # Add PhoenixKit configuration to config/config.exs
  defp add_phoenix_kit_configuration(igniter, custom_repo) do
    case find_or_detect_repo(igniter, custom_repo) do
      {igniter, nil} ->
        warning = """
        Could not determine application name or find Ecto repo automatically.
        
        Please specify with --repo option:
        
          mix phoenix_kit.install.igniter --repo YourApp.Repo
          
        Common repo names:
          - ZenclockRepo, Zenclock.Repo
          - MyAppRepo, MyApp.Repo
          
        Or manually add to config/config.exs:
        
          config :phoenix_kit, repo: YourApp.Repo
        """
        Igniter.add_warning(igniter, warning)
        
      {igniter, repo_module} ->
        # Use configure_new to avoid duplicating existing config
        Igniter.Project.Config.configure_new(
          igniter,
          "config.exs",
          :phoenix_kit,
          [:repo],
          repo_module
        )
    end
  end

  # Add PhoenixKit mailer configuration 
  defp add_mailer_configuration(igniter) do
    igniter
    |> add_dev_mailer_config()
    |> add_mailer_production_notice()
  end

  # Add Local mailer adapter for development
  defp add_dev_mailer_config(igniter) do
    Igniter.Project.Config.configure_new(
      igniter,
      "dev.exs", 
      :phoenix_kit,
      [PhoenixKit.Mailer],
      [adapter: Swoosh.Adapters.Local]
    )
  end

  # Add notice about production mailer configuration
  defp add_mailer_production_notice(igniter) do
    notice = """
    
    📧 Mailer Configuration Added:
    - Development: Swoosh.Adapters.Local (emails shown in browser)
    
    ⚠️  IMPORTANT: Without mailer configuration, user registration will fail!
    
    For production, configure appropriate adapter in config/prod.exs:
    
      # Example with SMTP
      config :phoenix_kit, PhoenixKit.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: "smtp.gmail.com",
        username: System.get_env("SMTP_USERNAME"),
        password: System.get_env("SMTP_PASSWORD")
    
      # Or cloud services: SendGrid, Mailgun, Postmark, etc.
    """
    
    Igniter.add_notice(igniter, notice)
  end

  # Find specified repo or auto-detect from project
  defp find_or_detect_repo(igniter, nil) do
    # Auto-detect repo from ecto_repos configuration
    case Igniter.Libs.Ecto.list_repos(igniter) do
      {igniter, []} ->
        # Try multiple fallback methods to find repo
        case auto_detect_repo_by_name(igniter) do
          {igniter, nil} ->
            auto_detect_repo_by_scanning(igniter)
          {igniter, repo} ->
            {igniter, repo}
        end
        
      {igniter, [repo | _]} ->
        # Use first repo found
        {igniter, repo}
    end
  end
  
  defp find_or_detect_repo(igniter, repo_string) when is_binary(repo_string) do
    repo_module = Module.concat([repo_string])
    
    case Igniter.Project.Module.module_exists(igniter, repo_module) do
      {true, igniter} ->
        {igniter, repo_module}
        
      {false, igniter} ->
        Igniter.add_warning(igniter, "Specified repo #{repo_string} does not exist")
        {igniter, nil}
    end
  end

  # Try to auto-detect repo by common naming patterns
  defp auto_detect_repo_by_name(igniter) do
    case Igniter.Project.Application.app_name(igniter) do
      nil ->
        # Can't determine app name, skip this method
        {igniter, nil}
        
      app_name ->
        # Try common repo patterns
        repo_patterns = [
          Module.concat([Macro.camelize(to_string(app_name)), "Repo"]),
          Module.concat([Macro.camelize(to_string(app_name)) <> "Web", "Repo"]),
          Module.concat([Macro.camelize(to_string(app_name)), "Data", "Repo"])
        ]
        
        find_existing_repo(igniter, repo_patterns)
    end
  end

  # Try to auto-detect repo by scanning project files
  defp auto_detect_repo_by_scanning(igniter) do
    # Look for modules that use Ecto.Repo
    {igniter, all_modules} = Igniter.Project.Module.find_all_matching_modules(igniter, fn _module, zipper ->
      case Igniter.Code.Module.move_to_use(zipper, Ecto.Repo) do
        {:ok, _} -> true
        :error -> false
      end
    end)
    
    case all_modules do
      [] ->
        {igniter, nil}
      [repo | _] ->
        {igniter, repo}
    end
  end

  # Helper to find existing repo from patterns
  defp find_existing_repo(igniter, []), do: {igniter, nil}
  defp find_existing_repo(igniter, [repo_module | rest]) do
    case Igniter.Project.Module.module_exists(igniter, repo_module) do
      {true, igniter} ->
        {igniter, repo_module}
      {false, igniter} ->
        find_existing_repo(igniter, rest)
    end
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