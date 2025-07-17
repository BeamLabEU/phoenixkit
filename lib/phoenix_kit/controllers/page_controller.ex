defmodule PhoenixKit.PageController do
  use Phoenix.Controller,
    formats: [:html, :json]

  import Plug.Conn
  import Phoenix.HTML

  alias PhoenixKit.PageHTML

  @moduledoc """
  Main page controller for PhoenixKit extension.

  Handles the landing page and general information display.
  """

  @doc """
  Renders the main PhoenixKit landing page.
  """
  def index(conn, _params) do
    stats = %{
      version: PhoenixKit.version(),
      features: get_available_features(),
      status: "active"
    }

    conn
    |> put_view(PageHTML)
    |> render(:index,
      title: "PhoenixKit - Phoenix Framework Extension",
      subtitle: "Powerful tools and components for your Phoenix application",
      stats: stats,
      features: get_feature_list()
    )
  end

  defp get_available_features do
    [
      dashboard: PhoenixKit.feature_enabled?(:enable_dashboard),
      live_view: PhoenixKit.feature_enabled?(:enable_live_view),
      components: true,
      utilities: true
    ]
  end

  defp get_feature_list do
    [
      %{
        title: "Real-time Dashboard",
        description: "Monitor your application with live metrics and statistics",
        icon: "📊",
        link: "/phoenix_kit/dashboard"
      },
      %{
        title: "LiveView Components",
        description: "Interactive components powered by Phoenix LiveView",
        icon: "⚡",
        link: "/phoenix_kit/live"
      },
      %{
        title: "UI Components",
        description: "Pre-built, customizable UI components",
        icon: "🎨",
        link: "/phoenix_kit/components"
      },
      %{
        title: "Utilities",
        description: "Helper functions and development tools",
        icon: "🛠️",
        link: "/phoenix_kit/utilities"
      }
    ]
  end
end
