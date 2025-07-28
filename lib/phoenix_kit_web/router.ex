defmodule PhoenixKitWeb.Router do
  use PhoenixKitWeb, :router

  import PhoenixKitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixKitWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :phoenix_kit_redirect_if_authenticated do
    plug PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated
  end

  pipeline :require_authenticated do
    plug :require_authenticated_user
  end

  scope "/", PhoenixKitWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Authentication routes with LiveView integration (with /phoenix_kit prefix for library usage)
  scope "/phoenix_kit", PhoenixKitWeb do
    pipe_through [:browser, :phoenix_kit_redirect_if_authenticated]

    post "/log_in", UserSessionController, :create
  end

  scope "/phoenix_kit", PhoenixKitWeb do
    pipe_through :browser
    
    delete "/log_out", UserSessionController, :delete
    get "/log_out", UserSessionController, :get_logout
  end

  # LiveView routes with proper authentication
  scope "/phoenix_kit", PhoenixKitWeb do
    pipe_through :browser

    live_session :phoenix_kit_redirect_if_user_is_authenticated,
      on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated}] do
      live "/test", TestLive, :index
      live "/register", UserRegistrationLive, :new
      live "/log_in", UserLoginLive, :new
      live "/reset_password", UserForgotPasswordLive, :new
      live "/reset_password/:token", UserResetPasswordLive, :edit
    end

    live_session :current_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :mount_current_user}] do
      live "/confirm/:token", UserConfirmationLive, :edit
      live "/confirm", UserConfirmationInstructionsLive, :new
    end

    live_session :require_authenticated_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :ensure_authenticated}] do
      live "/settings", UserSettingsLive, :edit
      live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixKitWeb do
  #   pipe_through :api
  # end

  # LiveDashboard routes removed - this is a library module
  # Parent applications should include their own LiveDashboard configuration

  ## Authentication routes are now handled by AuthRouter via forward
  ## All PhoenixKit routes are available under /phoenix_kit/
end
