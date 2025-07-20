defmodule Mix.Tasks.PhoenixKit.Install do
  @shortdoc "Installs PhoenixKit authentication library into your Phoenix application"

  @moduledoc """
  Installs PhoenixKit authentication library into your Phoenix application.

  This task will:
  - Copy database migrations
  - Generate configuration 
  - Show router setup instructions
  - Verify dependencies

  ## Examples

      $ mix phoenix_kit.install
      $ mix phoenix_kit.install --scope-prefix auth
      $ mix phoenix_kit.install --no-migrations

  ## Options

    * `--scope-prefix` - The prefix for authentication routes (default: "auth")
    * `--no-migrations` - Skip copying database migrations
    * `--no-config` - Skip generating configuration files
    * `--force` - Overwrite existing files without prompting

  """

  use Mix.Task

  alias Mix.Tasks.PhoenixKit.Install.{Generator, Validator, Injector}

  @switches [
    scope_prefix: :string,
    no_migrations: :boolean,
    no_config: :boolean,
    force: :boolean
  ]

  @default_options [
    scope_prefix: "auth",
    no_migrations: false,
    no_config: false,
    force: false
  ]

  @impl Mix.Task
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phoenix_kit.install must be invoked from within your *_web application root directory")
    end

    options = parse_options(args)
    
    Validator.ensure_phoenix_project!()
    Validator.check_phoenix_kit_dependency!()
    
    if options[:no_migrations] do
      Mix.shell().info("Skipping database migrations...")
    else
      copy_migrations(options)
    end

    if options[:no_config] do
      Mix.shell().info("Skipping configuration generation...")
    else
      generate_config(options)
    end

    show_installation_instructions(options)
    
    Mix.shell().info("""
    
    #{IO.ANSI.green()}PhoenixKit installation complete!#{IO.ANSI.reset()}

    Next steps:
    1. Run migrations: #{IO.ANSI.cyan()}mix ecto.migrate#{IO.ANSI.reset()}
    2. Add routes to your router (see instructions above)
    3. Update your layout templates
    4. Start your server: #{IO.ANSI.cyan()}mix phx.server#{IO.ANSI.reset()}
    """)
  end

  defp parse_options(args) do
    {options, _} = OptionParser.parse!(args, switches: @switches)
    Keyword.merge(@default_options, options)
  end

  defp copy_migrations(options) do
    Mix.shell().info("Copying PhoenixKit migrations...")
    
    source_path = Path.join([Application.app_dir(:phoenix_kit), "priv", "repo", "migrations"])
    target_path = Path.join([File.cwd!(), "priv", "repo", "migrations"])

    case File.ls(source_path) do
      {:ok, files} ->
        Enum.each(files, fn file ->
          copy_migration_file(source_path, target_path, file, options)
        end)
        Mix.shell().info("✓ Copied #{length(files)} migration(s)")
      
      {:error, :enoent} ->
        Mix.shell().error("PhoenixKit migrations not found. Ensure PhoenixKit is properly installed as a dependency.")
      
      {:error, reason} ->
        Mix.shell().error("Failed to read PhoenixKit migrations: #{reason}")
    end
  end

  defp copy_migration_file(source_path, target_path, file, options) do
    source_file = Path.join(source_path, file)
    
    # Generate new timestamp for the migration to avoid conflicts
    timestamp = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
    new_filename = String.replace(file, ~r/^\d+/, timestamp)
    target_file = Path.join(target_path, new_filename)

    if File.exists?(target_file) and not options[:force] do
      if Mix.shell().yes?("Migration #{new_filename} already exists. Overwrite?") do
        File.copy!(source_file, target_file)
        Mix.shell().info("  #{target_file}")
      end
    else
      File.copy!(source_file, target_file)
      Mix.shell().info("  #{target_file}")
    end
  end

  defp generate_config(options) do
    Mix.shell().info("Generating PhoenixKit configuration...")
    
    config_path = Path.join([File.cwd!(), "config", "config.exs"])
    
    config_content = """
    
    # PhoenixKit Configuration
    config :phoenix_kit,
      mode: :library

    # Configure PhoenixKit Repo (adjust database settings as needed)
    config :phoenix_kit, BeamLab.PhoenixKit.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: System.get_env("DATABASE_NAME", "your_app_dev"),
      pool_size: 10

    # Optional: Configure mailer for email features
    config :phoenix_kit, BeamLab.PhoenixKit.Mailer,
      adapter: Swoosh.Adapters.Local
    """

    if File.exists?(config_path) do
      content = File.read!(config_path)
      
      if String.contains?(content, "config :phoenix_kit") do
        if options[:force] or Mix.shell().yes?("PhoenixKit configuration already exists. Update it?") do
          inject_config(config_path, config_content, options)
        end
      else
        inject_config(config_path, config_content, options)
      end
    else
      Mix.shell().error("config/config.exs not found. Please ensure you're in a Phoenix project root.")
    end
  end

  defp inject_config(config_path, config_content, _options) do
    File.write!(config_path, File.read!(config_path) <> config_content)
    Mix.shell().info("✓ Updated config/config.exs")
  end

  defp show_installation_instructions(options) do
    scope_prefix = options[:scope_prefix]
    
    Mix.shell().info("""

    #{IO.ANSI.yellow()}Router Configuration Required:#{IO.ANSI.reset()}
    
    Add the following to your #{IO.ANSI.cyan()}lib/your_app_web/router.ex#{IO.ANSI.reset()}:

    #{IO.ANSI.green()}# Import PhoenixKit authentication functions#{IO.ANSI.reset()}
    #{IO.ANSI.cyan()}import BeamLab.PhoenixKitWeb.UserAuth#{IO.ANSI.reset()}

    #{IO.ANSI.green()}# Add to your browser pipeline:#{IO.ANSI.reset()}
    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
      #{IO.ANSI.cyan()}plug :fetch_current_scope_for_user  # Add this line#{IO.ANSI.reset()}
    end

    #{IO.ANSI.green()}# Add authentication routes:#{IO.ANSI.reset()}
    scope "/#{scope_prefix}", BeamLab.PhoenixKitWeb do
      pipe_through [:browser, :redirect_if_user_is_authenticated]

      get "/register", UserRegistrationController, :new
      post "/register", UserRegistrationController, :create
      get "/log-in", UserSessionController, :new
      post "/log-in", UserSessionController, :create
      get "/log-in/:token", UserSessionController, :confirm
    end

    scope "/#{scope_prefix}", BeamLab.PhoenixKitWeb do
      pipe_through [:browser, :require_authenticated_user]

      get "/settings", UserSettingsController, :edit
      put "/settings", UserSettingsController, :update
      delete "/log-out", UserSessionController, :delete
    end

    #{IO.ANSI.yellow()}Layout Integration:#{IO.ANSI.reset()}
    
    Add authentication state to your layout templates:

    #{IO.ANSI.cyan()}<%= if @current_scope do %>
      <div>Welcome, <%= @current_scope.user.email %>!</div>
      <.link href={~p"/#{scope_prefix}/log-out"} method="delete">Log out</.link>
    <% else %>
      <.link navigate={~p"/#{scope_prefix}/log-in"}>Log in</.link>
      <.link navigate={~p"/#{scope_prefix}/register"}>Sign up</.link>
    <% end %>#{IO.ANSI.reset()}
    """)
  end
