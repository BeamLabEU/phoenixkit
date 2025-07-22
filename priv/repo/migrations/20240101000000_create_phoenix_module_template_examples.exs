defmodule PhoenixModuleTemplate.Repo.Migrations.CreatePhoenixModuleTemplateExamples do
  @moduledoc """
  Migration for creating the phoenix_module_template_examples table.

  This migration demonstrates the proper naming convention for module-specific tables.
  The table name is prefixed with the module name to avoid conflicts.
  """

  use Ecto.Migration

  def up do
    create table(:phoenix_module_template_examples) do
      add :name, :string, null: false
      add :description, :text
      add :active, :boolean, default: true, null: false
      add :metadata, :jsonb

      timestamps(type: :naive_datetime)
    end

    # Add indexes for better performance
    create unique_index(:phoenix_module_template_examples, [:name])
    create index(:phoenix_module_template_examples, [:active])
    create index(:phoenix_module_template_examples, [:inserted_at])

    # Add index on metadata fields if needed (PostgreSQL JSONB)
    create index(:phoenix_module_template_examples, [:metadata], using: :gin)
  end

  def down do
    drop table(:phoenix_module_template_examples)
  end
end
