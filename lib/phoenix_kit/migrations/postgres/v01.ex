defmodule PhoenixKit.Migrations.Postgres.V01 do
  @moduledoc false

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    if create?, do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Create citext extension if not exists
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    # Create users table (phoenix_kit)
    create_if_not_exists table(:phoenix_kit, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:phoenix_kit, [:email], prefix: prefix)

    # Create tokens table (phoenix_kit_tokens)
    create_if_not_exists table(:phoenix_kit_tokens, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :user_id, references(:phoenix_kit, on_delete: :delete_all, prefix: prefix), null: false
      add :token, :binary, null: false  
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false, type: :naive_datetime)
    end

    create_if_not_exists index(:phoenix_kit_tokens, [:user_id], prefix: prefix)
    create_if_not_exists unique_index(:phoenix_kit_tokens, [:context, :token], prefix: prefix)
  end

  def down(%{prefix: prefix}) do
    drop_if_exists table(:phoenix_kit_tokens, prefix: prefix)
    drop_if_exists table(:phoenix_kit, prefix: prefix)
  end
end