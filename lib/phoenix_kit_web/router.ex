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

  scope "/", PhoenixKitWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixKitWeb do
  #   pipe_through :api
  # end

  # LiveDashboard routes removed - this is a library module
  # Parent applications should include their own LiveDashboard configuration

  ## Authentication routes

  scope "/", PhoenixKitWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PhoenixKitWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/phoenix_kit/register", UserRegistrationLive, :new
      live "/phoenix_kit/log_in", UserLoginLive, :new
      live "/phoenix_kit/reset_password", UserForgotPasswordLive, :new
      live "/phoenix_kit/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/phoenix_kit/log_in", UserSessionController, :create
  end

  scope "/", PhoenixKitWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :ensure_authenticated}] do
      live "/phoenix_kit/settings", UserSettingsLive, :edit
      live "/phoenix_kit/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", PhoenixKitWeb do
    pipe_through [:browser]

    delete "/phoenix_kit/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PhoenixKitWeb.UserAuth, :mount_current_user}] do
      live "/phoenix_kit/confirm/:token", UserConfirmationLive, :edit
      live "/phoenix_kit/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
