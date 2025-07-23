defmodule PhoenixKitWeb.AuthRouter do
  @moduledoc """
  Router for authentication routes that can be forwarded by parent applications.

  This router contains all authentication-related routes that will be available
  under the configured prefix when integrated into a parent Phoenix application.

  Usage in parent application:

      scope "/phoenix_kit" do
        pipe_through :browser
        forward "/", PhoenixKitWeb.AuthRouter
      end
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
    plug :put_root_layout, html: {PhoenixKitWeb.Layouts, :auth_minimal}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :auth_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixKitWeb.Layouts, :auth_minimal}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  ## Authentication routes for forwarding

  scope "/" do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      layout: {PhoenixKitWeb.Layouts, :auth_app},
      on_mount: [{PhoenixKitWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/register", PhoenixKitWeb.UserRegistrationLive, :new
      live "/log-in", PhoenixKitWeb.UserLoginLive, :new
      live "/reset-password", PhoenixKitWeb.UserForgotPasswordLive, :new
      live "/reset-password/:token", PhoenixKitWeb.UserResetPasswordLive, :edit
    end

    post "/log-in", PhoenixKitWeb.UserSessionController, :create
  end

  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :ensure_authenticated}] do
      live "/settings", PhoenixKitWeb.UserSettingsLive, :edit
      live "/settings/confirm-email/:token", PhoenixKitWeb.UserSettingsLive, :confirm_email
    end
  end

  scope "/" do
    pipe_through [:browser]

    delete "/log-out", PhoenixKitWeb.UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :mount_current_user}] do
      live "/confirm/:token", PhoenixKitWeb.UserConfirmationLive, :edit
      live "/confirm", PhoenixKitWeb.UserConfirmationInstructionsLive, :new
    end
  end
end
