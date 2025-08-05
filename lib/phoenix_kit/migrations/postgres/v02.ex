defmodule PhoenixKit.Migrations.Postgres.V02 do
  @moduledoc false

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    # Only create schema if it's not 'public' and create_schema is true
    if create? && prefix != "public", do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Create AI settings table
    create_if_not_exists table(:phoenix_kit_ai, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :setting_key, :string, null: false
      add :setting_value, :text
      # string, integer, float, boolean, json
      add :setting_type, :string, default: "string"
      add :description, :text
      add :is_active, :boolean, default: true
      add :updated_by, references(:phoenix_kit_users, on_delete: :nilify_all, prefix: prefix)

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:phoenix_kit_ai, [:setting_key], prefix: prefix)
    create_if_not_exists index(:phoenix_kit_ai, [:setting_type], prefix: prefix)
    create_if_not_exists index(:phoenix_kit_ai, [:is_active], prefix: prefix)
    create_if_not_exists index(:phoenix_kit_ai, [:updated_by], prefix: prefix)
  end

  def down(%{prefix: prefix}) do
    drop_if_exists table(:phoenix_kit_ai, prefix: prefix)
  end
end
