defmodule BeamLab.PhoenixKitWeb.Router do
  @moduledoc """
  Phoenix router functions for PhoenixKit authentication.
  
  This module provides simple routing functions to integrate PhoenixKit 
  authentication into Phoenix applications following Phoenix best practices.
  
  ## Usage
  
      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import BeamLab.PhoenixKitWeb.Router
  
        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_live_flash
          plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
          plug :protect_from_forgery
          plug :put_secure_browser_headers
          plug :fetch_current_scope_for_user  # PhoenixKit auth
        end
  
        scope "/" do
          pipe_through :browser
          get "/", PageController, :home
        end
  
        # PhoenixKit authentication - one line!
        phoenix_kit()
      end
  
  That's it! All authentication routes are automatically available:
  - `/phoenix_kit/register`
  - `/phoenix_kit/log-in` 
  - `/phoenix_kit/log-out`
  - `/phoenix_kit/settings`
  
  ## Options
  
  You can customize the authentication setup:
  
      phoenix_kit(require_confirmation: true)
      
  Available options:
  - `:require_confirmation` - Require email confirmation (default: false)
  - `:session_validity_in_days` - Session validity period (default: 60)
  """

  @doc """
  Adds PhoenixKit authentication routes to your Phoenix router.
  
  This function follows the same pattern as Phoenix LiveDashboard,
  providing a simple one-line integration for authentication.
  
  ## Examples
  
      phoenix_kit()
      phoenix_kit(require_confirmation: true)
  
  This function will:
  - Add all authentication routes with `/phoenix_kit/` prefix
  - Import required authentication functions  
  - Configure the necessary plugs
  
  ## Generated Routes
  
  PhoenixKit always uses `/phoenix_kit/` prefix for consistency and to avoid conflicts:
  
  - `GET /phoenix_kit/register` - New user registration form
  - `POST /phoenix_kit/register` - Create new user account
  - `GET /phoenix_kit/log-in` - User login form  
  - `POST /phoenix_kit/log-in` - Authenticate user
  - `GET /phoenix_kit/log-in/:token` - Magic link login
  - `GET /phoenix_kit/settings` - User settings page
  - `PUT /phoenix_kit/settings` - Update user settings
  - `DELETE /phoenix_kit/log-out` - Log out user
  
  """
  defmacro phoenix_kit(opts \\ []) do
    quote do
      # Import authentication functions into the calling router
      import BeamLab.PhoenixKitWeb.UserAuth,
        only: [fetch_current_scope_for_user: 2, redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]

      # Configure PhoenixKit options at runtime
      BeamLab.PhoenixKitWeb.Router.__configure__(unquote(opts))

      # Always forward to /phoenix_kit routes regardless of user's path choice
      forward "/phoenix_kit", BeamLab.PhoenixKitWeb.AuthRouter
    end
  end

  @doc false
  def __configure__(opts) do
    # Store configuration for runtime use
    Application.put_env(:phoenix_kit, :auth_options, opts)
    
    # Ensure library mode is enabled when used as router
    Application.put_env(:phoenix_kit, :mode, :library)
    
    # Set parent endpoint if not already configured
    unless Application.get_env(:phoenix_kit, :parent_endpoint) do
      # This will be set by the parent application's endpoint
      Application.put_env(:phoenix_kit, :parent_endpoint, nil)
    end
    
    :ok
  end
end