defmodule PhoenixKit.Migrations.Postgres.V03 do
  @moduledoc """
  Migration V03: Add role field to phoenix_kit_users table
  
  Adds user role support with enum-like values:
  - user (default)
  - moderator  
  - admin
  """

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts
    table_name = :phoenix_kit_users

    # Only create schema if it's not 'public' and create_schema is true
    if create? && prefix != "public", do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Add role column with default value for existing users
    alter table(table_name, prefix: prefix) do
      add :role, :string, size: 20, default: "user", null: false
    end

    # Create index for fast role-based queries
    create_if_not_exists index(table_name, [:role], prefix: prefix, name: "#{prefix}phoenix_kit_users_role_index")

    # Add constraint for value validation
    execute """
    ALTER TABLE #{if prefix != "public", do: "#{prefix}.", else: ""}phoenix_kit_users
    ADD CONSTRAINT #{prefix}phoenix_kit_users_role_check 
    CHECK (role IN ('user', 'moderator', 'admin'))
    """
  end

  def down(%{prefix: prefix}) do
    table_name = :phoenix_kit_users

    # Remove constraint first (must be before column drop)
    execute """
    ALTER TABLE #{if prefix != "public", do: "#{prefix}.", else: ""}phoenix_kit_users
    DROP CONSTRAINT IF EXISTS #{prefix}phoenix_kit_users_role_check
    """

    # Remove index
    drop_if_exists index(table_name, [:role], prefix: prefix, name: "#{prefix}phoenix_kit_users_role_index")

    # Remove role column
    alter table(table_name, prefix: prefix) do
      remove :role
    end
  end
end