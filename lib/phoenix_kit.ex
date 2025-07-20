defmodule BeamLab.PhoenixKit do
  @moduledoc """
  # BeamLab Phoenix Kit

  A professional Phoenix authentication and UI component library.

  ## Overview

  PhoenixKit provides a complete authentication system with:
  - User registration, login, logout
  - Password reset and email confirmation
  - Configurable UI components with Tailwind CSS
  - Built-in security best practices

  ## Usage

  ### As a Library

  Add to your Phoenix application's dependencies:

      {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}

  ### Installation

  1. Run generators to add authentication:

      mix phx.gen.auth Accounts User users

  2. Add PhoenixKit routes to your router:

      use BeamLab.PhoenixKitWeb, :router

  3. Configure your application.

  ## Configuration

  Configure in your `config/config.exs`:

      config :phoenix_kit,
        mode: :library,  # or :standalone
        ecto_repos: [YourApp.Repo]

  ## Components

  - `BeamLab.PhoenixKit.Accounts` - User management context
  - `BeamLab.PhoenixKitWeb.Components` - Reusable UI components
  - `BeamLab.PhoenixKitWeb.UserAuth` - Authentication plugs

  """

  @version Mix.Project.config()[:version]

  @doc """
  Returns the version of PhoenixKit.

  ## Examples

      iex> BeamLab.PhoenixKit.version()
      "1.0.0"

  """
  def version, do: @version

  @doc """
  Returns the current mode of PhoenixKit (:standalone or :library).

  ## Examples

      iex> BeamLab.PhoenixKit.mode()
      :library

  """
  def mode do
    case {Mix.env(), Application.get_env(:phoenix_kit, :mode)} do
      {:dev, _} -> :standalone
      {:test, _} -> :standalone  # Always standalone in test for complete testing
      {_, :standalone} -> :standalone
      {_, :library} -> :library
      {_, nil} -> :library
      {_, _} -> :library
    end
  end

  @doc """
  Checks if PhoenixKit is running in standalone mode.

  ## Examples

      iex> BeamLab.PhoenixKit.standalone?()
      false

  """
  def standalone?, do: mode() == :standalone

  @doc """
  Checks if PhoenixKit is running in library mode.

  ## Examples

      iex> BeamLab.PhoenixKit.library?()
      true

  """
  def library?, do: mode() == :library

  @doc """
  Install PhoenixKit authentication system.
  
  This function provides a programmatic way to install PhoenixKit when Mix tasks
  are not available (e.g., when used as a git dependency).
  
  ## Examples
  
      # Complete installation
      BeamLab.PhoenixKit.install()
      
      # Custom scope prefix
      BeamLab.PhoenixKit.install(scope_prefix: "authentication")
      
      # Skip migrations
      BeamLab.PhoenixKit.install(no_migrations: true)
  
  For more options, see `BeamLab.PhoenixKit.Installer.install/1`.
  """
  defdelegate install(options \\ []), to: BeamLab.PhoenixKit.Installer

  @doc """
  Generate PhoenixKit database migrations.
  
  ## Examples
  
      BeamLab.PhoenixKit.generate_migrations()
      BeamLab.PhoenixKit.generate_migrations(force: true)
  """
  defdelegate generate_migrations(options \\ []), to: BeamLab.PhoenixKit.Installer

  @doc """
  Generate PhoenixKit router configuration.
  
  ## Examples
  
      BeamLab.PhoenixKit.generate_routes()
      BeamLab.PhoenixKit.generate_routes(scope_prefix: "auth", dry_run: true)
  """
  defdelegate generate_routes(options \\ []), to: BeamLab.PhoenixKit.Installer

  @doc """
  Show router configuration example.
  
  Useful when automatic router generation is not possible.
  
  ## Examples
  
      BeamLab.PhoenixKit.show_router_example()
      BeamLab.PhoenixKit.show_router_example("authentication")
  """
  defdelegate show_router_example(scope_prefix \\ "auth"), to: BeamLab.PhoenixKit.Installer

  # Delegate to Accounts context for easier API
  defdelegate register_user(attrs), to: BeamLab.PhoenixKit.Accounts
  defdelegate get_user!(id), to: BeamLab.PhoenixKit.Accounts
  defdelegate get_user_by_email(email), to: BeamLab.PhoenixKit.Accounts
  defdelegate update_user_password(user, attrs), to: BeamLab.PhoenixKit.Accounts
end
