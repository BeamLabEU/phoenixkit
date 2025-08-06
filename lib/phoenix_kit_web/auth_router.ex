defmodule PhoenixKitWeb.AuthRouter do
  @moduledoc """
  Legacy authentication router for PhoenixKit.

  **DEPRECATED**: This module is kept for backward compatibility.
  Use `PhoenixKitWeb.Integration.phoenix_kit_routes/1` macro instead.

  This router provides basic forwarding to authentication routes but lacks
  the advanced features and proper pipeline configuration of the Integration module.

  ## Migration Path

  Replace usage of this router with the Integration macro:

      # Instead of:
      forward "/auth", PhoenixKitWeb.AuthRouter

      # Use:
      import PhoenixKitWeb.Integration
      phoenix_kit_routes("/auth")
  """
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import PhoenixKitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: PhoenixKit.LayoutConfig.get_root_layout()
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :phoenix_kit_redirect_if_authenticated do
    plug PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated
  end

  pipeline :require_authenticated do
    plug PhoenixKitWeb.UserAuth, :phoenix_kit_require_authenticated_user
  end

  scope "/" do
    pipe_through [:browser, :phoenix_kit_redirect_if_authenticated]

    # Test LiveView 
    live "/test", PhoenixKitWeb.TestLive, :index

    # LiveView routes for authentication
    live "/register", PhoenixKitWeb.UserRegistrationLive, :new
    live "/log_in", PhoenixKitWeb.UserLoginLive, :new

    post "/log_in", PhoenixKitWeb.UserSessionController, :create

    live "/reset_password", PhoenixKitWeb.UserForgotPasswordLive, :new
    live "/reset_password/:token", PhoenixKitWeb.UserResetPasswordLive, :edit
  end

  scope "/" do
    pipe_through [:browser]

    delete "/log_out", PhoenixKitWeb.UserSessionController, :delete
    get "/log_out", PhoenixKitWeb.UserSessionController, :get_logout

    live "/confirm/:token", PhoenixKitWeb.UserConfirmationLive, :edit
    live "/confirm", PhoenixKitWeb.UserConfirmationInstructionsLive, :new
  end

  scope "/" do
    pipe_through [:browser, :require_authenticated]

    live "/settings", PhoenixKitWeb.UserSettingsLive, :edit
    live "/settings/confirm_email/:token", PhoenixKitWeb.UserSettingsLive, :confirm_email
  end
end
