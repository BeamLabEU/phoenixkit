defmodule BeamLab.PhoenixKit.Installer do
  @moduledoc """
  DEPRECATED: PhoenixKit installer functions.
  
  As of PhoenixKit v1.0.0, no installation is required. PhoenixKit works out-of-the-box
  with a simple one-line router integration.
  
  ## Migration Guide
  
      # OLD WAY (deprecated)
      BeamLab.PhoenixKit.Installer.install()
      
      # NEW WAY (zero configuration)
      # 1. Add to your router.ex:
      import BeamLab.PhoenixKitWeb.Router
      phoenix_kit()
      
      # 2. Add migrations:
      mix ecto.gen.migration add_phoenix_kit_auth_tables
      # Copy from deps/phoenix_kit/priv/repo/migrations/
      
  The new approach follows Phoenix LiveDashboard pattern for better integration.
  """

  require Logger

  @doc """
  Complete PhoenixKit installation.
  
  This function performs the same operations as `mix phoenix_kit.install`:
  - Copies database migrations
  - Generates configuration
  - Shows router setup instructions
  - Provides next steps
  
  ## Options
  
    * `:scope_prefix` - The prefix for authentication routes (default: "auth")
    * `:no_migrations` - Skip copying database migrations (default: false)
    * `:no_config` - Skip generating configuration files (default: false)
    * `:force` - Overwrite existing files without prompting (default: false)
  
  ## Examples
  
      BeamLab.PhoenixKit.Installer.install()
      BeamLab.PhoenixKit.Installer.install(scope_prefix: "authentication")
      BeamLab.PhoenixKit.Installer.install(force: true)
  """
  def install(options \\ []) do
    options = Keyword.merge([scope_prefix: "/phoenix_kit_users", no_migrations: false, no_config: false, force: false], options)
    
    IO.puts("🚀 PhoenixKit Installation Starting...")
    
    unless phoenix_project?() do
      IO.puts("❌ This must be run from a Phoenix project root directory")
      {:error, :not_phoenix_project}
    else

    if options[:no_migrations] do
      IO.puts("⏭️  Skipping database migrations...")
    else
      generate_migrations(options)
    end

    if options[:no_config] do
      IO.puts("⏭️  Skipping configuration generation...")
    else
      generate_config(options)
    end

    show_installation_instructions(options)
    
    IO.puts("""
    
    ✅ PhoenixKit installation complete!

    Next steps:
    1. Run migrations: mix ecto.migrate
    2. Add routes to your router (see instructions above)
    3. Update your layout templates
    4. Start your server: mix phx.server
    """)
    
      :ok
    end
  end

  @doc """
  Generate PhoenixKit database migrations.
  
  Copies migration files from PhoenixKit to your project with proper timestamps.
  
  ## Options
  
    * `:force` - Overwrite existing migration files without prompting (default: false)
  
  ## Examples
  
      BeamLab.PhoenixKit.Installer.generate_migrations()
      BeamLab.PhoenixKit.Installer.generate_migrations(force: true)
  """
  def generate_migrations(options \\ []) do
    options = Keyword.merge([force: false], options)
    
    IO.puts("📦 Generating PhoenixKit migrations...")
    
    source_path = Path.join([Application.app_dir(:phoenix_kit), "priv", "repo", "migrations"])
    target_path = Path.join([File.cwd!(), "priv", "repo", "migrations"])

    # Ensure target directory exists
    File.mkdir_p!(target_path)

    case File.ls(source_path) do
      {:ok, files} ->
        copied_files = Enum.map(files, fn file ->
          copy_migration_file(source_path, target_path, file, options)
        end)
        |> Enum.filter(& &1)
        
        if length(copied_files) > 0 do
          IO.puts("✅ Generated #{length(copied_files)} migration(s):")
          Enum.each(copied_files, &IO.puts("  #{&1}"))
        else
          IO.puts("ℹ️  No new migrations to generate.")
        end
        
        :ok
      
      {:error, :enoent} ->
        IO.puts("❌ PhoenixKit migrations not found. Ensure PhoenixKit is installed as dependency.")
        {:error, :migrations_not_found}
      
      {:error, reason} ->
        IO.puts("❌ Failed to read PhoenixKit migrations: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Generate PhoenixKit router configuration.
  
  ## Options
  
    * `:scope_prefix` - The prefix for authentication routes (default: "auth")
    * `:dry_run` - Show what would be generated without modifying files (default: false)
    * `:force` - Overwrite existing route configuration without prompting (default: false)
  
  ## Examples
  
      BeamLab.PhoenixKit.Installer.generate_routes()
      BeamLab.PhoenixKit.Installer.generate_routes(scope_prefix: "authentication")
      BeamLab.PhoenixKit.Installer.generate_routes(dry_run: true)
  """
  def generate_routes(options \\ []) do
    options = Keyword.merge([scope_prefix: "/phoenix_kit_users", dry_run: false, force: false], options)
    
    IO.puts("🛣️  Generating PhoenixKit routes...")
    
    app_name = Mix.Project.config()[:app] |> to_string()
    app_module = Macro.camelize(app_name)
    potential_router_paths = [
      "lib/#{app_name}_web/router.ex",
      "lib/#{app_module}Web/router.ex",
      "lib/#{app_module}_web/router.ex"
    ]
    
    router_file = Enum.find(potential_router_paths, &File.exists?/1)
    
    unless router_file do
      IO.puts("❌ Could not find router.ex file")
      {:error, :router_not_found}
    else

      if options[:dry_run] do
        show_router_dry_run(router_file, options)
      else
        inject_routes(router_file, options)
      end
    end
  end

  @doc """
  Show router configuration example.
  
  Displays the router code that needs to be added manually.
  """
  def show_router_example(scope_prefix \\ "/phoenix_kit_users") do
    IO.puts("""
    
    🛣️  Router Configuration Example:
    
    Add the following to your router.ex:

    defmodule YourAppWeb.Router do
      use YourAppWeb, :router
      
      # Import PhoenixKit routes macro
      import BeamLab.PhoenixKitWeb, only: [phoenix_kit_routes: 0, phoenix_kit_routes: 1]
      import BeamLab.PhoenixKitWeb.UserAuth, only: [fetch_current_scope_for_user: 2]

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug :fetch_current_scope_for_user  # Add this line
      end

      # Your existing routes
      scope "/", YourAppWeb do
        pipe_through :browser
        get "/", PageController, :home
      end

      # PhoenixKit Authentication routes - automatically configured!
      phoenix_kit_routes("#{scope_prefix}")
      
      # Or with default prefix /phoenix_kit:
      # phoenix_kit_routes()
    end
    
    That's it! No manual route configuration needed.
    Routes will be automatically available at:
    - #{scope_prefix}/register
    - #{scope_prefix}/log-in  
    - #{scope_prefix}/log-out
    - #{scope_prefix}/settings
    """)
  end

  # Private functions

  defp phoenix_project? do
    File.exists?("mix.exs") and 
    String.contains?(File.read!("mix.exs"), ":phoenix")
  end

  defp copy_migration_file(source_path, target_path, file, options) do
    source_file = Path.join(source_path, file)
    
    # Extract the base migration name without timestamp
    base_name = String.replace(file, ~r/^\d+_/, "")
    
    # Check if migration with same name already exists
    existing_file = find_existing_migration(target_path, base_name)
    
    if existing_file != nil and not options[:force] do
      IO.puts("⚠️  Migration for #{base_name} already exists (#{existing_file})")
      nil
    else
      generate_new_migration(source_file, target_path, base_name)
    end
  end

  defp find_existing_migration(target_path, base_name) do
    case File.ls(target_path) do
      {:ok, files} ->
        Enum.find(files, fn file ->
          String.ends_with?(file, base_name)
        end)
      
      _ ->
        nil
    end
  end

  defp generate_new_migration(source_file, target_path, base_name) do
    # Generate new timestamp that's guaranteed to be unique
    timestamp = generate_migration_timestamp()
    new_filename = "#{timestamp}_#{base_name}"
    target_file = Path.join(target_path, new_filename)

    # Read source content and update module name
    content = File.read!(source_file)
    app_name = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    updated_content = String.replace(content, ~r/defmodule \w+\.Repo\.Migrations\./, "defmodule #{app_name}.Repo.Migrations.")
    
    File.write!(target_file, updated_content)
    new_filename
  end

  defp generate_migration_timestamp do
    # Ensure unique timestamp by using microseconds
    now = :os.system_time(:microsecond)
    # Convert to format expected by Ecto (YYYYMMDDHHMMSS)
    {{year, month, day}, {hour, minute, second}} = :calendar.system_time_to_universal_time(now, :microsecond)
    
    # Add microseconds to seconds to ensure uniqueness
    unique_second = rem(now, 1_000_000) |> div(10_000) |> Kernel.+(second)
    
    :io_lib.format("~4..0w~2..0w~2..0w~2..0w~2..0w~2..0w", [year, month, day, hour, minute, unique_second])
    |> List.to_string()
  end

  defp generate_config(options) do
    IO.puts("⚙️  Generating PhoenixKit configuration...")
    
    config_path = Path.join([File.cwd!(), "config", "config.exs"])
    app_name = Mix.Project.config()[:app] |> to_string()
    
    config_content = """
    
    # PhoenixKit Configuration
    config :phoenix_kit,
      mode: :library,
      library_mode: true,
      parent_endpoint: #{Macro.camelize(app_name)}Web.Endpoint

    # Configure PhoenixKit Repo (adjust database settings as needed)
    config :phoenix_kit, BeamLab.PhoenixKit.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: System.get_env("DATABASE_NAME", "#{app_name}_dev"),
      pool_size: 10

    # Optional: Configure mailer for email features
    config :phoenix_kit, BeamLab.PhoenixKit.Mailer,
      adapter: Swoosh.Adapters.Local
    """

    if File.exists?(config_path) do
      content = File.read!(config_path)
      
      if String.contains?(content, "config :phoenix_kit") do
        if options[:force] do
          File.write!(config_path, content <> config_content)
          IO.puts("✅ Updated config/config.exs")
        else
          IO.puts("ℹ️  PhoenixKit configuration already exists in config.exs")
        end
      else
        File.write!(config_path, content <> config_content)
        IO.puts("✅ Updated config/config.exs")
      end
    else
      IO.puts("❌ config/config.exs not found. Please ensure you're in a Phoenix project root.")
    end
  end

  defp show_installation_instructions(options) do
    scope_prefix = options[:scope_prefix]
    
    app_name = Mix.Project.config()[:app] |> to_string()
    _app_module = Macro.camelize(app_name)
    
    IO.puts("""

    📋 Simple Integration Steps:
    
    1. Add router configuration (see below)
    
    2. Update your layout template to show authentication state:
    
    <%= if assigns[:current_scope] do %>
      <div>Welcome, <%= @current_scope.user.email %>!</div>
      <.link href={~p"#{scope_prefix}/log-out"} method="delete">Log out</.link>
    <% else %>
      <.link navigate={~p"#{scope_prefix}/log-in"}>Log in</.link>
      <.link navigate={~p"#{scope_prefix}/register"}>Sign up</.link>
    <% end %>

    Router Configuration:
    """)
    
    show_router_example(scope_prefix)
  end

  defp show_router_dry_run(router_file, options) do
    IO.puts("🔍 Dry run mode - no files will be modified")
    IO.puts("Would modify: #{router_file}")
    IO.puts("")
    show_router_example(options[:scope_prefix])
  end

  defp inject_routes(router_file, options) do
    content = File.read!(router_file)
    
    if String.contains?(content, "BeamLab.PhoenixKitWeb") do
      if options[:force] do
        IO.puts("⚠️  PhoenixKit routes already exist. Use force option or update manually.")
      else
        IO.puts("ℹ️  PhoenixKit routes already exist in router.")
      end
    else
      IO.puts("⚠️  Automatic router injection not implemented.")
      IO.puts("Please add the routes manually:")
      show_router_example(options[:scope_prefix])
    end
    
    :ok
  end
end