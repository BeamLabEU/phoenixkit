defmodule PhoenixKit.Repo.Migrations.CreatePhoenixKitAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:phoenix_kit) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      timestamps()
    end

    create unique_index(:phoenix_kit, [:email])

    create table(:phoenix_kit_tokens) do
      add :user_id, references(:phoenix_kit, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:phoenix_kit_tokens, [:user_id])
    create unique_index(:phoenix_kit_tokens, [:context, :token])
  end
end
