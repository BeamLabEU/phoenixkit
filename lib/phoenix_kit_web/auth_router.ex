defmodule PhoenixKitWeb.AuthRouter do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
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


  scope "/" do
    pipe_through [:browser]

    # Test routes with static HTML forms
    get "/register", PhoenixKitWeb.TestController, :register
    post "/register", PhoenixKitWeb.TestController, :create_user
    get "/log_in", PhoenixKitWeb.TestController, :login
    
    # Original LiveView routes (commented out for testing)
    # live "/register", PhoenixKitWeb.UserRegistrationLive, :new
    # live "/log_in", PhoenixKitWeb.UserLoginLive, :new

    post "/log_in", PhoenixKitWeb.UserSessionController, :create

    delete "/log_out", PhoenixKitWeb.UserSessionController, :delete

    live "/reset_password", PhoenixKitWeb.UserForgotPasswordLive, :new
    live "/reset_password/:token", PhoenixKitWeb.UserResetPasswordLive, :edit

    live "/confirm/:token", PhoenixKitWeb.UserConfirmationLive, :edit
    live "/confirm", PhoenixKitWeb.UserConfirmationInstructionsLive, :new
  end

  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    live "/settings", PhoenixKitWeb.UserSettingsLive, :edit
    live "/settings/confirm_email/:token", PhoenixKitWeb.UserSettingsLive, :confirm_email
  end
end