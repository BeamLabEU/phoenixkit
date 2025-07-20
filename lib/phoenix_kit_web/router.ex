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
  # Skip dev routes in library mode to avoid dependency issues
  if Application.compile_env(:phoenix_kit, :dev_routes) and 
     not Application.compile_env(:phoenix_kit, :library_mode, false) do
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
