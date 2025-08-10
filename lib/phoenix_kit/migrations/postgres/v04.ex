defmodule PhoenixKit.Migrations.Postgres.V04 do
  @moduledoc """
  Migration V04: Add roles2 field to phoenix_kit_users table

  Adds secondary role field with enum-like values:
  - guest (default)
  - member
  - editor
  - owner
  """

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts
    table_name = :phoenix_kit_users

    # Only create schema if it's not 'public' and create_schema is true
    if create? && prefix != "public", do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Add roles2 column with default value for existing users
    alter table(table_name, prefix: prefix) do
      add :roles2, :string, size: 20, default: "guest", null: false
    end

    # Create index for fast roles2-based queries
    create_if_not_exists index(table_name, [:roles2],
                           prefix: prefix,
                           name: "#{prefix}phoenix_kit_users_roles2_index"
                         )

    # Add constraint for value validation
    execute """
    ALTER TABLE #{if prefix != "public", do: "#{prefix}.", else: ""}phoenix_kit_users
    ADD CONSTRAINT #{prefix}phoenix_kit_users_roles2_check 
    CHECK (roles2 IN ('guest', 'member', 'editor', 'owner'))
    """
  end

  def down(%{prefix: prefix}) do
    table_name = :phoenix_kit_users

    # Remove constraint first (must be before column drop)
    execute """
    ALTER TABLE #{if prefix != "public", do: "#{prefix}.", else: ""}phoenix_kit_users
    DROP CONSTRAINT IF EXISTS #{prefix}phoenix_kit_users_roles2_check
    """

    # Remove index
    drop_if_exists index(table_name, [:roles2],
                     prefix: prefix,
                     name: "#{prefix}phoenix_kit_users_roles2_index"
                   )

    # Remove roles2 column
    alter table(table_name, prefix: prefix) do
      remove :roles2
    end
  end
end
