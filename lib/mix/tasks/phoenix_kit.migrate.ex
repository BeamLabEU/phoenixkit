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

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [status: :boolean, repo: :string, force: :boolean],
        aliases: [s: :status, r: :repo, f: :force]
      )

    repo = get_repo(opts[:repo])

    if opts[:status] do
      show_status(repo)
    else
      run_migration(repo, opts)
    end
  end

  defp get_repo(nil) do
    Logger.info("PhoenixKit Schema Migration Tool")
    Logger.info("===============================")
    Logger.info("Detecting repository automatically...")

    case detect_repo() do
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

    opts = %{prefix: "public", escaped_prefix: "public", repo: repo}
    installed_version = PhoenixKit.Migrations.Postgres.migrated_version(opts)
    target_version = PhoenixKit.Migrations.Postgres.current_version()
    migration_required = installed_version < target_version

    Logger.info("")
    Logger.info("Repository: #{inspect(repo)}")

    Logger.info(
      "Installed Version: #{if installed_version > 0, do: installed_version, else: "None (fresh install)"}"
    )

    Logger.info("Target Version: #{target_version}")
    Logger.info("Migration Required: #{if migration_required, do: "YES", else: "NO"}")
    Logger.info("")

    if migration_required do
      case installed_version do
        0 ->
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

  defp run_migration(repo, _opts) do
    # Verify repo exists
    unless verify_repo(repo), do: exit({:shutdown, 1})

    opts = %{prefix: "public", escaped_prefix: "public", repo: repo}
    installed_version = PhoenixKit.Migrations.Postgres.migrated_version(opts)
    target_version = PhoenixKit.Migrations.Postgres.current_version()
    migration_required = installed_version < target_version

    if not migration_required do
      Logger.info("✅ Schema already up to date at version #{installed_version}")
      exit({:shutdown, 0})
    end

    Logger.info("Starting PhoenixKit schema migration...")
    Logger.info("From: #{if installed_version > 0, do: installed_version, else: "fresh install"}")
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

    case PhoenixKit.Migrations.Postgres.up(opts) do
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
    if Code.ensure_loaded?(repo) do
      if function_exported?(repo, :__adapter__, 0) do
        true
      else
        Logger.error("#{repo} is not an Ecto repository")
        false
      end
    else
      Logger.error("Repository module #{repo} not found or not loaded")
      false
    end
  end

  defp confirm_migration(0, target_version) do
    Logger.warning("⚠️  This will create new PhoenixKit authentication tables")
    Logger.warning("   Target version: #{target_version}")

    Logger.warning(
      "   Tables to create: phoenix_kit, phoenix_kit_tokens, phoenix_kit_schema_versions"
    )

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

  # Simple repo detection without external dependencies
  defp detect_repo do
    # Try PhoenixKit configuration first
    case Application.get_env(:phoenix_kit, :repo) do
      nil ->
        # Try common repo patterns
        detect_common_repo_patterns()

      repo ->
        {:ok, repo}
    end
  end

  defp detect_common_repo_patterns do
    app_name = Mix.Project.config()[:app]
    base_module = app_name |> to_string() |> Macro.camelize()

    potential_repos = [
      Module.concat([base_module, "Repo"]),
      Module.concat([base_module, "Repository"])
    ]

    Enum.reduce_while(potential_repos, {:error, "No repo found"}, fn repo, _acc ->
      if Code.ensure_loaded?(repo) and function_exported?(repo, :__adapter__, 0) do
        {:halt, {:ok, repo}}
      else
        {:cont, {:error, "No repo found"}}
      end
    end)
  end
end
