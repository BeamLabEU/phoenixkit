defmodule PhoenixKit.SchemaMigrations do
  @moduledoc """
  Manages PhoenixKit database schema versioning and migrations.
  
  This module handles:
  - Tracking current schema version
  - Applying safe migrations between versions
  - Rolling back to previous versions when needed
  - Ensuring data integrity during upgrades
  """

  require Logger

  @current_schema_version "1.0.0"
  
  # Schema version history - each version defines required changes
  # @schema_versions [
  #   "0.1.0",  # Initial version (implicit)
  #   "1.0.0"   # Current version with citext and proper indexes
  # ]

  @doc """
  Gets the current schema version installed in the database.
  Returns nil if no version table exists (fresh install).
  """
  def get_installed_version(repo) do
    if version_table_exists?(repo) do
      case repo.query("SELECT version FROM phoenix_kit_schema_versions ORDER BY inserted_at DESC LIMIT 1") do
        {:ok, %{rows: [[version]]}} -> version
        {:ok, %{rows: []}} -> nil
        {:error, _} -> nil
      end
    else
      nil
    end
  end

  @doc """
  Gets the target schema version (current version of the library).
  """
  def get_target_version, do: @current_schema_version

  @doc """
  Checks if a schema migration is required.
  """
  def migration_required?(repo) do
    installed = get_installed_version(repo)
    target = get_target_version()
    
    case installed do
      nil -> true  # Fresh install
      ^target -> false  # Already up to date
      _ -> version_compare(installed, target) == :lt  # Upgrade needed
    end
  end

  @doc """
  Performs safe migration from current version to target version.
  Returns :ok on success, {:error, reason} on failure.
  """
  def migrate_to_current(repo) do
    installed_version = get_installed_version(repo)
    target_version = get_target_version()
    
    Logger.info("[PhoenixKit] Schema migration from #{installed_version || "fresh"} to #{target_version}")
    
    case installed_version do
      nil ->
        # Fresh install
        perform_fresh_install(repo)
      ^target_version ->
        # Already current
        Logger.info("[PhoenixKit] Schema already at target version #{target_version}")
        :ok
      old_version ->
        # Upgrade needed
        perform_upgrade(repo, old_version, target_version)
    end
  end

  @doc """
  Creates the schema version tracking table if it doesn't exist.
  """
  def ensure_version_table(repo) do
    # Execute commands separately to avoid prepared statement issues
    version_table_commands = [
      """
      CREATE TABLE IF NOT EXISTS phoenix_kit_schema_versions (
        id bigserial PRIMARY KEY,
        version varchar(50) NOT NULL,
        applied_at timestamp NOT NULL DEFAULT NOW(),
        inserted_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE INDEX IF NOT EXISTS phoenix_kit_schema_versions_version_index ON phoenix_kit_schema_versions (version)"
    ]
    
    Enum.reduce_while(version_table_commands, :ok, fn sql, _acc ->
      case repo.query(sql) do
        {:ok, _} -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @doc """
  Records a schema version as applied.
  """
  def record_version(repo, version) do
    ensure_version_table(repo)
    
    insert_sql = """
    INSERT INTO phoenix_kit_schema_versions (version, applied_at)
    VALUES ($1, NOW())
    ON CONFLICT DO NOTHING
    """
    
    case repo.query(insert_sql, [version]) do
      {:ok, _} -> 
        Logger.info("[PhoenixKit] Recorded schema version #{version}")
        :ok
      {:error, error} -> 
        Logger.error("[PhoenixKit] Failed to record version #{version}: #{inspect(error)}")
        {:error, error}
    end
  end

  # Private functions

  defp version_table_exists?(repo) do
    query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_name = 'phoenix_kit_schema_versions'
    );
    """
    
    case repo.query(query) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end

  defp perform_fresh_install(repo) do
    Logger.info("[PhoenixKit] Performing fresh schema installation...")
    
    # Create current schema
    with :ok <- create_current_schema(repo),
         :ok <- record_version(repo, @current_schema_version) do
      Logger.info("[PhoenixKit] Fresh installation completed successfully")
      :ok
    else
      {:error, reason} ->
        Logger.error("[PhoenixKit] Fresh installation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp perform_upgrade(repo, from_version, to_version) do
    Logger.info("[PhoenixKit] Upgrading schema from #{from_version} to #{to_version}")
    
    # Get migration path
    migration_steps = get_migration_path(from_version, to_version)
    
    # Apply each migration step
    Enum.reduce_while(migration_steps, :ok, fn {from_v, to_v}, _acc ->
      case apply_migration_step(repo, from_v, to_v) do
        :ok -> 
          record_version(repo, to_v)
          {:cont, :ok}
        {:error, reason} -> 
          Logger.error("[PhoenixKit] Migration step #{from_v} -> #{to_v} failed: #{inspect(reason)}")
          {:halt, {:error, reason}}
      end
    end)
  end

  defp get_migration_path(from_version, to_version) do
    # For now, simple direct migration
    # In future versions, this could handle complex multi-step migrations
    [{from_version, to_version}]
  end

  defp apply_migration_step(repo, _from_version, to_version) do
    case to_version do
      "1.0.0" ->
        # Migration to version 1.0.0 (current)
        migrate_to_1_0_0(repo)
      _ ->
        Logger.error("[PhoenixKit] Unknown migration target version: #{to_version}")
        {:error, "Unknown target version"}
    end
  end

  defp migrate_to_1_0_0(repo) do
    Logger.info("[PhoenixKit] Applying migration to schema version 1.0.0")
    
    # This migration ensures we have the current schema
    # It's safe to run multiple times (idempotent)
    # Execute each command separately to avoid prepared statement issues
    migration_commands = [
      "CREATE EXTENSION IF NOT EXISTS citext",
      """
      CREATE TABLE IF NOT EXISTS phoenix_kit (
        id bigserial PRIMARY KEY,
        email citext NOT NULL,
        hashed_password varchar(255) NOT NULL,
        confirmed_at timestamp,
        inserted_at timestamp NOT NULL DEFAULT NOW(),
        updated_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_email_index ON phoenix_kit (email)",
      """
      CREATE TABLE IF NOT EXISTS phoenix_kit_tokens (
        id bigserial PRIMARY KEY,
        user_id bigint NOT NULL REFERENCES phoenix_kit(id) ON DELETE CASCADE,
        token bytea NOT NULL,
        context varchar(255) NOT NULL,
        sent_to varchar(255),
        inserted_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE INDEX IF NOT EXISTS phoenix_kit_tokens_user_id_index ON phoenix_kit_tokens (user_id)",
      "CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_tokens_context_token_index ON phoenix_kit_tokens (context, token)"
    ]
    
    # Execute each command separately
    Enum.reduce_while(migration_commands, :ok, fn sql, _acc ->
      case repo.query(sql) do
        {:ok, _} -> 
          {:cont, :ok}
        {:error, error} -> 
          Logger.error("[PhoenixKit] Schema migration to 1.0.0 failed on command: #{String.slice(sql, 0, 50)}...")
          Logger.error("[PhoenixKit] Error: #{inspect(error)}")
          {:halt, {:error, error}}
      end
    end)
    |> case do
      :ok -> 
        Logger.info("[PhoenixKit] Schema migration to 1.0.0 completed successfully")
        :ok
      error -> 
        error
    end
  end

  defp create_current_schema(repo) do
    # Create the current schema (same as migrate_to_1_0_0)
    migrate_to_1_0_0(repo)
  end

  defp version_compare(v1, v2) when is_binary(v1) and is_binary(v2) do
    # Simple semantic version comparison
    v1_parts = v1 |> String.split(".") |> Enum.map(&String.to_integer/1)
    v2_parts = v2 |> String.split(".") |> Enum.map(&String.to_integer/1)
    
    compare_version_parts(v1_parts, v2_parts)
  end

  defp compare_version_parts([], []), do: :eq
  defp compare_version_parts([h1 | _t1], [h2 | _t2]) when h1 < h2, do: :lt
  defp compare_version_parts([h1 | _t1], [h2 | _t2]) when h1 > h2, do: :gt
  defp compare_version_parts([h1 | t1], [h2 | t2]) when h1 == h2, do: compare_version_parts(t1, t2)
  defp compare_version_parts([], [_ | _]), do: :lt
  defp compare_version_parts([_ | _], []), do: :gt
end