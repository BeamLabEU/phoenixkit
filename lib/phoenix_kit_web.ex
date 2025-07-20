defmodule BeamLab.PhoenixKitWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use BeamLab.PhoenixKitWeb, :controller
      use BeamLab.PhoenixKitWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @doc """
  Macro for adding PhoenixKit authentication routes to your router.

  ## Usage

      defmodule YourAppWeb.Router do
        use YourAppWeb, :router
        import BeamLab.PhoenixKitWeb, only: [phoenix_kit_routes: 0]

        pipeline :browser do
          # ... your browser pipeline
          plug :fetch_current_scope_for_user
        end

        # Add PhoenixKit routes
        phoenix_kit_routes()
      end

  ## Options

  You can also use it with a custom scope prefix:

      phoenix_kit_routes("/custom_auth")

  """
  defmacro phoenix_kit_routes(scope_prefix \\ "/phoenix_kit_users") do
    quote do
      import BeamLab.PhoenixKitWeb.UserAuth,
        only: [fetch_current_scope_for_user: 2, redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]

      scope unquote(scope_prefix), BeamLab.PhoenixKitWeb do
        pipe_through [:browser, :redirect_if_user_is_authenticated]

        get "/register", UserRegistrationController, :new
        post "/register", UserRegistrationController, :create
      end

      scope unquote(scope_prefix), BeamLab.PhoenixKitWeb do
        pipe_through [:browser, :require_authenticated_user]

        get "/settings", UserSettingsController, :edit
        put "/settings", UserSettingsController, :update
        get "/settings/confirm-email/:token", UserSettingsController, :confirm_email
      end

      scope unquote(scope_prefix), BeamLab.PhoenixKitWeb do
        pipe_through [:browser]

        get "/log-in", UserSessionController, :new
        get "/log-in/:token", UserSessionController, :confirm
        post "/log-in", UserSessionController, :create
        delete "/log-out", UserSessionController, :delete
      end
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: BeamLab.PhoenixKitWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: BeamLab.PhoenixKitWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import BeamLab.PhoenixKitWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias BeamLab.PhoenixKitWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      # Use runtime endpoint detection for library mode
      use Phoenix.VerifiedRoutes,
        endpoint: BeamLab.PhoenixKitWeb.get_endpoint_module(),
        router: BeamLab.PhoenixKitWeb.Router,
        statics: BeamLab.PhoenixKitWeb.static_paths()
    end
  end

  @doc false
  def get_endpoint_module do
    if Application.get_env(:phoenix_kit, :library_mode, false) do
      Application.get_env(:phoenix_kit, :parent_endpoint, BeamLab.PhoenixKitWeb.Endpoint)
    else
      BeamLab.PhoenixKitWeb.Endpoint
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
