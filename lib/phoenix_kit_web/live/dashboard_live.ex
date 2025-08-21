defmodule PhoenixKitWeb.Live.DashboardLive do
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Users.Roles

  def mount(_params, _session, socket) do
    # Load initial statistics
    stats = Roles.get_role_stats()

    socket =
      socket
      |> assign(:stats, stats)

    {:ok, socket}
  end

  def handle_event("refresh_stats", _params, socket) do
    stats = Roles.get_role_stats()

    socket =
      socket
      |> assign(:stats, stats)
      |> put_flash(:info, "Statistics refreshed successfully")

    {:noreply, socket}
  end
end
