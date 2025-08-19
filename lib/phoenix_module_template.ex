defmodule PhoenixModuleTemplate do
  @external_resource "README.md"
  @version Mix.Project.config()[:version]

  @moduledoc """
  # Phoenix Module Template

  Professional template for developing Phoenix modules with PostgreSQL support.

  This library provides a solid foundation for creating reusable Phoenix modules
  that can be easily integrated into any Phoenix application.

  ## Features

  - Library-first architecture with no circular dependencies
  - PostgreSQL integration with Ecto
  - Professional code organization and testing
  - Optional Phoenix components and plugs
  - Ready for Hex package publishing

  ## Quick Start

  Add to your `mix.exs`:

      def deps do
        [
          {:phoenix_module_template, "~> #{@version}"}
        ]
      end

  ## Usage Examples

      # Basic usage
      {:ok, result} = PhoenixModuleTemplate.create_example(%{name: "test"})
      
      # List all examples
      examples = PhoenixModuleTemplate.list_examples()

  ## Configuration

  Configure in your `config.exs`:

      config :phoenix_module_template,
        repo: MyApp.Repo,
        custom_setting: "value"

  For more information, see the [documentation](https://hexdocs.pm/phoenix_module_template).
  """

  alias PhoenixModuleTemplate.Context

  @doc """
  Returns the version of the Phoenix Module Template.

  ## Examples

      iex> PhoenixModuleTemplate.version()
      "0.1.0"

  """
  @spec version() :: String.t()
  def version, do: @version

  @doc """
  Returns configuration for the module.

  ## Examples

      iex> PhoenixModuleTemplate.config()
      [repo: MyApp.Repo, custom_setting: "value"]

  """
  @spec config() :: Keyword.t()
  def config do
    Application.get_all_env(:phoenix_module_template)
  end

  @doc """
  Returns the configured repository module.

  Defaults to the first available Ecto repository if not configured.
  """
  @spec repo() :: module()
  def repo do
    case Application.get_env(:phoenix_module_template, :repo) do
      nil -> detect_repo()
      repo when is_atom(repo) -> repo
    end
  end

  # Public API - delegates to context

  @doc """
  Creates a new example record.

  ## Parameters

  - `attrs` - A map of attributes for the example

  ## Examples

      iex> PhoenixModuleTemplate.create_example(%{name: "Test"})
      {:ok, %PhoenixModuleTemplate.Schema.Example{}}

      iex> PhoenixModuleTemplate.create_example(%{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  defdelegate create_example(attrs), to: Context

  @doc """
  Lists all example records.

  ## Examples

      iex> PhoenixModuleTemplate.list_examples()
      [%PhoenixModuleTemplate.Schema.Example{}, ...]

  """
  @spec list_examples() :: [struct()]
  defdelegate list_examples(), to: Context

  @doc """
  Gets a single example by ID.

  ## Parameters

  - `id` - The ID of the example to retrieve

  ## Examples

      iex> PhoenixModuleTemplate.get_example(123)
      %PhoenixModuleTemplate.Schema.Example{}

      iex> PhoenixModuleTemplate.get_example(456)
      nil

  """
  @spec get_example(integer()) :: struct() | nil
  defdelegate get_example(id), to: Context

  @doc """
  Updates an example record.

  ## Parameters

  - `example` - The example struct to update
  - `attrs` - A map of attributes to update

  ## Examples

      iex> PhoenixModuleTemplate.update_example(example, %{name: "Updated"})
      {:ok, %PhoenixModuleTemplate.Schema.Example{}}

  """
  @spec update_example(struct(), map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  defdelegate update_example(example, attrs), to: Context

  @doc """
  Deletes an example record.

  ## Parameters

  - `example` - The example struct to delete

  ## Examples

      iex> PhoenixModuleTemplate.delete_example(example)
      {:ok, %PhoenixModuleTemplate.Schema.Example{}}

  """
  @spec delete_example(struct()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  defdelegate delete_example(example), to: Context

  # Private helpers

  defp detect_repo do
    # Try to find the first available Ecto repository
    :application.which_applications()
    |> Enum.find_value(fn {app, _, _} ->
      case Application.get_env(app, :ecto_repos) do
        [repo | _] -> repo
        _ -> nil
      end
    end) ||
      raise """
      No Ecto repository found. Please configure a repository:

          config :phoenix_module_template, repo: MyApp.Repo

      """
  end
end
