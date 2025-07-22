defmodule PhoenixModuleTemplate.ContextTest do
  @moduledoc """
  Tests for the PhoenixModuleTemplate.Context module.
  """

  use PhoenixModuleTemplate.DataCase

  alias PhoenixModuleTemplate.Context
  alias PhoenixModuleTemplate.Schema.Example

  describe "examples" do
    @valid_attrs %{name: "Test Example", description: "A test example", active: true}
    @update_attrs %{name: "Updated Example", description: "An updated example", active: false}
    @invalid_attrs %{name: nil, description: nil, active: nil}

    def example_fixture(attrs \\ %{}) do
      {:ok, example} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Context.create_example()

      example
    end

    test "list_examples/0 returns all examples" do
      example = example_fixture()
      assert Context.list_examples() == [example]
    end

    test "get_example/1 returns the example with given id" do
      example = example_fixture()
      assert Context.get_example(example.id) == example
    end

    test "get_example/1 returns nil for non-existent id" do
      assert Context.get_example(-1) == nil
    end

    test "get_example_by/1 returns the example with given criteria" do
      example = example_fixture()
      assert Context.get_example_by(name: example.name) == example
    end

    test "create_example/1 with valid data creates an example" do
      assert {:ok, %Example{} = example} = Context.create_example(@valid_attrs)
      assert example.name == "Test Example"
      assert example.description == "A test example"
      assert example.active == true
    end

    test "create_example/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Context.create_example(@invalid_attrs)
    end

    test "update_example/2 with valid data updates the example" do
      example = example_fixture()
      assert {:ok, %Example{} = example} = Context.update_example(example, @update_attrs)
      assert example.name == "Updated Example"
      assert example.description == "An updated example"
      assert example.active == false
    end

    test "update_example/2 with invalid data returns error changeset" do
      example = example_fixture()
      assert {:error, %Ecto.Changeset{}} = Context.update_example(example, @invalid_attrs)
      assert example == Context.get_example(example.id)
    end

    test "delete_example/1 deletes the example" do
      example = example_fixture()
      assert {:ok, %Example{}} = Context.delete_example(example)
      assert Context.get_example(example.id) == nil
    end

    test "change_example/1 returns an example changeset" do
      example = example_fixture()
      assert %Ecto.Changeset{} = Context.change_example(example)
    end

    test "count_examples/0 returns the count of examples" do
      assert Context.count_examples() == 0
      example_fixture()
      assert Context.count_examples() == 1
      example_fixture(%{name: "Another Example"})
      assert Context.count_examples() == 2
    end

    test "list_examples_paginated/1 returns paginated examples" do
      example1 = example_fixture()
      example2 = example_fixture(%{name: "Second Example"})

      result = Context.list_examples_paginated(page: 1, per_page: 1)

      assert result.page == 1
      assert result.per_page == 1
      assert result.total_count == 2
      assert result.total_pages == 2
      assert length(result.examples) == 1
    end

    test "search_examples/1 finds examples by name" do
      example = example_fixture(%{name: "Searchable Example"})
      example_fixture(%{name: "Other Example"})

      results = Context.search_examples("Searchable")
      assert length(results) == 1
      assert hd(results).id == example.id
    end

    test "search_examples/1 finds examples by description" do
      example = example_fixture(%{description: "Searchable description"})
      example_fixture(%{description: "Other description"})

      results = Context.search_examples("Searchable")
      assert length(results) == 1
      assert hd(results).id == example.id
    end
  end
end
