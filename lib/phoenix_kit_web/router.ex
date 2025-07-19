defmodule BeamLab.PhoenixKitWeb.Router do
  use BeamLab.PhoenixKitWeb, :router

  import BeamLab.PhoenixKitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BeamLab.PhoenixKitWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", BeamLab.PhoenixKitWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:phoenix_kit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BeamLab.PhoenixKitWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/phoenix_kit_users/register", UserRegistrationController, :new
    post "/phoenix_kit_users/register", UserRegistrationController, :create
  end

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/phoenix_kit_users/settings", UserSettingsController, :edit
    put "/phoenix_kit_users/settings", UserSettingsController, :update
    get "/phoenix_kit_users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser]

    get "/phoenix_kit_users/log-in", UserSessionController, :new
    get "/phoenix_kit_users/log-in/:token", UserSessionController, :confirm
    post "/phoenix_kit_users/log-in", UserSessionController, :create
    delete "/phoenix_kit_users/log-out", UserSessionController, :delete
  end
end
