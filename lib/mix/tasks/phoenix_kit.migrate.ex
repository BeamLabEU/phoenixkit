defmodule Mix.Tasks.PhoenixKit.Migrate do
  @moduledoc """
  Manages PhoenixKit schema migrations.
  
  This task allows you to manually control PhoenixKit schema versioning
  and migrations, which is useful for production deployments.
  
  ## Usage
  
  Check current schema version:
  
      mix phoenix_kit.migrate --status
  
  Migrate to latest version:
  
      mix phoenix_kit.migrate
  
  Migrate with specific repo:
  
      mix phoenix_kit.migrate --repo MyApp.Repo
  
  ## Commands
  
  - `--status` - Show current and target schema versions
  - `--repo REPO` - Specify repository to use
  - `--force` - Force migration even if data loss might occur
  
  ## Safe Migration Process
  
  PhoenixKit follows these principles for safe migrations:
  
  1. **Versioned Schema** - Each version is tracked in phoenix_kit_schema_versions
  2. **Idempotent Operations** - Migrations can be run multiple times safely  
  3. **No Data Loss** - Migrations preserve existing data
  4. **Rollback Support** - Future versions will support schema rollback
  
  ## Production Usage
  
  For production deployments:
  
  1. Test migration on staging environment first
  2. Backup database before migration
  3. Run migration during maintenance window if needed
  4. Monitor logs for any issues
  
  """
  
  use Mix.Task
  require Logger

  @shortdoc "Manage PhoenixKit schema migrations"

  def run(args) do
    Mix.Task.run("app.start")
    
    {opts, _, _} = OptionParser.parse(args, 
      switches: [status: :boolean, repo: :string, force: :boolean],
      aliases: [s: :status, r: :repo, f: :force]
    )
    
    repo = get_repo(opts[:repo])
    
    cond do
      opts[:status] -> show_status(repo)
      true -> run_migration(repo, opts)
    end
  end
  
  defp get_repo(nil) do
    Logger.info("PhoenixKit Schema Migration Tool")
    Logger.info("===============================")
    Logger.info("Detecting repository automatically...")
    
    case PhoenixKit.AutoSetup.detect_parent_repo() do
      {:ok, detected_repo} ->
        Logger.info("Detected repo: #{inspect(detected_repo)}")
        detected_repo
      {:error, reason} ->
        Logger.error("Could not detect repository: #{reason}")
        Logger.error("Please specify repo with: mix phoenix_kit.migrate --repo YourApp.Repo")
        exit({:shutdown, 1})
    end
  end
  
  defp get_repo(repo_string) do
    Logger.info("PhoenixKit Schema Migration Tool")
    Logger.info("===============================")
    Logger.info("Using specified repo: #{repo_string}")
    Module.concat([repo_string])
  end
  
  defp show_status(repo) do
    # Verify repo exists
    unless verify_repo(repo), do: exit({:shutdown, 1})
    
    Logger.info("PhoenixKit Schema Status")
    Logger.info("=======================")
    
    installed_version = PhoenixKit.SchemaMigrations.get_installed_version(repo)
    target_version = PhoenixKit.SchemaMigrations.get_target_version()
    migration_required = PhoenixKit.SchemaMigrations.migration_required?(repo)
    
    Logger.info("")
    Logger.info("Repository: #{inspect(repo)}")
    Logger.info("Installed Version: #{installed_version || "None (fresh install)"}")
    Logger.info("Target Version: #{target_version}")
    Logger.info("Migration Required: #{if migration_required, do: "YES", else: "NO"}")
    Logger.info("")
    
    if migration_required do
      case installed_version do
        nil ->
          Logger.info("📋 Action Required: Fresh installation")
          Logger.info("   This will create PhoenixKit authentication tables")
          Logger.info("   Tables: phoenix_kit, phoenix_kit_tokens, phoenix_kit_schema_versions")
          
        old_version ->
          Logger.info("📋 Action Required: Schema upgrade")
          Logger.info("   Upgrade from #{old_version} to #{target_version}")
          Logger.info("   This is a safe operation that preserves existing data")
      end
      
      Logger.info("")
      Logger.info("To apply migration: mix phoenix_kit.migrate")
    else
      Logger.info("✅ Schema is up to date - no migration needed")
    end
  end
  
  defp run_migration(repo, opts) do
    # Verify repo exists
    unless verify_repo(repo), do: exit({:shutdown, 1})
    
    installed_version = PhoenixKit.SchemaMigrations.get_installed_version(repo)
    target_version = PhoenixKit.SchemaMigrations.get_target_version()
    migration_required = PhoenixKit.SchemaMigrations.migration_required?(repo)
    
    if not migration_required do
      Logger.info("✅ Schema already up to date at version #{installed_version}")
      exit({:shutdown, 0})
    end
    
    Logger.info("Starting PhoenixKit schema migration...")
    Logger.info("From: #{installed_version || "fresh install"}")  
    Logger.info("To: #{target_version}")
    Logger.info("")
    
    # Confirm migration unless forced
    unless opts[:force] do
      if not confirm_migration(installed_version, target_version) do
        Logger.info("Migration cancelled by user")
        exit({:shutdown, 0})
      end
    end
    
    # Perform migration
    Logger.info("Applying migration...")
    
    case PhoenixKit.SchemaMigrations.migrate_to_current(repo) do
      :ok ->
        Logger.info("✅ Migration completed successfully!")
        Logger.info("")
        Logger.info("PhoenixKit schema is now at version #{target_version}")
        Logger.info("Authentication tables are ready for use.")
        
      {:error, reason} ->
        Logger.error("❌ Migration failed: #{inspect(reason)}")
        Logger.error("")
        Logger.error("Common solutions:")
        Logger.error("- Verify database connectivity")
        Logger.error("- Check database permissions")  
        Logger.error("- Ensure PostgreSQL citext extension is available")
        Logger.error("- Review database logs for detailed error information")
        exit({:shutdown, 1})
    end
  end
  
  defp verify_repo(repo) do
    unless Code.ensure_loaded?(repo) do
      Logger.error("Repository module #{repo} not found or not loaded")
      false
    else
      unless function_exported?(repo, :__adapter__, 0) do
        Logger.error("#{repo} is not an Ecto repository")
        false
      else
        true
      end
    end
  end
  
  defp confirm_migration(nil, target_version) do
    Logger.warning("⚠️  This will create new PhoenixKit authentication tables")
    Logger.warning("   Target version: #{target_version}")
    Logger.warning("   Tables to create: phoenix_kit, phoenix_kit_tokens, phoenix_kit_schema_versions")
    Logger.warning("")
    
    case Mix.shell().yes?("Proceed with fresh installation?") do
      true -> true
      false -> false
    end
  end
  
  defp confirm_migration(from_version, to_version) do
    Logger.warning("⚠️  This will upgrade your PhoenixKit schema")
    Logger.warning("   From version: #{from_version}")  
    Logger.warning("   To version: #{to_version}")
    Logger.warning("   This operation preserves existing data")
    Logger.warning("")
    
    case Mix.shell().yes?("Proceed with schema upgrade?") do
      true -> true
      false -> false  
    end
  end
end