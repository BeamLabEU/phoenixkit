defmodule Mix.Tasks.PhoenixKit.Gen.Migration do
  @shortdoc "Generates PhoenixKit database migrations"

  @moduledoc """
  Generates PhoenixKit database migrations for authentication tables.

  This task copies the necessary database migration files from PhoenixKit
  to your Phoenix application with proper timestamps to avoid conflicts.

  ## Examples

      $ mix phoenix_kit.gen.migration
      $ mix phoenix_kit.gen.migration --force

  ## Options

    * `--force` - Overwrite existing migration files without prompting

  The generated migration will create:
  
    * `phoenix_kit_users` table - User accounts with email and password
    * `phoenix_kit_users_tokens` table - Session and email verification tokens

  Remember to run `mix ecto.migrate` after generating the migration.
  """

  use Mix.Task

  @switches [force: :boolean]
  @default_options [force: false]

  @impl Mix.Task  
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phoenix_kit.gen.migration must be invoked from within your *_web application root directory")
    end

    options = parse_options(args)
    
    ensure_phoenix_project!()
    ensure_migrations_directory!()
    
    copy_migrations(options)
    
    Mix.shell().info("""
    
    #{IO.ANSI.green()}PhoenixKit migrations generated successfully!#{IO.ANSI.reset()}

    Next steps:
    1. Review the generated migration files
    2. Run migrations: #{IO.ANSI.cyan()}mix ecto.migrate#{IO.ANSI.reset()}
    3. Continue with PhoenixKit installation: #{IO.ANSI.cyan()}mix phoenix_kit.install#{IO.ANSI.reset()}
    """)
  end

  defp parse_options(args) do
    {options, _} = OptionParser.parse!(args, switches: @switches)
    Keyword.merge(@default_options, options)
  end

  defp ensure_phoenix_project! do
    unless phoenix_project?() do
      Mix.raise("""
      This task can only be run within a Phoenix application.
      
      Make sure you're in the root directory of a Phoenix project.
      """)
    end
  end

  defp ensure_migrations_directory! do
    migrations_dir = Path.join([File.cwd!(), "priv", "repo", "migrations"])
    
    unless File.exists?(migrations_dir) do
      Mix.shell().info("Creating migrations directory...")
      File.mkdir_p!(migrations_dir)
    end
  end

  defp copy_migrations(options) do
    Mix.shell().info("Generating PhoenixKit migrations...")
    
    source_path = Path.join([Application.app_dir(:phoenix_kit), "priv", "repo", "migrations"])
    target_path = Path.join([File.cwd!(), "priv", "repo", "migrations"])

    case File.ls(source_path) do
      {:ok, files} ->
        copied_files = Enum.map(files, fn file ->
          copy_migration_file(source_path, target_path, file, options)
        end)
        |> Enum.filter(& &1)
        
        if length(copied_files) > 0 do
          Mix.shell().info("✓ Generated #{length(copied_files)} migration(s):")
          Enum.each(copied_files, &Mix.shell().info("  #{&1}"))
        else
          Mix.shell().info("No new migrations to generate.")
        end
      
      {:error, :enoent} ->
        Mix.shell().error("""
        PhoenixKit migrations not found. 
        
        This usually means:
        1. PhoenixKit is not properly installed as a dependency
        2. You need to run `mix deps.get` first
        
        Please add PhoenixKit to your mix.exs dependencies and run `mix deps.get`.
        """)
        System.halt(1)
      
      {:error, reason} ->
        Mix.shell().error("Failed to read PhoenixKit migrations: #{reason}")
        System.halt(1)
    end
  end

  defp copy_migration_file(source_path, target_path, file, options) do
    source_file = Path.join(source_path, file)
    
    # Extract the base migration name without timestamp
    base_name = String.replace(file, ~r/^\d+_/, "")
    
    # Check if migration with same name already exists
    existing_file = find_existing_migration(target_path, base_name)
    
    if existing_file != nil and not options[:force] do
      if Mix.shell().yes?("Migration for #{base_name} already exists (#{existing_file}). Regenerate?") do
        generate_new_migration(source_file, target_path, base_name)
      else
        nil
      end
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

    # Read source content and update module name with new timestamp
    content = File.read!(source_file)
    updated_content = update_migration_module_name(content, timestamp)
    
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

  defp update_migration_module_name(content, _timestamp) do
    # Update the module name to match the new timestamp
    String.replace(content, ~r/defmodule \w+\.Repo\.Migrations\./, "defmodule #{Mix.Phoenix.otp_app()}.Repo.Migrations.")
  end

  defp phoenix_project? do
    File.exists?("mix.exs") and 
    String.contains?(File.read!("mix.exs"), ":phoenix")
  end
end