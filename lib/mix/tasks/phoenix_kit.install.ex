defmodule Mix.Tasks.PhoenixKit.Install do
  @moduledoc """
  Install PhoenixKit migrations into the parent application.

  This task copies the necessary migration files from PhoenixKit
  into the parent application's priv/repo/migrations directory.

  ## Usage

      mix phoenix_kit.install

  This will copy the migration files and allow you to run:

      mix ecto.migrate

  ## Options

    * `--migrations-only` - Only copy migration files, don't update configuration

  """
  @shortdoc "Install PhoenixKit migrations into parent application"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    opts = parse_args(args)
    
    # Find the source migrations directory
    phoenix_kit_priv = find_phoenix_kit_priv()
    source_migrations = Path.join(phoenix_kit_priv, "repo/migrations")
    
    # Find the target migrations directory
    target_migrations = "priv/repo/migrations"
    
    if File.exists?(source_migrations) do
      File.mkdir_p!(target_migrations)
      copy_migrations(source_migrations, target_migrations)
      
      unless opts[:migrations_only] do
        print_setup_instructions()
      end
    else
      Mix.shell().error("PhoenixKit migrations not found at #{source_migrations}")
      Mix.shell().error("Make sure PhoenixKit is properly installed as a dependency.")
    end
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [migrations_only: :boolean])
    opts
  end

  defp find_phoenix_kit_priv do
    # Try to find PhoenixKit in deps
    deps_path = Mix.Project.deps_path()
    phoenix_kit_dep = Path.join([deps_path, "phoenix_kit", "priv"])
    
    if File.exists?(phoenix_kit_dep) do
      phoenix_kit_dep
    else
      # Fallback to local development
      Path.join([File.cwd!(), "priv"])
    end
  end

  defp copy_migrations(source, target) do
    auth_migration = "create_phoenix_kit_auth_tables.exs"
    
    # Find the auth migration file
    source_files = File.ls!(source)
    auth_file = Enum.find(source_files, &String.ends_with?(&1, auth_migration))
    
    if auth_file do
      timestamp = generate_timestamp()
      new_filename = "#{timestamp}_#{auth_migration}"
      
      source_path = Path.join(source, auth_file)
      target_path = Path.join(target, new_filename)
      
      File.copy!(source_path, target_path)
      
      Mix.shell().info("✅ Copied migration: #{new_filename}")
    else
      Mix.shell().error("❌ Auth migration file not found")
    end
  end

  defp generate_timestamp do
    {{year, month, day}, {hour, minute, second}} = :calendar.universal_time()
    
    :io_lib.format("~4..0B~2..0B~2..0B~2..0B~2..0B~2..0B", 
                   [year, month, day, hour, minute, second])
    |> to_string()
  end

  defp print_setup_instructions do
    Mix.shell().info("""

    ✅ PhoenixKit migrations installed successfully!

    Next steps:
    
    1. Add PhoenixKit configuration to your config/config.exs:
    
        config :phoenix_kit,
          repo: YourApp.Repo
    
    2. Add PhoenixKit routes to your router:
    
        # lib/your_app_web/router.ex
        import PhoenixKitWeb.Integration
        phoenix_kit_auth_routes("/auth")
    
    3. Run the migration:
    
        mix ecto.migrate
    
    4. Start using PhoenixKit authentication!
    
    For more information, see: https://github.com/BeamLabEU/phoenixkit
    """)
  end
end