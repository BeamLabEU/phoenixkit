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
  * `--prefix` - Specify PostgreSQL schema prefix (defaults to "public")
  * `--create-schema` - Create schema if using custom prefix (default: true for non-public prefixes)
  
  ## Auto-detection
  
  The installer will automatically:
  - Detect Ecto repo from `:ecto_repos` config or common naming patterns (MyApp.Repo)
  - Find main router using Phoenix conventions (MyAppWeb.Router)
  - Configure Swoosh.Adapters.Local for development in config/dev.exs
  - Provide production mailer setup instructions
  
  ## Note about warnings
  
  You may see a compiler warning about "unused import PhoenixKitWeb.Integration".
  This is normal behavior for Elixir macros and can be safely ignored.
  The `phoenix_kit_routes()` macro is properly used and will expand correctly.
  """

  @shortdoc "Install PhoenixKit authentication system into a Phoenix application"

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_kit,
      example: "mix phoenix_kit.install.igniter --repo MyApp.Repo --prefix auth",
      positional: [],
      schema: [
        router_path: :string,
        repo: :string,
        prefix: :string,
        create_schema: :boolean
      ],
      aliases: [
        r: :router_path,
        repo: :repo,
        p: :prefix
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
    |> create_phoenix_kit_migration(opts)
    |> add_completion_notice()
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
        warning = create_router_not_found_warning(custom_router_path)
        Igniter.add_warning(igniter, warning)

      {igniter, router_module} ->
        add_phoenix_kit_routes_to_router(igniter, router_module)
    end
  end

  # Find router using Igniter.Libs.Phoenix
  defp find_router(igniter, nil) do
    Igniter.Libs.Phoenix.select_router(igniter, "Which router should be used for PhoenixKit routes?")
  end
  
  defp find_router(igniter, custom_path) do
    if File.exists?(custom_path) do
      # Try to extract module name from file content
      case extract_module_from_router_file(custom_path) do
        {:ok, module} -> 
          # Verify the module exists in the project
          case Igniter.Project.Module.module_exists(igniter, module) do
            {true, igniter} -> {igniter, module}
            {false, igniter} -> 
              Igniter.add_warning(igniter, "Module #{inspect(module)} extracted from #{custom_path} does not exist")
              {igniter, nil}
          end
        :error -> 
          Igniter.add_warning(igniter, "Could not determine module name from #{custom_path}")
          {igniter, nil}
      end
    else
      Igniter.add_warning(igniter, "Router file not found at #{custom_path}")
      {igniter, nil}
    end
  end

  # Extract module name from router file content
  defp extract_module_from_router_file(path) do
    case File.read(path) do
      {:ok, content} ->
        case Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)/, content) do
          [_, module_name] -> {:ok, Module.concat([module_name])}
          _ -> :error
        end
      _ -> :error
    end
  end

  # Create comprehensive warning when router is not found
  defp create_router_not_found_warning(nil) do
    """
    🚨 Router Detection Failed

    PhoenixKit could not automatically detect your Phoenix router.
    
    📋 MANUAL SETUP REQUIRED:
    
    1. Open your main router file (usually lib/your_app_web/router.ex)
    
    2. Add the following lines to your router module:
    
       defmodule YourAppWeb.Router do
         use YourAppWeb, :router
         
         # Add this import
         import PhoenixKitWeb.Integration
         
         # Your existing pipelines and scopes...
         
         # Add this line at the end, before the final 'end'
         phoenix_kit_routes()
       end
    
    3. The routes will be available at:
       • /phoenix_kit/register - User registration
       • /phoenix_kit/login - User login  
       • /phoenix_kit/reset_password - Password reset
       • And other authentication routes
    
    📖 Common router locations:
       • lib/my_app_web/router.ex
       • lib/my_app/router.ex
       • apps/my_app_web/lib/my_app_web/router.ex (umbrella apps)
    
    ⚠️  Note: You may see a compiler warning about "unused import PhoenixKitWeb.Integration".
       This is normal behavior for Elixir macros and can be safely ignored.
       The phoenix_kit_routes() macro will expand correctly.
    
    💡 Need help? Check the PhoenixKit documentation or create an issue on GitHub.
    """
  end

  defp create_router_not_found_warning(custom_path) do
    """
    🚨 Router Not Found at Custom Path

    PhoenixKit could not find a router at the specified path: #{custom_path}
    
    📋 TROUBLESHOOTING STEPS:
    
    1. Verify the path exists and contains a valid Phoenix router
    2. Check file permissions (file must be readable)
    3. Ensure the file contains a proper Phoenix router module:
    
       defmodule YourAppWeb.Router do
         use YourAppWeb, :router
         # ... router content
       end
    
    📋 MANUAL SETUP (if file exists but couldn't be processed):
    
    Add the following to your router at #{custom_path}:
    
       # Add after 'use YourAppWeb, :router'
       import PhoenixKitWeb.Integration
       
       # Add before the final 'end'
       phoenix_kit_routes()
    
    🔄 ALTERNATIVE: Let PhoenixKit auto-detect your router:
    
    Run the installer without --router-path option:
       mix phoenix_kit.install.igniter
    
    ⚠️  Note: You may see a compiler warning about "unused import PhoenixKitWeb.Integration".
       This is normal for macros and can be safely ignored.
    
    💡 Need help? Check the PhoenixKit documentation or create an issue on GitHub.
    """
  end

  # Add PhoenixKit routes to router using proper Igniter API
  defp add_phoenix_kit_routes_to_router(igniter, router_module) do
    # Check if PhoenixKit routes already exist
    {_igniter, _source, zipper} = Igniter.Project.Module.find_module!(igniter, router_module)
    
    case Igniter.Code.Function.move_to_function_call(zipper, :phoenix_kit_routes, 0) do
      {:ok, _} ->
        # Routes already exist, add notice
        Igniter.add_notice(igniter, "PhoenixKit routes already exist in router #{inspect(router_module)}, skipping.")
        
      :error ->
        # Add import and routes call to router module
        igniter
        |> add_import_to_router_module(router_module)
        |> add_routes_call_to_router_module(router_module)
    end
  end

  # Add import PhoenixKitWeb.Integration to router
  defp add_import_to_router_module(igniter, router_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      # Check if import already exists
      case Igniter.Code.Function.move_to_function_call(zipper, :import, 1, fn call_zipper ->
        case Igniter.Code.Function.move_to_nth_argument(call_zipper, 0) do
          {:ok, arg_zipper} ->
            Igniter.Code.Common.nodes_equal?(arg_zipper, PhoenixKitWeb.Integration)
          :error -> false
        end
      end) do
        {:ok, _} ->
          # Import already exists
          {:ok, zipper}
          
        :error ->
          # Add import after use statement
          case Igniter.Libs.Phoenix.move_to_router_use(igniter, zipper) do
            {:ok, use_zipper} ->
              import_code = "import PhoenixKitWeb.Integration"
              {:ok, Igniter.Code.Common.add_code(use_zipper, import_code, placement: :after)}
              
            :error ->
              {:warning, "Could not add import PhoenixKitWeb.Integration to router. Please add manually."}
          end
      end
    end)
  end

  # Add phoenix_kit_routes() call to router
  defp add_routes_call_to_router_module(igniter, router_module) do
    Igniter.Project.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      routes_code = "phoenix_kit_routes()"
      {:ok, Igniter.Code.Common.add_code(zipper, routes_code, placement: :after)}
    end)
  end

  # Create PhoenixKit migration file using Igniter best practices
  defp create_phoenix_kit_migration(igniter, opts) do
    prefix = opts[:prefix] || "public"
    create_schema = opts[:create_schema] != false && prefix != "public"
    migration_name = "add_phoenix_kit_auth_tables"
    
    # Use Igniter to generate migration
    case create_ecto_migration(igniter, migration_name, prefix, create_schema) do
      {:ok, igniter} ->
        igniter
        
      {:exists, igniter} ->
        Igniter.add_notice(igniter, "PhoenixKit migration already exists, skipping creation.")
        igniter
        
      {:error, igniter, reason} ->
        Igniter.add_warning(igniter, "Could not create migration: #{reason}")
        igniter
    end
  end

  # Create Ecto migration using standard Igniter patterns
  defp create_ecto_migration(igniter, migration_name, prefix, create_schema) do
    case Igniter.Project.Application.app_name(igniter) do
      nil ->
        {:error, igniter, "Could not determine app name"}
        
      app_name ->
        # Check if migration already exists
        migrations_dir = Path.join(["priv", "repo", "migrations"])
        
        case find_existing_migration_file(migrations_dir, migration_name) do
          nil ->
            # No existing migration, create new one
            create_new_migration(igniter, app_name, migration_name, prefix, create_schema)
            
          existing_file ->
            # Migration exists, check if it's compatible
            check_existing_migration_compatibility(igniter, existing_file, prefix, create_schema)
        end
    end
  end

  # Create new migration file
  defp create_new_migration(igniter, app_name, migration_name, prefix, create_schema) do
    timestamp = generate_timestamp()
    migration_file = "#{timestamp}_#{migration_name}.exs"
    migration_path = Path.join(["priv", "repo", "migrations", migration_file])
    
    module_name = "#{Macro.camelize(to_string(app_name))}.Repo.Migrations.#{Macro.camelize(migration_name)}"
    
    migration_opts = migration_opts(prefix, create_schema)
    
    migration_content = """
    defmodule #{module_name} do
      use Ecto.Migration

      def up, do: PhoenixKit.Migrations.up(#{migration_opts})

      def down, do: PhoenixKit.Migrations.down(#{migration_opts})
    end
    """
    
    igniter = Igniter.create_new_file(igniter, migration_path, migration_content)
    {:ok, igniter}
  end

  # Find existing migration file with the same name pattern
  defp find_existing_migration_file(migrations_dir, migration_name) do
    if File.dir?(migrations_dir) do
      migrations_dir
      |> File.ls!()
      |> Enum.find(fn filename ->
        String.contains?(filename, migration_name) && String.ends_with?(filename, ".exs")
      end)
      |> case do
        nil -> nil
        filename -> Path.join([migrations_dir, filename])
      end
    else
      nil
    end
  rescue
    _ -> nil
  end

  # Check if existing migration is compatible with current options
  defp check_existing_migration_compatibility(igniter, existing_file, prefix, create_schema) do
    expected_opts = migration_opts(prefix, create_schema)
    
    case File.read(existing_file) do
      {:ok, content} ->
        expected_call = "PhoenixKit.Migrations.up(#{expected_opts})"
        
        if String.contains?(content, expected_call) do
          {:exists, igniter}
        else
          warning = """
          Existing migration #{Path.basename(existing_file)} has different options.
          Expected: #{expected_call}
          
          Please either:
          1. Remove the existing migration and re-run the installer
          2. Manually update the existing migration options
          """
          igniter = Igniter.add_warning(igniter, warning)
          {:exists, igniter}
        end
        
      {:error, _} ->
        {:error, igniter, "Cannot read existing migration file"}
    end
  end


  # Generate migration options (same as phoenix_kit.install.ex)
  defp migration_opts("public", false), do: ""
  defp migration_opts(prefix, create_schema) when is_binary(prefix) do
    opts = [prefix: prefix]
    opts = if create_schema, do: Keyword.put(opts, :create_schema, true), else: opts
    inspect(opts)  
  end

  # Generate timestamp (same as phoenix_kit.install.ex)
  defp generate_timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  # Add completion notice with next steps
  defp add_completion_notice(igniter) do
    notice = """
    
    🎉 PhoenixKit installation complete!
    
    Next steps:
      1. Run: mix ecto.migrate
      2. Start your Phoenix server: mix phx.server
      3. Visit /phoenix_kit/register to test user registration
    
    📚 Visit /phoenix_kit routes for complete authentication system:
      - User registration and login
      - Password reset and email confirmation  
      - User settings and profile management
    
    ⚡ PhoenixKit routes work independently of your app's browser pipeline
       and are automatically configured for LiveView forms.
    """
    
    Igniter.add_notice(igniter, notice)
  end

end