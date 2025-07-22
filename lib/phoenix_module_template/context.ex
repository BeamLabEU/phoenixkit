defmodule PhoenixModuleTemplate.Context do
  @moduledoc """
  The Context module for PhoenixModuleTemplate.

  This module contains the business logic for managing examples.
  It follows Phoenix's context pattern for organizing domain logic.
  """

  import Ecto.Query, warn: false

  alias PhoenixModuleTemplate.Schema.Example

  @doc """
  Returns the list of examples.

  ## Examples

      iex> list_examples()
      [%Example{}, ...]

  """
  def list_examples do
    repo().all(Example)
  end

  @doc """
  Gets a single example.

  Returns `nil` if the Example does not exist.

  ## Examples

      iex> get_example(123)
      %Example{}

      iex> get_example(456)
      nil

  """
  def get_example(id), do: repo().get(Example, id)

  @doc """
  Gets a single example by a given field.

  Returns `nil` if the Example does not exist.

  ## Examples

      iex> get_example_by(name: "test")
      %Example{}

      iex> get_example_by(name: "nonexistent")
      nil

  """
  def get_example_by(clauses), do: repo().get_by(Example, clauses)

  @doc """
  Creates an example.

  ## Examples

      iex> create_example(%{name: "test"})
      {:ok, %Example{}}

      iex> create_example(%{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_example(attrs \\ %{}) do
    %Example{}
    |> Example.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates an example.

  ## Examples

      iex> update_example(example, %{name: "new name"})
      {:ok, %Example{}}

      iex> update_example(example, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_example(%Example{} = example, attrs) do
    example
    |> Example.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes an example.

  ## Examples

      iex> delete_example(example)
      {:ok, %Example{}}

      iex> delete_example(example)
      {:error, %Ecto.Changeset{}}

  """
  def delete_example(%Example{} = example) do
    repo().delete(example)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking example changes.

  ## Examples

      iex> change_example(example)
      %Ecto.Changeset{data: %Example{}}

  """
  def change_example(%Example{} = example, attrs \\ %{}) do
    Example.changeset(example, attrs)
  end

  @doc """
  Returns the count of examples.

  ## Examples

      iex> count_examples()
      42

  """
  def count_examples do
    repo().aggregate(Example, :count)
  end

  @doc """
  Returns examples with pagination.

  ## Examples

      iex> list_examples_paginated(page: 1, per_page: 10)
      %{examples: [...], total_count: 42, page: 1, per_page: 10}

  """
  def list_examples_paginated(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    offset = (page - 1) * per_page

    examples =
      Example
      |> limit(^per_page)
      |> offset(^offset)
      |> repo().all()

    total_count = count_examples()

    %{
      examples: examples,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: div(total_count + per_page - 1, per_page)
    }
  end

  @doc """
  Searches examples by name.

  ## Examples

      iex> search_examples("test")
      [%Example{name: "test example"}, ...]

  """
  def search_examples(query) when is_binary(query) do
    search_term = "%#{query}%"

    Example
    |> where([e], ilike(e.name, ^search_term) or ilike(e.description, ^search_term))
    |> repo().all()
  end

  # Private helper to get the configured repository
  defp repo do
    PhoenixModuleTemplate.repo()
  end
end
