defmodule Mix.Tasks.PhoenixKit.Install do
  @moduledoc """
  Igniter installer for PhoenixKit authentication system.

  This task automatically installs PhoenixKit into a Phoenix application by:
  1. Auto-detecting and configuring Ecto repo
  2. Setting up mailer configuration for development and production
  3. Modifying the router to include PhoenixKit routes

  ## Usage

  ```bash
  mix phoenix_kit.install
  ```

  With custom options:

  ```bash
  mix phoenix_kit.install --repo MyApp.Repo --router-path lib/my_app_web/router.ex
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
      example: "mix phoenix_kit.install --repo MyApp.Repo --prefix auth",
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
    |> create_or_upgrade_phoenix_kit_migration(opts)
    |> add_completion_notice()
  end

  # Add PhoenixKit configuration to config files
  defp add_phoenix_kit_configuration(igniter, custom_repo) do
    case find_or_detect_repo(igniter, custom_repo) do
      {igniter, nil} ->
        warning = """
        Could not determine application name or find Ecto repo automatically.

        Please specify with --repo option:

          mix phoenix_kit.install --repo YourApp.Repo

        Common repo names:
          - MyAppRepo, MyApp.Repo

        Or manually add to config/config.exs:

          config :phoenix_kit, repo: YourApp.Repo
        """

        Igniter.add_warning(igniter, warning)

      {igniter, repo_module} ->
        igniter
        # Add repo config to main config.exs
        |> Igniter.Project.Config.configure_new(
          "config.exs",
          :phoenix_kit,
          [:repo],
          repo_module
        )
        # Also add repo config to test.exs for testing
        |> Igniter.Project.Config.configure_new(
          "test.exs",
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
      adapter: Swoosh.Adapters.Local
    )
  end

  # Add notice about mailer configuration
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
    # Try multiple methods to find repos

    # Method 1: Use Igniter's Ecto lib
    case Igniter.Libs.Ecto.list_repos(igniter) do
      {igniter, [repo | _]} ->
        IO.puts("DEBUG: Found repo from Igniter.Libs.Ecto: #{inspect(repo)}")
        validate_postgres_adapter(igniter, repo)

      {igniter, []} ->
        IO.puts("DEBUG: No repos found via Igniter.Libs.Ecto")

        # Method 2: Try Application config directly
        parent_app_name = Mix.Project.config()[:app]
        IO.puts("DEBUG: Parent app name: #{inspect(parent_app_name)}")

        case Application.get_env(parent_app_name, :ecto_repos, []) do
          [repo | _] ->
            IO.puts("DEBUG: Found repo from Application config: #{inspect(repo)}")
            validate_postgres_adapter(igniter, repo)

          [] ->
            IO.puts("DEBUG: No repos in Application config, trying naming patterns")

            # Method 3: Try common naming patterns
            case parent_app_name do
              nil ->
                IO.puts("DEBUG: Parent app name is nil")
                {igniter, nil}

              app_name ->
                # Try most common pattern: AppName.Repo
                repo_module = Module.concat([Macro.camelize(to_string(app_name)), "Repo"])
                IO.puts("DEBUG: Trying repo module: #{inspect(repo_module)}")

                case Igniter.Project.Module.module_exists(igniter, repo_module) do
                  {true, igniter} ->
                    IO.puts("DEBUG: Found repo module: #{inspect(repo_module)}")
                    validate_postgres_adapter(igniter, repo_module)

                  {false, igniter} ->
                    IO.puts("DEBUG: Repo module does not exist: #{inspect(repo_module)}")
                    {igniter, nil}
                end
            end
        end
    end
  end

  defp find_or_detect_repo(igniter, repo_string) when is_binary(repo_string) do
    repo_module = Module.concat([repo_string])

    case Igniter.Project.Module.module_exists(igniter, repo_module) do
      {true, igniter} ->
        validate_postgres_adapter(igniter, repo_module)

      {false, igniter} ->
        Igniter.add_warning(igniter, "Specified repo #{repo_string} does not exist")
        {igniter, nil}
    end
  end

  # Validate that the repo uses PostgreSQL adapter
  defp validate_postgres_adapter(igniter, repo_module) do
    IO.puts("DEBUG: Validating PostgreSQL adapter for #{inspect(repo_module)}")

    # If Igniter.Libs.Ecto.list_repos found this repo, it's already valid
    # No need for complex AST parsing - trust Igniter's detection
    notice = """

    ℹ️  Database Configuration

    PhoenixKit will use #{inspect(repo_module)} as the database repository.
    Please ensure it's configured with PostgreSQL adapter:

      adapter: Ecto.Adapters.Postgres

    If you're using a different database (MySQL, SQLite), migration will fail.
    """

    igniter = Igniter.add_notice(igniter, notice)
    IO.puts("DEBUG: Repo #{inspect(repo_module)} validated successfully")
    {igniter, repo_module}
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
    # Check if this is the PhoenixKit library itself (not a real Phoenix app)
    case Igniter.Project.Application.app_name(igniter) do
      :phoenix_kit ->
        # This is the PhoenixKit library itself, skip router integration
        IO.puts("DEBUG: Detected PhoenixKit library project, skipping router integration")
        {igniter, nil}

      _ ->
        # This is a real Phoenix app, proceed with router selection
        Igniter.Libs.Phoenix.select_router(
          igniter,
          "Which router should be used for PhoenixKit routes?"
        )
    end
  end

  defp find_router(igniter, custom_path) do
    if File.exists?(custom_path) do
      # Try to extract module name from file content
      case extract_module_from_router_file(custom_path) do
        {:ok, module} ->
          # Verify the module exists in the project
          case Igniter.Project.Module.module_exists(igniter, module) do
            {true, igniter} ->
              {igniter, module}

            {false, igniter} ->
              Igniter.add_warning(
                igniter,
                "Module #{inspect(module)} extracted from #{custom_path} does not exist"
              )

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

      _ ->
        :error
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
       mix phoenix_kit.install

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
        Igniter.add_notice(
          igniter,
          "PhoenixKit routes already exist in router #{inspect(router_module)}, skipping."
        )

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

               :error ->
                 false
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
              {:warning,
               "Could not add import PhoenixKitWeb.Integration to router. Please add manually."}
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

  # Create or upgrade PhoenixKit migration file using Igniter best practices
  defp create_or_upgrade_phoenix_kit_migration(igniter, opts) do
    prefix = opts[:prefix] || "public"
    create_schema = opts[:create_schema] != false && prefix != "public"

    # Check if this is a new installation or existing installation
    case determine_migration_strategy(igniter, prefix) do
      {:new_install, igniter} ->
        create_initial_migration(igniter, prefix, create_schema)

      {:upgrade_needed, igniter, current_version, target_version} ->
        # Redirect to update task instead of handling upgrade here
        notice = """

        📦 PhoenixKit is already installed (V#{pad_version(current_version)}).

        To update to the latest version (V#{pad_version(target_version)}), please use:
          mix phoenix_kit.update#{if prefix != "public", do: " --prefix=#{prefix}", else: ""}

        To check current status:
          mix phoenix_kit.update --status#{if prefix != "public", do: " --prefix=#{prefix}", else: ""}
        """

        # Add notice early in pipeline so it appears first
        igniter = Igniter.add_notice(igniter, notice)

        # Return igniter without creating migration
        igniter

      {:up_to_date, igniter} ->
        # Redirect to update task for status check
        notice = """

        ✅ PhoenixKit is already installed and up to date.

        To check current status:
          mix phoenix_kit.update --status#{if prefix != "public", do: " --prefix=#{prefix}", else: ""}

        To force reinstall:
          mix phoenix_kit.update --force#{if prefix != "public", do: " --prefix=#{prefix}", else: ""}
        """

        Igniter.add_notice(igniter, notice)
        igniter

      {:error, igniter, reason} ->
        Igniter.add_warning(igniter, "Could not determine migration strategy: #{reason}")
        igniter
    end
  end

  # Determine whether this is a new install, upgrade, or already up to date
  defp determine_migration_strategy(igniter, _prefix) do
    case Igniter.Project.Application.app_name(igniter) do
      nil ->
        {:error, igniter, "Could not determine app name"}

      _app_name ->
        migrations_dir = Path.join(["priv", "repo", "migrations"])

        case find_phoenix_kit_migrations(migrations_dir) do
          [] ->
            # No existing PhoenixKit migrations
            {:new_install, igniter}

          _existing_migrations ->
            # Check current and target versions using proper DB method
            # Default prefix for install
            prefix = "public"
            opts = %{prefix: prefix, escaped_prefix: String.replace(prefix, "'", "\\'")}

            try do
              current_version = PhoenixKit.Migrations.Postgres.migrated_version(opts)
              target_version = PhoenixKit.Migrations.Postgres.current_version()

              cond do
                current_version < target_version ->
                  {:upgrade_needed, igniter, current_version, target_version}

                current_version >= target_version ->
                  {:up_to_date, igniter}
              end
            rescue
              _ ->
                # If DB not accessible but migration files exist, this is an update case
                # Migration files exist but haven't been run yet
                # No DB table = version 0
                current_version = 0
                target_version = PhoenixKit.Migrations.Postgres.current_version()
                {:upgrade_needed, igniter, current_version, target_version}
            end
        end
    end
  end

  # Create initial migration for new installation
  defp create_initial_migration(igniter, prefix, create_schema) do
    case Igniter.Project.Application.app_name(igniter) do
      nil ->
        Igniter.add_warning(igniter, "Could not determine app name for migration")

      app_name ->
        timestamp = generate_timestamp()
        migration_file = "#{timestamp}_add_phoenix_kit_auth_tables.exs"
        migration_path = Path.join(["priv", "repo", "migrations", migration_file])

        module_name =
          "#{Macro.camelize(to_string(app_name))}.Repo.Migrations.AddPhoenixKitAuthTables"

        migration_opts = migration_opts(prefix, create_schema)

        migration_content = """
        defmodule #{module_name} do
          use Ecto.Migration

          def up, do: PhoenixKit.Migrations.up(#{migration_opts})

          def down, do: PhoenixKit.Migrations.down(#{migration_opts})
        end
        """

        igniter = Igniter.create_new_file(igniter, migration_path, migration_content)

        notice = """

        📦 PhoenixKit Initial Installation Created:
        - Migration: #{migration_file}
        - This will install PhoenixKit version #{PhoenixKit.Migrations.Postgres.current_version()} (latest)

        Next steps:
          1. Run: mix ecto.migrate
          2. PhoenixKit will be ready to use!
        """

        Igniter.add_notice(igniter, notice)
    end
  end

  # Find all existing PhoenixKit migrations
  defp find_phoenix_kit_migrations(migrations_dir) do
    if File.dir?(migrations_dir) do
      migrations_dir
      |> File.ls!()
      |> Enum.filter(fn filename ->
        (String.contains?(filename, "phoenix_kit") ||
           String.contains?(filename, "add_phoenix_kit") ||
           String.contains?(filename, "upgrade_phoenix_kit")) &&
          String.ends_with?(filename, ".exs")
      end)
      |> Enum.map(&Path.join([migrations_dir, &1]))
    else
      []
    end
  rescue
    _ -> []
  end

  # Pad version number for consistent naming
  defp pad_version(version) when version < 10, do: "0#{version}"
  defp pad_version(version), do: to_string(version)

  # Generate migration options (same as phoenix_kit.install.ex)
  defp migration_opts("public", false), do: "[]"
  # public schema doesn't need create_schema
  defp migration_opts("public", true), do: "[]"

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
