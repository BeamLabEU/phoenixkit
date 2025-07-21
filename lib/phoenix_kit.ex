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
  DEPRECATED: PhoenixKit now works without installation commands.
  
  PhoenixKit v1.0.0+ follows Phoenix best practices and works out-of-the-box.
  No installation commands are needed.
  
  ## Migration Guide
  
      # Old way (deprecated)
      BeamLab.PhoenixKit.install()
      
      # New way (zero-configuration)
      # 1. Add to your router.ex:
      import BeamLab.PhoenixKitWeb.Router
      phoenix_kit()
      
      # 2. Add migrations: 
      mix ecto.gen.migration add_phoenix_kit_auth_tables
      # Then copy content from deps/phoenix_kit/priv/repo/migrations/
      
      # That's it! No installation needed.
  
  The new approach follows Phoenix LiveDashboard pattern for better integration.
  """
  def install(_options \\ []) do
    IO.warn("BeamLab.PhoenixKit.install/1 is deprecated. PhoenixKit now works without installation commands.")
    
    IO.puts("""
    
    🎉 PhoenixKit v1.0.0+ works without installation!
    
    ## New Simple Integration:
    
    1. Add to your router.ex:
    
       import BeamLab.PhoenixKitWeb.Router
       phoenix_kit()
    
    2. Generate migrations:
    
       mix ecto.gen.migration add_phoenix_kit_auth_tables
       # Copy from: deps/phoenix_kit/priv/repo/migrations/
    
    3. Run migrations:
    
       mix ecto.migrate
    
    That's it! No installation commands needed.
    Routes automatically available at /auth/register, /auth/log-in, etc.
    """)
    
    :ok
  end

  @doc """
  DEPRECATED: Use standard Phoenix migration approach.
  
  ## Migration Guide
  
      # Old way (deprecated)
      BeamLab.PhoenixKit.generate_migrations()
      
      # New way (standard Phoenix)
      mix ecto.gen.migration add_phoenix_kit_auth_tables
      # Then copy from deps/phoenix_kit/priv/repo/migrations/
  """
  def generate_migrations(_options \\ []) do
    IO.warn("BeamLab.PhoenixKit.generate_migrations/1 is deprecated. Use standard Phoenix migrations.")
    IO.puts("Copy migrations from deps/phoenix_kit/priv/repo/migrations/ to your project.")
    :ok
  end

  @doc """
  Generate PhoenixKit router configuration.
  
  ## Examples
  
      BeamLab.PhoenixKit.generate_routes()
      BeamLab.PhoenixKit.generate_routes(scope_prefix: "auth", dry_run: true)
  """
  def generate_routes(options \\ []), do: BeamLab.PhoenixKit.Installer.generate_routes(options)

  @doc """
  Show router configuration example.
  
  Useful when automatic router generation is not possible.
  
  ## Examples
  
      BeamLab.PhoenixKit.show_router_example()
      BeamLab.PhoenixKit.show_router_example("authentication")
  """
  def show_router_example(scope_prefix \\ "/phoenix_kit_users"), do: BeamLab.PhoenixKit.Installer.show_router_example(scope_prefix)

  # Delegate to Accounts context for easier API
  defdelegate register_user(attrs), to: BeamLab.PhoenixKit.Accounts
  defdelegate get_user!(id), to: BeamLab.PhoenixKit.Accounts
  defdelegate get_user_by_email(email), to: BeamLab.PhoenixKit.Accounts
  defdelegate update_user_password(user, attrs), to: BeamLab.PhoenixKit.Accounts
end
