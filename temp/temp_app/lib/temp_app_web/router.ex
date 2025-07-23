defmodule TempAppWeb.Router do
  use TempAppWeb, :router
  
  # Import PhoenixKit integration helpers
  import PhoenixKitWeb.Integration

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TempAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TempAppWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Add PhoenixKit authentication routes  
  phoenix_kit_auth_routes()

  # Other scopes may use custom stacks.
  # scope "/api", TempAppWeb do
  #   pipe_through :api
  # end
end
