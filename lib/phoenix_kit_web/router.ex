defmodule BeamLab.PhoenixKitWeb.StandaloneRouter do
  use BeamLab.PhoenixKitWeb, :router

  import BeamLab.PhoenixKitWeb.UserAuth,
    only: [fetch_current_scope_for_user: 2, redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]

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
  import BeamLab.PhoenixKitWeb.DevRoutes
  dev_routes()

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
