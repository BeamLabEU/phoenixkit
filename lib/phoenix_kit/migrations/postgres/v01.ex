defmodule PhoenixKit.Migrations.Postgres.V01 do
  @moduledoc false

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    # Only create schema if it's not 'public' and create_schema is true
    if create? && prefix != "public", do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Create citext extension if not exists
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    # Create version tracking table (phoenix_kit)
    create_if_not_exists table(:phoenix_kit, primary_key: false, prefix: prefix) do
      add :id, :serial, primary_key: true
      add :version, :integer, null: false
      add :migrated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create_if_not_exists unique_index(:phoenix_kit, [:version], prefix: prefix)

    # Create users table (phoenix_kit_users)
    create_if_not_exists table(:phoenix_kit_users, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:phoenix_kit_users, [:email], prefix: prefix)

    # Create tokens table (phoenix_kit_users_tokens)
    create_if_not_exists table(:phoenix_kit_users_tokens, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true

      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all, prefix: prefix),
        null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false, type: :naive_datetime)
    end

    create_if_not_exists index(:phoenix_kit_users_tokens, [:user_id], prefix: prefix)

    create_if_not_exists unique_index(:phoenix_kit_users_tokens, [:context, :token],
                           prefix: prefix
                         )
  end

  def down(%{prefix: prefix}) do
    drop_if_exists table(:phoenix_kit_users_tokens, prefix: prefix)
    drop_if_exists table(:phoenix_kit_users, prefix: prefix)
    drop_if_exists table(:phoenix_kit, prefix: prefix)
  end
end
