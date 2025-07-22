defmodule BeamLab.PhoenixKitWeb.AuthRouter do
  @moduledoc """
  Router module that handles all PhoenixKit authentication routes.
  
  This module is designed to be used with `Phoenix.Router.forward/4`
  to delegate authentication routes to PhoenixKit.
  """

  use BeamLab.PhoenixKitWeb, :router

  import BeamLab.PhoenixKitWeb.UserAuth,
    only: [redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]

  pipeline :phoenix_kit_auth do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    # LIBRARY MODE: Do NOT override parent app layout
    # plug :put_root_layout, html: {BeamLab.PhoenixKitWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Registration routes
  scope "/" do
    pipe_through [:phoenix_kit_auth, :redirect_if_user_is_authenticated]

    get "/register", BeamLab.PhoenixKitWeb.UserRegistrationController, :new
    post "/register", BeamLab.PhoenixKitWeb.UserRegistrationController, :create
  end

  # Authenticated user routes  
  scope "/" do
    pipe_through [:phoenix_kit_auth, :require_authenticated_user]

    get "/settings", BeamLab.PhoenixKitWeb.UserSettingsController, :edit
    put "/settings", BeamLab.PhoenixKitWeb.UserSettingsController, :update
    get "/settings/confirm-email/:token", BeamLab.PhoenixKitWeb.UserSettingsController, :confirm_email
  end

  # Session routes (public)
  scope "/" do
    pipe_through :phoenix_kit_auth

    get "/log-in", BeamLab.PhoenixKitWeb.UserSessionController, :new
    get "/log-in/:token", BeamLab.PhoenixKitWeb.UserSessionController, :confirm
    post "/log-in", BeamLab.PhoenixKitWeb.UserSessionController, :create
    delete "/log-out", BeamLab.PhoenixKitWeb.UserSessionController, :delete
  end
end