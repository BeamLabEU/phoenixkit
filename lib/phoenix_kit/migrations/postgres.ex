defmodule PhoenixKit.Migrations.Postgres do
  @moduledoc false

  @behaviour PhoenixKit.Migration

  use Ecto.Migration

  @initial_version 1
  @current_version 2
  @default_prefix "public"

  @doc false
  def initial_version, do: @initial_version

  @doc false
  def current_version, do: @current_version

  @impl PhoenixKit.Migration
  def up(opts) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        # Check if we're in runtime context (has :repo key)
        if Map.has_key?(opts, :repo) do
          runtime_up(opts)
        else
          change(@initial_version..opts.version, :up, opts)
        end

      initial < opts.version ->
        if Map.has_key?(opts, :repo) do
          runtime_up(opts)
        else
          change((initial + 1)..opts.version, :up, opts)
        end

      true ->
        :ok
    end
  end

  @impl PhoenixKit.Migration
  def down(opts) do
    opts = with_defaults(opts, @initial_version)
    current_version = migrated_version(opts)

    # Determine target version:
    # - If version not specified, rollback to complete removal (0)
    # - If version specified, rollback to that version
    target_version =
      case Map.get(opts, :version) do
        # Complete removal (state before installation)
        nil -> 0
        specified_version -> specified_version
      end

    if current_version > target_version do
      # For rollback from version N to version M, execute down for versions N, N-1, ..., M+1
      # This means we don't execute down for the target version itself
      change(current_version..(target_version + 1)//-1, :down, opts)
    end
  end

  @impl PhoenixKit.Migration
  def migrated_version(opts) do
    opts = with_defaults(opts, @initial_version)

    repo =
      case Map.get(opts, :repo) do
        nil ->
          try do
            repo()
          rescue
            _error ->
              # Fallback for auto-setup context
              case Application.get_env(:phoenix_kit, :repo) do
                nil -> reraise "No repo configured", __STACKTRACE__
                configured_repo -> configured_repo
              end
          end

        configured_repo ->
          configured_repo
      end

    escaped_prefix = Map.fetch!(opts, :escaped_prefix)

    query = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'phoenix_kit'
    AND pg_namespace.nspname = '#{escaped_prefix}'
    """

    case repo.query(query, [], log: false) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> String.to_integer(version)
      _ -> 0
    end
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad_idx = String.pad_leading(to_string(index), 2, "0")

      [__MODULE__, "V#{pad_idx}"]
      |> Module.concat()
      |> apply(direction, [opts])
    end

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, Enum.min(range) - 1)
    end
  end

  defp record_version(_opts, 0) do
    # Handle rollback to version 0 - tables are dropped, so we can't update comment
    # This is expected behavior for complete rollback
    :ok
  end

  defp record_version(%{prefix: prefix, repo: repo}, version) do
    sql = "COMMENT ON TABLE #{inspect(prefix)}.phoenix_kit IS '#{version}'"

    case repo.query(sql) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp record_version(%{prefix: prefix}, version) do
    # Fallback for migration context - use execute
    execute "COMMENT ON TABLE #{inspect(prefix)}.phoenix_kit IS '#{version}'"
  end

  # Runtime migration for auto-setup context
  defp runtime_up(%{repo: repo, prefix: prefix} = opts) do
    migration_commands = [
      "CREATE EXTENSION IF NOT EXISTS citext",
      """
      CREATE TABLE IF NOT EXISTS #{prefix}.phoenix_kit (
        id serial PRIMARY KEY,
        version integer NOT NULL,
        migrated_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_version_index ON #{prefix}.phoenix_kit (version)",
      """
      CREATE TABLE IF NOT EXISTS #{prefix}.phoenix_kit_users (
        id bigserial PRIMARY KEY,
        email citext NOT NULL,
        hashed_password varchar(255) NOT NULL,
        confirmed_at timestamp,
        inserted_at timestamp NOT NULL DEFAULT NOW(),
        updated_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_users_email_index ON #{prefix}.phoenix_kit_users (email)",
      """
      CREATE TABLE IF NOT EXISTS #{prefix}.phoenix_kit_users_tokens (
        id bigserial PRIMARY KEY,
        user_id bigint NOT NULL REFERENCES #{prefix}.phoenix_kit_users(id) ON DELETE CASCADE,
        token bytea NOT NULL,
        context varchar(255) NOT NULL,
        sent_to varchar(255),
        inserted_at timestamp NOT NULL DEFAULT NOW()
      )
      """,
      "CREATE INDEX IF NOT EXISTS phoenix_kit_users_tokens_user_id_index ON #{prefix}.phoenix_kit_users_tokens (user_id)",
      "CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_users_tokens_context_token_index ON #{prefix}.phoenix_kit_users_tokens (context, token)"
    ]

    # Execute each command
    Enum.reduce_while(migration_commands, :ok, fn sql, _acc ->
      case repo.query(sql) do
        {:ok, _} -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      :ok ->
        record_version(opts, @current_version)

      error ->
        error
    end
  end

  defp with_defaults(opts, version) do
    opts = Enum.into(opts, %{prefix: @default_prefix, version: version})

    opts
    |> Map.put(:quoted_prefix, inspect(opts.prefix))
    |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "\\'"))
    |> Map.put_new(:create_schema, opts.prefix != @default_prefix)
  end
end
