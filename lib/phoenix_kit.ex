defmodule PhoenixKit do
  @moduledoc """
  PhoenixKit - Professional authentication library for Phoenix applications.

  Provides streamlined authentication setup with support for:
  - User registration and login
  - Email confirmation 
  - Password reset
  - Magic link authentication
  - Session management
  - Layout integration

  ## Quick Start

      # Add to your router.ex
      use PhoenixKitWeb.Integration
      phoenix_kit_routes()

  ## Configuration

      config :phoenix_kit,
        repo: MyApp.Repo,
        layout: {MyAppWeb.Layouts, :app}
  """

  @doc """
  Returns the current version of PhoenixKit.

  ## Examples

      iex> PhoenixKit.version()
      "1.0.0"

  """
  @spec version() :: String.t()
  def version do
    Application.spec(:phoenix_kit, :vsn) |> to_string()
  end

  @doc """
  Validates if PhoenixKit is properly configured.

  Checks for required configuration keys and returns a status.

  ## Examples

      iex> PhoenixKit.configured?()
      false

  """
  @spec configured?() :: boolean()
  def configured? do
    case Application.get_env(:phoenix_kit, :repo) do
      nil -> false
      _repo -> true
    end
  end

  @doc """
  Returns PhoenixKit configuration.

  ## Examples

      iex> PhoenixKit.config()
      %{ecto_repos: []}

  """
  @spec config() :: map()
  def config do
    :phoenix_kit
    |> Application.get_all_env()
    |> Enum.into(%{})
  end
end
