defmodule PhoenixKit do
  @moduledoc """
  PhoenixKit is a professional authentication library for Phoenix applications with zero-config setup.

  PhoenixKit provides a complete, production-ready authentication system that integrates seamlessly 
  into any Phoenix application. It follows Oban-style architecture with versioned migrations and 
  automatic configuration detection.

  ## Features

  - **Zero-Config Setup** - Automatic repository detection and configuration
  - **Complete Authentication** - Registration, login, logout, email confirmation, password reset
  - **Professional Database Management** - Versioned migrations with rollback support  
  - **Library-First Design** - No OTP application, integrates into any Phoenix app
  - **LiveView Ready** - All authentication pages use Phoenix LiveView
  - **Production Ready** - Comprehensive error handling and logging
  - **Magic Link Authentication** - Optional passwordless authentication
  - **Layout Integration** - Seamless integration with your app's layouts

  ## Quick Start

  Add PhoenixKit to your Phoenix application:

      # mix.exs
      def deps do
        [
          {:phoenix_kit, "~> 0.1.14"},
          {:igniter, "~> 0.6.0", only: [:dev]}
        ]
      end

  Install and configure PhoenixKit:

      mix deps.get
      mix phoenix_kit.install

  This automatically:
  - Detects your Ecto repository
  - Creates database migrations
  - Configures your Phoenix router
  - Sets up authentication routes
  - Adds layout integration

  ## Core Modules

  ### Authentication Context

  - `PhoenixKit.Users.Auth` - Main authentication context with user management functions
  - `PhoenixKit.Users.Auth.User` - User schema with email-based authentication
  - `PhoenixKit.Users.Auth.UserToken` - Token management for email confirmation and password reset
  - `PhoenixKit.Users.Auth.MagicLink` - Optional passwordless authentication system

  ### Web Integration  

  - `PhoenixKitWeb.Integration` - Router integration macros and helpers
  - `PhoenixKitWeb.Users.Auth` - Plugs and authentication helpers
  - `PhoenixKit.LayoutConfig` - Layout integration with parent applications

  ### Database Management

  - `PhoenixKit.Migration` - Database migration utilities and PostgreSQL support
  - `PhoenixKit.Repo` - Repository configuration and helpers

  ### Configuration

  - `PhoenixKit.Config` - Configuration management with environment variable support
  - `PhoenixKit.ConfigEnv` - Environment-based configuration loading

  ## Installation Methods

  ### Semi-Automatic (Recommended)

  Uses Igniter for automated setup:

      mix phoenix_kit.install

  ### Manual Integration

  Add routes to your router:

      # router.ex
      use PhoenixKitWeb.Integration

      scope "/" do
        pipe_through :browser
        phoenix_kit_routes()
      end

  Configure your application:

      # config/config.exs  
      config :phoenix_kit,
        repo: MyApp.Repo

      # config/dev.exs
      config :phoenix_kit, PhoenixKit.Mailer,
        adapter: Swoosh.Adapters.Local

  ## Layout Integration

  PhoenixKit automatically integrates with your app's layouts:

      # config/config.exs
      config :phoenix_kit,
        layout: {MyAppWeb.Layouts, :app},
        root_layout: {MyAppWeb.Layouts, :root}

  Access current user in layouts:

      <!-- app.html.heex -->
      <%= if assigns[:phoenix_kit_current_user] do %>
        <p>Welcome, <%= @phoenix_kit_current_user.email %>!</p>
      <% else %>
        <%= link "Sign in", to: ~p"/phoenix_kit/users/log_in" %>
      <% end %>

  ## Authentication Routes

  PhoenixKit provides these routes by default:

  - `GET /phoenix_kit/users/register` - User registration
  - `GET /phoenix_kit/users/log_in` - User login  
  - `DELETE /phoenix_kit/users/log_out` - User logout
  - `GET /phoenix_kit/users/confirm` - Email confirmation
  - `GET /phoenix_kit/users/reset_password` - Password reset
  - `GET /phoenix_kit/users/settings` - User settings

  ## LiveView Integration

  Protect your LiveView pages with on_mount callbacks:

      # router.ex
      live_session :authenticated, on_mount: [:phoenix_kit_mount_current_user, :phoenix_kit_ensure_authenticated] do
        scope "/admin" do
          pipe_through [:browser]
          live "/dashboard", MyAppWeb.DashboardLive
        end
      end

  ## Database Migrations

  PhoenixKit uses a professional versioned migration system:

      # Check current version
      mix phoenix_kit.update --status

      # Update to latest version  
      mix phoenix_kit.update

      # Generate custom migration
      mix phoenix_kit.gen.migration AddCustomField

  ## Configuration

  PhoenixKit supports various configuration options:

      config :phoenix_kit,
        repo: MyApp.Repo,
        layout: {MyAppWeb.Layouts, :app},
        page_title_prefix: "Auth"

      config :phoenix_kit, PhoenixKit.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: "smtp.example.com"

  ## Production Deployment

  PhoenixKit is production-ready with:

  - Secure password hashing with bcrypt
  - Email confirmation workflow
  - Session management
  - Comprehensive error handling
  - Database connection pooling
  - Proper logging and telemetry

  ## Examples

  ### Creating a User

      {:ok, user} = PhoenixKit.Users.Auth.register_user(%{
        email: "user@example.com", 
        password: "secure_password123"
      })

  ### Authenticating

      case PhoenixKit.Users.Auth.get_user_by_email_and_password(email, password) do
        %User{} = user -> {:ok, user}
        nil -> {:error, :invalid_credentials}
      end

  ### Magic Link Authentication

      # Generate magic link
      {:ok, link} = PhoenixKit.Users.Auth.MagicLink.generate_magic_link(user)
      
      # Send via email
      PhoenixKit.Mailer.deliver_magic_link_email(user, link)

  ## More Information

  For detailed documentation, visit:
  - [HexDocs](https://hexdocs.pm/phoenix_kit)
  - [GitHub](https://github.com/BeamLabEU/phoenixkit)

  For common integration patterns, see `PhoenixKitWeb.Integration`.
  """

  @doc """
  Returns the current version of PhoenixKit.

  ## Examples

      iex> PhoenixKit.version()
      "0.1.14"

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
      true

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
      %{repo: MyApp.Repo, layout: {MyAppWeb.Layouts, :app}}

  """
  @spec config() :: map()
  def config do
    :phoenix_kit
    |> Application.get_all_env()
    |> Enum.into(%{})
  end
end
