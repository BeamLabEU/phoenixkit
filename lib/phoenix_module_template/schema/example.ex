defmodule PhoenixModuleTemplate.Schema.Example do
  @moduledoc """
  Example schema for PhoenixModuleTemplate.

  This schema demonstrates how to structure database entities in a Phoenix module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          description: String.t() | nil,
          active: boolean(),
          metadata: map() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "phoenix_module_template_examples" do
    field :name, :string
    field :description, :string
    field :active, :boolean, default: true
    field :metadata, :map

    timestamps(type: :naive_datetime)
  end

  @doc """
  Creates a changeset for the example.

  ## Parameters

  - `example` - The example struct (can be %Example{} for creation)
  - `attrs` - Map of attributes to change

  ## Examples

      iex> changeset(%Example{}, %{name: "Test"})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Example{}, %{name: ""})
      %Ecto.Changeset{valid?: false}

  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(example, attrs) do
    example
    |> cast(attrs, [:name, :description, :active, :metadata])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> unique_constraint(:name)
  end

  @doc """
  Creates a changeset for updating the example.

  Similar to `changeset/2` but may have different validation rules for updates.
  """
  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(example, attrs) do
    example
    |> cast(attrs, [:name, :description, :active, :metadata])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, max: 1000)
    |> unique_constraint(:name)
  end

  @doc """
  Creates a changeset for creating a new example with default values.
  """
  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> put_change(:active, Map.get(attrs, :active, true))
  end

  @doc """
  Validates metadata structure if present.

  This can be customized based on your specific metadata requirements.
  """
  @spec validate_metadata(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_metadata(changeset) do
    case get_field(changeset, :metadata) do
      nil -> changeset
      metadata when is_map(metadata) -> changeset
      _ -> add_error(changeset, :metadata, "must be a valid map")
    end
  end
end
