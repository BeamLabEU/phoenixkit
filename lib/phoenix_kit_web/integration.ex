defmodule PhoenixKitWeb.Integration do
  @moduledoc """
  Integration helpers for adding PhoenixKit authentication to parent Phoenix applications.

  This module provides helper functions and macros to easily integrate PhoenixKit's
  authentication system into existing Phoenix applications using the forward pattern.
  """

  @doc """
  Adds PhoenixKit authentication routes to your router.

  ## Usage

  In your main application's router.ex:

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        
        # Add this line to import the helper
        import PhoenixKitWeb.Integration
        
        # ... your existing pipelines ...
        
        # Add PhoenixKit auth routes under /phoenix_kit prefix
        phoenix_kit_auth_routes("/phoenix_kit")
        
        # Or with custom prefix
        phoenix_kit_auth_routes("/auth")
      end

  ## Routes created

  The following routes will be available under your chosen prefix:

  - GET /register - User registration page
  - GET /log-in - User login page  
  - POST /log-in - User login form submission
  - DELETE /log-out - User logout
  - GET /reset-password - Password reset request page
  - GET /reset-password/:token - Password reset form
  - GET /settings - User settings page
  - GET /settings/confirm-email/:token - Email confirmation
  - GET /confirm/:token - Account confirmation
  - GET /confirm - Resend confirmation instructions

  ## Configuration

  Make sure your application is configured properly:

      # config/config.exs
      config :phoenix_kit,
        repo: MyApp.Repo
        
      # Add to your deps in mix.exs  
      {:phoenix_kit, "~> 0.1.0"}
  """
  defmacro phoenix_kit_auth_routes(prefix \\ "/phoenix_kit") do
    quote do
      scope unquote(prefix) do
        pipe_through :browser
        forward "/", PhoenixKitWeb.AuthRouter
      end
    end
  end

  @doc """
  Returns the configuration needed for PhoenixKit integration.

  Add this to your configuration files:

      # In config/config.exs
      config :phoenix_kit, repo: MyApp.Repo
  """
  def sample_config do
    """
    config :phoenix_kit,
      repo: MyApp.Repo
    """
  end

  @doc """
  Instructions for manual route setup if you prefer not to use the macro.
  """
  def manual_setup_instructions do
    """
    If you prefer to set up routes manually, add this to your router:

        scope "/phoenix_kit" do
          pipe_through :browser
          forward "/", PhoenixKitWeb.AuthRouter
        end
        
    Or for a custom path:
        
        scope "/auth" do  
          pipe_through :browser
          forward "/", PhoenixKitWeb.AuthRouter
        end
    """
  end
end