end

defmodule Mix.Tasks.PhoenixKit.Install.Validator do
  @moduledoc false

  def ensure_phoenix_project! do
    unless phoenix_project?() do
      Mix.raise("""
      This task can only be run within a Phoenix application.
      
      Make sure you're in the root directory of a Phoenix project.
      """)
    end
  end

  def check_phoenix_kit_dependency! do
    deps = Mix.Project.config()[:deps] || []
    
    phoenix_kit_dep = Enum.find(deps, fn
      {:phoenix_kit, _} -> true
      {:phoenix_kit, _, _} -> true
      _ -> false
    end)

    unless phoenix_kit_dep do
      Mix.shell().error("""
      PhoenixKit dependency not found in mix.exs.
      
      Please add PhoenixKit to your dependencies:
      
      def deps do
        [
          {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
        ]
      end
      
      Then run: mix deps.get
      """)
      
      System.halt(1)
    end
  end

  defp phoenix_project? do
    File.exists?("mix.exs") and 
    String.contains?(File.read!("mix.exs"), ":phoenix")
  end
end

defmodule Mix.Tasks.PhoenixKit.Install.Generator do
  @moduledoc false
  # Reserved for future template generation functionality
end

defmodule Mix.Tasks.PhoenixKit.Install.Injector do
  @moduledoc false  
  # Reserved for future code injection functionality
end