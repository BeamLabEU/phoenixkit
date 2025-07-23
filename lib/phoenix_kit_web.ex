defmodule PhoenixKitWeb do
  @moduledoc """
  The web interface for PhoenixKit authentication module.

  This module provides the base functionality for web components
  including controllers, live views, and components used for
  user authentication and management.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PhoenixKitWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: PhoenixKitWeb.Layouts]

      import Plug.Conn
      import PhoenixKitWeb.Gettext
      import PhoenixKitWeb.CoreComponents

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PhoenixKitWeb.Layouts, :app}

      import PhoenixKitWeb.Gettext
      import PhoenixKitWeb.CoreComponents

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import PhoenixKitWeb.Gettext

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      import PhoenixKitWeb.CoreComponents
      import PhoenixKitWeb.Gettext

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.LiveView.Helpers

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PhoenixKitWeb.Endpoint,
        router: PhoenixKitWeb.Router,
        statics: PhoenixKitWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end