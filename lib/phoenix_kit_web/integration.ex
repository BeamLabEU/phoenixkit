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
        
        # Add PhoenixKit auth routes - they work independently of your :browser pipeline!
        phoenix_kit_auth_routes()  # Uses /phoenix_kit prefix by default
        
        # Or with custom prefix if needed
        phoenix_kit_auth_routes("/authentication")
      end

  **Note:** PhoenixKit routes work completely independently and don't require 
  your application's :browser pipeline. They create their own pipeline with 
  all necessary plugs for LiveView forms to work properly.

  ## Routes created

  The following routes will be available under /phoenix_kit prefix (or your custom prefix):

  - GET /phoenix_kit/register - User registration page
  - GET /phoenix_kit/log_in - User login page  
  - POST /phoenix_kit/log_in - User login form submission
  - DELETE /phoenix_kit/log_out - User logout
  - GET /phoenix_kit/log_out - User logout (direct URL access)
  - GET /phoenix_kit/reset_password - Password reset request page
  - GET /phoenix_kit/reset_password/:token - Password reset form
  - GET /phoenix_kit/settings - User settings page
  - GET /phoenix_kit/settings/confirm_email/:token - Email confirmation
  - GET /phoenix_kit/confirm/:token - Account confirmation
  - GET /phoenix_kit/confirm - Resend confirmation instructions

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
      # Define the auto-setup pipeline  
      pipeline :phoenix_kit_auto_setup do
        plug PhoenixKitWeb.Integration, :phoenix_kit_auto_setup
      end

      pipeline :phoenix_kit_redirect_if_authenticated do
        plug PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated
      end

      pipeline :phoenix_kit_require_authenticated do
        plug PhoenixKitWeb.UserAuth, :require_authenticated_user
      end
      
      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup, :phoenix_kit_redirect_if_authenticated]

        post "/log_in", UserSessionController, :create
      end

      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup]
        
        delete "/log_out", UserSessionController, :delete
        get "/log_out", UserSessionController, :get_logout
      end

      # LiveView routes with proper authentication
      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup]

        live_session :phoenix_kit_redirect_if_user_is_authenticated,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated}] do
          live "/test", TestLive, :index
          live "/register", UserRegistrationLive, :new
          live "/log_in", UserLoginLive, :new
          live "/reset_password", UserForgotPasswordLive, :new
          live "/reset_password/:token", UserResetPasswordLive, :edit
        end

        live_session :phoenix_kit_current_user,
          on_mount: [{PhoenixKitWeb.UserAuth, :mount_current_user}] do
          live "/confirm/:token", UserConfirmationLive, :edit
          live "/confirm", UserConfirmationInstructionsLive, :new
        end

        live_session :phoenix_kit_require_authenticated_user,
          on_mount: [{PhoenixKitWeb.UserAuth, :ensure_authenticated}] do
          live "/settings", UserSettingsLive, :edit
          live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
        end
      end
    end
  end

  @doc """
  Pipeline plug for automatic PhoenixKit setup.
  
  This plug ensures PhoenixKit is configured and database tables exist
  before handling any authentication requests.
  """
  def init(opts), do: opts
  
  def call(conn, :phoenix_kit_auto_setup) do
    unless PhoenixKit.AutoSetup.setup_complete?() do
      case PhoenixKit.AutoSetup.ensure_setup!() do
        :ok -> 
          conn
        {:error, reason} ->
          conn
          |> Plug.Conn.put_resp_content_type("text/html")
          |> Plug.Conn.send_resp(500, setup_error_page(reason))
          |> Plug.Conn.halt()
      end
    else
      conn
    end
  end

  defp setup_error_page(reason) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>PhoenixKit Setup Error</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .error { background: #fee; padding: 20px; border: 1px solid #fcc; border-radius: 5px; }
        .code { background: #f5f5f5; padding: 10px; font-family: monospace; }
      </style>
    </head>
    <body>
      <h1>PhoenixKit Auto-Setup Failed</h1>
      <div class="error">
        <p><strong>Error:</strong> #{inspect(reason)}</p>
        
        <p>Please ensure your Phoenix application has:</p>
        <ul>
          <li>A properly configured Ecto.Repo</li>
          <li>PostgreSQL database connection</li>
          <li>Database create/modify permissions</li>
        </ul>
        
        <p>For manual setup instructions, see: 
        <a href="https://github.com/BeamLabEU/phoenixkit">PhoenixKit Documentation</a></p>
      </div>
    </body>
    </html>
    """
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
