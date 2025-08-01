defmodule Mix.Tasks.PhoenixKit.Install do
  @moduledoc """
  Install and configure PhoenixKit for use in an application.

  ## Example

  Install with required repo parameter:

  ```bash
  mix phoenix_kit.install --repo MyApp.Repo
  ```

  Specify a custom repo and prefix explicitly:

  ```bash
  mix phoenix_kit.install --repo MyApp.CustomRepo --prefix "auth"
  ```

  ## Options

  * `--repo` or `-r` — **REQUIRED** Specify an Ecto repo for PhoenixKit to use
  * `--prefix` or `-p` — Specify a PostgreSQL schema prefix, defaults to "public"
  * `--create-schema` — Create schema if using custom prefix (default: true for non-public prefixes)
  """

  @shortdoc "Install and configure PhoenixKit for use in an application"

  use Mix.Task

  @switches [prefix: :string, repo: :string, create_schema: :boolean]
  @aliases [p: :prefix, r: :repo]

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, switches: @switches, aliases: @aliases)

    # Make --repo required
    unless opts[:repo] do
      Mix.raise("""
      --repo is required!

      Usage: mix phoenix_kit.install --repo MyApp.Repo

      Example:
        mix phoenix_kit.install --repo MyApp.Repo
        mix phoenix_kit.install --repo MyApp.Repo --prefix "auth"
      """)
    end

    app_name = Mix.Project.config()[:app]
    repo = find_repo(opts[:repo])
    prefix = opts[:prefix] || "public"
    create_schema = opts[:create_schema] != false && prefix != "public"

    migration_content = """
    use Ecto.Migration

    def up, do: PhoenixKit.Migration.up(#{migration_opts(prefix, create_schema)})

    def down, do: PhoenixKit.Migration.down(#{migration_opts(prefix, create_schema)})
    """

    # Check for existing migrations first
    if PhoenixKit.Migration.migrations_exist?() do
      existing_migrations = PhoenixKit.Migration.existing_migrations()
      Mix.shell().info([
        :yellow, "🔍 Found existing PhoenixKit migrations: ", :reset, inspect(existing_migrations)
      ])
      Mix.shell().info([
        :yellow, "⏭️  Skipping migration creation - PhoenixKit tables already exist", :reset
      ])
    else
      # Generate migration
      timestamp = generate_timestamp()
      migration_name = "add_phoenix_kit_auth_tables"
      migration_file = "#{timestamp}_#{migration_name}.exs"

      migrations_path = Path.join([File.cwd!(), "priv", "repo", "migrations"])
      File.mkdir_p!(migrations_path)

      migration_path = Path.join(migrations_path, migration_file)

      module_name =
        "#{Macro.camelize(to_string(app_name))}.Repo.Migrations.#{Macro.camelize(migration_name)}"

      full_migration = """
      defmodule #{module_name} do
        #{migration_content}
      end
      """

      File.write!(migration_path, full_migration)
      Mix.shell().info([:green, "📝 Creating PhoenixKit migration: ", :reset, migration_path])
    end

    # Add configuration if not exists
    maybe_add_phoenix_kit_config(repo)

    Mix.shell().info([
      :green,
      "\nPhoenixKit installation complete!\n",
      :reset,
      "\nNext steps:\n",
      "  1. Run: ",
      :bright,
      "mix ecto.migrate",
      :reset,
      "\n",
      "  2. Add PhoenixKit routes to your router.ex\n"
    ])
  end

  defp find_repo(repo_string) do
    Module.concat([repo_string])
  end

  # defp get_ecto_repos do
  #   Mix.Project.config()[:ecto_repos] || []
  # end

  defp migration_opts("public", false), do: ""

  defp migration_opts(prefix, create_schema) when is_binary(prefix) do
    opts = [prefix: prefix]
    opts = if create_schema, do: Keyword.put(opts, :create_schema, true), else: opts
    inspect(opts)
  end

  defp generate_timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  defp maybe_add_phoenix_kit_config(repo) do
    config_path = "config/config.exs"

    if File.exists?(config_path) do
      config_content = File.read!(config_path)
      config_line = "config :phoenix_kit, repo: #{inspect(repo)}"

      case Regex.run(~r/config\s+:phoenix_kit[^}]*}/s, config_content) do
        [existing_config] ->
          Mix.shell().info([
            :yellow, "🔍 Found existing PhoenixKit configuration: ", :reset, existing_config
          ])
          
          if Mix.shell().yes?("Replace existing PhoenixKit configuration?") do
            Mix.shell().info([:green, "✅ Updating PhoenixKit configuration", :reset])
            # Simple replacement - remove old config and add new one
            updated_content = String.replace(config_content, existing_config, config_line)
            File.write!(config_path, updated_content)
            Mix.shell().info([:green, "* updating ", :reset, config_path])
          else
            Mix.shell().info([:yellow, "⏭️  Keeping existing PhoenixKit configuration", :reset])
          end

        nil ->
          unless String.contains?(config_content, config_line) do
            Mix.shell().info([:green, "📝 Adding new PhoenixKit configuration", :reset])
            updated_config = config_content <> "\n\n# PhoenixKit configuration\n#{config_line}\n"
            File.write!(config_path, updated_config)
            Mix.shell().info([:green, "* updating ", :reset, config_path])
          end
      end
    end
  end
end
