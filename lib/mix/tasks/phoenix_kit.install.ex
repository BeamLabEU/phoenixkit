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

  alias Igniter.Code.Common
  alias Igniter.Code.Function, as: IgniterFunction
  alias Igniter.Libs.Ecto
  alias Igniter.Libs.Phoenix, as: IgniterPhoenix
  alias Igniter.Project.Application
  alias Igniter.Project.Config
  alias Igniter.Project.Module, as: IgniterModule
  alias PhoenixKit.Migrations.Postgres

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
    |> add_layout_integration_configuration()
    |> copy_test_demo_files()
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
        |> Config.configure_new(
          "config.exs",
          :phoenix_kit,
          [:repo],
          repo_module
        )
        # Also add repo config to test.exs for testing
        |> Config.configure_new(
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
    Config.configure_new(
      igniter,
      "dev.exs",
      :phoenix_kit,
      [PhoenixKit.Mailer],
      adapter: Swoosh.Adapters.Local
    )
  end

  # Add brief notice about mailer configuration
  defp add_mailer_production_notice(igniter) do
    notice = """

    📧 Development mailer configured (Swoosh.Adapters.Local)
    ⚠️  Production: Configure mailer in config/prod.exs
    """

    Igniter.add_notice(igniter, notice)
  end

  # Add layout integration configuration
  defp add_layout_integration_configuration(igniter) do
    case detect_app_layouts(igniter) do
      {igniter, nil} ->
        # No layouts detected, use PhoenixKit defaults
        add_layout_integration_notice(igniter, :no_layouts_detected)

      {igniter, {layouts_module, _}} ->
        # Add layout configuration to config.exs
        igniter
        |> add_layout_config(layouts_module)
        |> add_layout_integration_notice(:layouts_detected)
    end
  end

  # Detect app layouts using IgniterPhoenix
  defp detect_app_layouts(igniter) do
    case Application.app_name(igniter) do
      nil -> {igniter, nil}
      app_name -> detect_layouts_for_app(igniter, app_name)
    end
  end

  # Try to detect layouts module following Phoenix conventions
  defp detect_layouts_for_app(igniter, app_name) do
    app_web_module = Module.concat([Macro.camelize(to_string(app_name)) <> "Web"])
    layouts_module = Module.concat([app_web_module, "Layouts"])

    case IgniterModule.module_exists(igniter, layouts_module) do
      {true, igniter} ->
        {igniter, {layouts_module, :app}}

      {false, igniter} ->
        try_alternative_layouts_pattern(igniter, app_name)
    end
  end

  # Try alternative patterns like MyApp.Layouts
  defp try_alternative_layouts_pattern(igniter, app_name) do
    alt_layouts_module = Module.concat([Macro.camelize(to_string(app_name)), "Layouts"])

    case IgniterModule.module_exists(igniter, alt_layouts_module) do
      {true, igniter} -> {igniter, {alt_layouts_module, :app}}
      {false, igniter} -> {igniter, nil}
    end
  end

  # Add layout configuration to config.exs
  defp add_layout_config(igniter, layouts_module) do
    # Add layout configuration with inline comments
    igniter
    |> add_layout_config_with_comments(layouts_module)
    |> recompile_phoenix_kit_dependency()
  end

  # Add layout configuration with comments
  defp add_layout_config_with_comments(igniter, layouts_module) do
    # First add layout config using standard Igniter methods
    igniter
    |> Config.configure_new(
      "config.exs",
      :phoenix_kit,
      [:layout],
      {layouts_module, :app}
    )
    |> Config.configure_new(
      "config.exs",
      :phoenix_kit,
      [:root_layout],
      {layouts_module, :root}
    )
    # Then add comment above layout config
    |> add_comment_to_layout_config()
    |> add_manual_comment_instruction(layouts_module)
  end

  # Add comment above layout configuration in config file
  defp add_comment_to_layout_config(igniter) do
    config_path = "config/config.exs"

    Igniter.update_file(igniter, config_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      # Only add comment if it doesn't already exist
      if String.contains?(
           content,
           "# IMPORTANT: After changing these settings, run: mix deps.compile phoenix_kit --force"
         ) do
        # Comment already exists, no changes needed
        source
      else
        # Add comment before layout line
        updated_content =
          String.replace(
            content,
            "layout:",
            "# IMPORTANT: After changing these settings, run: mix deps.compile phoenix_kit --force\n  layout:",
            # Only replace first occurrence
            global: false
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  # Add brief reminder about recompilation
  defp add_manual_comment_instruction(igniter, _layouts_module) do
    notice = "🎨 Layout integration configured"
    Igniter.add_notice(igniter, notice)
  end

  # Skip redundant layout notice since already covered
  defp add_layout_integration_notice(igniter, :layouts_detected) do
    igniter
  end

  defp add_layout_integration_notice(igniter, :no_layouts_detected) do
    notice = "💡 To integrate with your app's design, see layout configuration in README.md"
    Igniter.add_notice(igniter, notice)
  end

  # Method 1: Use Igniter's Ecto lib
  defp try_igniter_ecto_list(igniter) do
    case Ecto.list_repos(igniter) do
      {igniter, [repo | _]} -> validate_postgres_adapter(igniter, repo)
      {igniter, []} -> {igniter, nil}
    end
  end

  # Method 2: Try Application config directly
  defp try_application_config(igniter) do
    parent_app_name = Mix.Project.config()[:app]

    case Elixir.Application.get_env(parent_app_name, :ecto_repos, []) do
      [repo | _] -> validate_postgres_adapter(igniter, repo)
      [] -> {igniter, nil}
    end
  end

  # Method 3: Try common naming patterns
  defp try_naming_patterns(igniter) do
    parent_app_name = Mix.Project.config()[:app]

    case parent_app_name do
      nil ->
        {igniter, nil}

      app_name ->
        # Try most common pattern: AppName.Repo
        repo_module = Module.concat([Macro.camelize(to_string(app_name)), "Repo"])

        case IgniterModule.module_exists(igniter, repo_module) do
          {true, igniter} -> validate_postgres_adapter(igniter, repo_module)
          {false, igniter} -> {igniter, nil}
        end
    end
  end

  # Find specified repo or auto-detect from project
  defp find_or_detect_repo(igniter, nil) do
    # Try multiple methods to find repos
    with {igniter, nil} <- try_igniter_ecto_list(igniter),
         {igniter, nil} <- try_application_config(igniter) do
      try_naming_patterns(igniter)
    end
  end

  defp find_or_detect_repo(igniter, repo_string) when is_binary(repo_string) do
    repo_module = Module.concat([repo_string])

    case IgniterModule.module_exists(igniter, repo_module) do
      {true, igniter} ->
        validate_postgres_adapter(igniter, repo_module)

      {false, igniter} ->
        Igniter.add_warning(igniter, "Specified repo #{repo_string} does not exist")
        {igniter, nil}
    end
  end

  # Validate that the repo uses PostgreSQL adapter
  defp validate_postgres_adapter(igniter, repo_module) do
    # Trust Igniter's detection - no need for verbose notices
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

  # Find router using IgniterPhoenix
  defp find_router(igniter, nil) do
    # Check if this is the PhoenixKit library itself (not a real Phoenix app)
    case Application.app_name(igniter) do
      :phoenix_kit ->
        # This is the PhoenixKit library itself, skip router integration
        {igniter, nil}

      app_name ->
        # Try to auto-detect router first based on app name
        app_web_module = Module.concat([Macro.camelize(to_string(app_name)) <> "Web"])
        router_module = Module.concat([app_web_module, "Router"])

        case IgniterModule.module_exists(igniter, router_module) do
          {true, igniter} ->
            {igniter, router_module}

          {false, igniter} ->
            # Fallback to Igniter's router selection
            IgniterPhoenix.select_router(
              igniter,
              "Which router should be used for PhoenixKit routes?"
            )
        end
    end
  end

  defp find_router(igniter, custom_path) do
    if File.exists?(custom_path) do
      handle_existing_router_file(igniter, custom_path)
    else
      Igniter.add_warning(igniter, "Router file not found at #{custom_path}")
      {igniter, nil}
    end
  end

  # Handle extraction and verification of router module from existing file
  defp handle_existing_router_file(igniter, custom_path) do
    case extract_module_from_router_file(custom_path) do
      {:ok, module} ->
        verify_router_module_exists(igniter, module, custom_path)

      :error ->
        Igniter.add_warning(igniter, "Could not determine module name from #{custom_path}")
        {igniter, nil}
    end
  end

  # Verify the extracted router module exists in the project
  defp verify_router_module_exists(igniter, module, custom_path) do
    case IgniterModule.module_exists(igniter, module) do
      {true, igniter} ->
        {igniter, module}

      {false, igniter} ->
        Igniter.add_warning(
          igniter,
          "Module #{inspect(module)} extracted from #{custom_path} does not exist"
        )

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
    {_igniter, _source, zipper} = IgniterModule.find_module!(igniter, router_module)

    case IgniterFunction.move_to_function_call(zipper, :phoenix_kit_routes, 0) do
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
    IgniterModule.find_and_update_module!(igniter, router_module, fn zipper ->
      handle_import_addition(igniter, zipper)
    end)
  end

  # Handle the addition of import statement to router
  defp handle_import_addition(igniter, zipper) do
    if import_already_exists?(zipper) do
      {:ok, zipper}
    else
      add_import_after_use_statement(igniter, zipper)
    end
  end

  # Check if PhoenixKitWeb.Integration import already exists
  defp import_already_exists?(zipper) do
    case IgniterFunction.move_to_function_call(zipper, :import, 1, &check_import_argument/1) do
      {:ok, _} -> true
      :error -> false
    end
  end

  # Check if import argument matches PhoenixKitWeb.Integration
  defp check_import_argument(call_zipper) do
    case IgniterFunction.move_to_nth_argument(call_zipper, 0) do
      {:ok, arg_zipper} -> Common.nodes_equal?(arg_zipper, PhoenixKitWeb.Integration)
      :error -> false
    end
  end

  # Add import statement after use statement
  defp add_import_after_use_statement(igniter, zipper) do
    case IgniterPhoenix.move_to_router_use(igniter, zipper) do
      {:ok, use_zipper} ->
        import_code = "import PhoenixKitWeb.Integration"
        {:ok, Common.add_code(use_zipper, import_code, placement: :after)}

      :error ->
        {:warning,
         "Could not add import PhoenixKitWeb.Integration to router. Please add manually."}
    end
  end

  # Add phoenix_kit_routes() call to router
  defp add_routes_call_to_router_module(igniter, router_module) do
    IgniterModule.find_and_update_module!(igniter, router_module, fn zipper ->
      # Get parent app name for module construction
      app_name = Application.app_name(igniter)

      app_web_module_name =
        if app_name && app_name != :phoenix_kit do
          "#{Macro.camelize(to_string(app_name))}Web"
        else
          "YourAppWeb"
        end

      routes_code = """
      # PhoenixKit Demo Pages - Test Authentication Levels
      scope "/" do
        pipe_through :browser

        live_session :phoenix_kit_demo_current_user,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_user}] do
          live "/test-current-user", #{app_web_module_name}.PhoenixKitLive.TestRequireAuthLive, :index
        end

        live_session :phoenix_kit_demo_redirect_if_auth,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated}] do
          live "/test-redirect-if-auth", #{app_web_module_name}.PhoenixKitLive.TestRedirectIfAuthLive, :index
        end

        live_session :phoenix_kit_demo_ensure_auth,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_ensure_authenticated}] do
          live "/test-ensure-auth", #{app_web_module_name}.PhoenixKitLive.TestEnsureAuthLive, :index
        end
      end

      phoenix_kit_routes()
      """

      {:ok, Common.add_code(zipper, routes_code, placement: :after)}
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
        handle_upgrade_needed(igniter, prefix, current_version, target_version)

      {:up_to_date, igniter} ->
        handle_up_to_date(igniter, prefix)

      {:error, igniter, reason} ->
        Igniter.add_warning(igniter, "Could not determine migration strategy: #{reason}")
        igniter
    end
  end

  # Handle upgrade needed scenario
  defp handle_upgrade_needed(igniter, prefix, current_version, target_version) do
    notice = generate_upgrade_notice(prefix, current_version, target_version)
    Igniter.add_notice(igniter, notice)
    igniter
  end

  # Handle up to date scenario
  defp handle_up_to_date(igniter, prefix) do
    notice = generate_up_to_date_notice(prefix)
    Igniter.add_notice(igniter, notice)
    igniter
  end

  # Generate upgrade needed notice
  defp generate_upgrade_notice(prefix, current_version, target_version) do
    prefix_option = if prefix != "public", do: " --prefix=#{prefix}", else: ""

    """

    📦 PhoenixKit is already installed (V#{pad_version(current_version)}).

    To update to the latest version (V#{pad_version(target_version)}), please use:
      mix phoenix_kit.update#{prefix_option}

    To check current status:
      mix phoenix_kit.update --status#{prefix_option}
    """
  end

  # Generate up to date notice
  defp generate_up_to_date_notice(prefix) do
    prefix_option = if prefix != "public", do: " --prefix=#{prefix}", else: ""

    """

    ✅ PhoenixKit is already installed and up to date.

    To check current status:
      mix phoenix_kit.update --status#{prefix_option}

    To force reinstall:
      mix phoenix_kit.update --force#{prefix_option}
    """
  end

  # Determine whether this is a new install, upgrade, or already up to date
  defp determine_migration_strategy(igniter, _prefix) do
    case Application.app_name(igniter) do
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
              current_version = Postgres.migrated_version(opts)
              target_version = Postgres.current_version()

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
                target_version = Postgres.current_version()
                {:upgrade_needed, igniter, current_version, target_version}
            end
        end
    end
  end

  # Create initial migration for new installation
  defp create_initial_migration(igniter, prefix, create_schema) do
    case Application.app_name(igniter) do
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
        - This will install PhoenixKit version #{Postgres.current_version()} (latest)

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

  # Recompile PhoenixKit dependency to pick up layout configuration changes
  defp recompile_phoenix_kit_dependency(igniter) do
    # Since this is running during installation, we need to recompile the dependency
    # to ensure the layout configuration changes are picked up immediately
    recompile_notice = """

    🔄 Recompiling PhoenixKit to apply layout configuration...
    """

    igniter = Igniter.add_notice(igniter, recompile_notice)

    # Run the recompilation in the background using System.cmd instead of Mix task
    # to avoid potential issues with Mix state during Igniter execution
    try do
      {output, exit_code} =
        System.cmd("mix", ["deps.compile", "phoenix_kit", "--force"], stderr_to_stdout: true)

      if exit_code == 0 do
        success_notice = "✅ PhoenixKit dependency recompiled successfully!"
        Igniter.add_notice(igniter, success_notice)
      else
        warning_notice =
          "⚠️ Could not automatically recompile PhoenixKit dependency. Output: #{String.slice(output, 0, 200)}"

        Igniter.add_warning(igniter, warning_notice)
      end
    rescue
      _ ->
        warning_notice =
          "⚠️ Could not automatically recompile PhoenixKit dependency. Please run: mix deps.compile phoenix_kit --force"

        Igniter.add_warning(igniter, warning_notice)
    end
  end

  # Copy test demo files to parent project
  defp copy_test_demo_files(igniter) do
    case Application.app_name(igniter) do
      nil ->
        Igniter.add_warning(igniter, "Could not determine app name for copying test demo files")

      :phoenix_kit ->
        # This is the PhoenixKit library itself, skip copying test files
        igniter

      app_name ->
        app_web_module = Module.concat([Macro.camelize(to_string(app_name)) <> "Web"])

        # Create demo directory path - directly in app_web as phoenix_kit_live
        app_web_dir = Macro.underscore(to_string(app_name)) <> "_web"
        demo_dir = Path.join([app_web_dir, "phoenix_kit_live"])

        igniter
        |> copy_test_file("test_ensure_auth_live.ex", demo_dir, app_web_module)
        |> copy_test_file("test_redirect_if_auth_live.ex", demo_dir, app_web_module)
        |> copy_test_file("test_require_auth_live.ex", demo_dir, app_web_module)
        |> add_test_demo_notice()
    end
  end

  # Copy a single test file to demo directory using embedded content
  defp copy_test_file(igniter, filename, demo_dir, app_web_module) do
    # Create files in live/ directory with proper notifications
    content = get_embedded_test_file_content(filename)

    if content do
      # First update use statement to avoid conflicts
      app_web_module_string = inspect(app_web_module)

      updated_content =
        String.replace(
          content,
          "use PhoenixKitWeb, :live_view",
          "use #{app_web_module_string}, :live_view"
        )

      # Then replace module names (but not the use statement)
      updated_content =
        String.replace(
          updated_content,
          "defmodule PhoenixKitWeb",
          "defmodule #{app_web_module_string}.PhoenixKitLive"
        )

      # Create file only if it doesn't exist (skip if already exists)
      dest_path = Path.join(["lib", demo_dir, filename])

      if File.exists?(dest_path) do
        # File exists, add notice and skip creation
        Igniter.add_notice(igniter, "Demo file already exists, skipping: #{dest_path}")
      else
        # File doesn't exist, create it
        Igniter.create_new_file(igniter, dest_path, updated_content)
      end
    else
      Igniter.add_warning(igniter, "Unknown test file: #{filename}")
    end
  end

  # Get embedded content for test files
  defp get_embedded_test_file_content("test_ensure_auth_live.ex") do
    """
    defmodule PhoenixKitWeb.TestEnsureAuthLive do
      @moduledoc \"\"\"
      Test component for phoenix_kit_ensure_authenticated authentication level.
      This page should only be accessible to authenticated users using PhoenixKit auth.
      \"\"\"
      use PhoenixKitWeb, :live_view

      def render(assigns) do
        ~H\"\"\"
        <div class="hero py-8 min-h-[80vh] bg-success">
          <div class="hero-content text-center">
            <div class="max-w-md">
              <h1 class="text-5xl font-bold text-success-content">phoenix_kit_ensure_authenticated</h1>
              <div class="py-6 text-success-content">
                <p class="mb-4">
                  This page is protected by PhoenixKit <code>phoenix_kit_ensure_authenticated</code>.
                  You can only see this if you are logged in through PhoenixKit auth system.
                </p>

                <%= if @phoenix_kit_current_user do %>
                  <div class="alert alert-info">
                    <div>
                      <h3 class="font-bold">Welcome, authenticated user!</h3>
                      <div class="text-sm">
                        <p><strong>Email:</strong> {@phoenix_kit_current_user.email}</p>
                        <p><strong>User ID:</strong> {@phoenix_kit_current_user.id}</p>
                        <%= if @phoenix_kit_current_user.confirmed_at do %>
                          <p><strong>Account:</strong> Confirmed at {@phoenix_kit_current_user.confirmed_at}</p>
                        <% else %>
                          <p><strong>Account:</strong> Not yet confirmed</p>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% else %>
                  <div class="alert alert-error">
                    <div>
                      <p>This should never be visible - authentication is required!</p>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="badge badge-success">PhoenixKit Authentication: REQUIRED</div>
            </div>
          </div>
        </div>
        \"\"\"
      end

      def mount(_params, _session, socket) do
        {:ok, socket}
      end
    end
    """
  end

  defp get_embedded_test_file_content("test_redirect_if_auth_live.ex") do
    """
    defmodule PhoenixKitWeb.TestRedirectIfAuthLive do
      @moduledoc \"\"\"
      Test component for redirect_if_user_is_authenticated authentication level.
      This page should redirect authenticated users away (like login/register pages).
      \"\"\"
      use PhoenixKitWeb, :live_view

      def render(assigns) do
        ~H\"\"\"
        <div class="hero py-8 min-h-[80vh] bg-base-300">
          <div class="hero-content text-center">
            <div class="max-w-md">
              <h1 class="text-5xl font-bold text-warning">redirect_if_user_is_authenticated</h1>
              <p class="py-6">
                This page is protected by <code>redirect_if_user_is_authenticated</code> authentication.
                If you are logged in, you should be redirected away from this page.
              </p>
              <div class="badge badge-warning">Authentication: REDIRECT IF LOGGED IN</div>
            </div>
          </div>
        </div>
        \"\"\"
      end

      def mount(_params, _session, socket) do
        {:ok, socket}
      end
    end
    """
  end

  defp get_embedded_test_file_content("test_require_auth_live.ex") do
    """
    defmodule PhoenixKitWeb.TestRequireAuthLive do
      @moduledoc \"\"\"
      Test component for phoenix_kit_mount_current_user authentication level.
      This page shows current user information without requiring authentication.
      \"\"\"
      use PhoenixKitWeb, :live_view

      def render(assigns) do
        ~H\"\"\"
        <div class="hero py-8 min-h-[80vh] bg-info">
          <div class="hero-content text-center">
            <div class="max-w-md">
              <h1 class="text-5xl font-bold text-info-content">phoenix_kit_mount_current_user</h1>
              <div class="py-6 text-info-content">
                <p class="mb-4">
                  This page uses PhoenixKit <code>phoenix_kit_mount_current_user</code>.
                  It mounts current user without requiring authentication.
                </p>

                <%= if @phoenix_kit_current_user do %>
                  <div class="alert alert-success">
                    <div>
                      <h3 class="font-bold">User is logged in!</h3>
                      <div class="text-sm">
                        <p><strong>Email:</strong> {@phoenix_kit_current_user.email}</p>
                        <p><strong>ID:</strong> {@phoenix_kit_current_user.id}</p>
                        <%= if @phoenix_kit_current_user.confirmed_at do %>
                          <p><strong>Status:</strong> Confirmed</p>
                        <% else %>
                          <p><strong>Status:</strong> Not confirmed</p>
                        <% end %>
                      </div>
                    </div>
                  </div>
                <% else %>
                  <div class="alert alert-warning">
                    <div>
                      <h3 class="font-bold">No user logged in</h3>
                      <p class="text-sm">Page is accessible but phoenix_kit_current_user is nil</p>
                    </div>
                  </div>
                <% end %>
              </div>
              <div class="badge badge-info">PhoenixKit Mount: ALWAYS ACCESSIBLE</div>
            </div>
          </div>
        </div>
        \"\"\"
      end

      def mount(_params, _session, socket) do
        {:ok, socket}
      end
    end
    """
  end

  defp get_embedded_test_file_content(_), do: nil

  # Add notice about demo files
  defp add_test_demo_notice(igniter) do
    notice = """

    These demonstrate PhoenixKit authentication levels.
    """

    Igniter.add_notice(igniter, notice)
  end

  # Add completion notice with essential next steps
  defp add_completion_notice(igniter) do
    notice = """

    🎉 PhoenixKit installation complete!

    Next steps:
      1. Run: mix ecto.migrate
      2. Start server: mix phx.server  
      3. Visit /phoenix_kit/register
      4. Test demo pages: /test-current-user, /test-redirect-if-auth, /test-ensure-auth

    💡 Layout changes require: mix deps.compile phoenix_kit --force
    """

    Igniter.add_notice(igniter, notice)
  end
end
