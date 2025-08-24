defmodule PhoenixKitWeb.Live.DashboardLive do
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Users.Roles

  def mount(_params, _session, socket) do
    # Load extended statistics including activity and confirmation status
    stats = Roles.get_extended_stats()

    # Get PhoenixKit version from application specification
    version = Application.spec(:phoenix_kit, :vsn) |> to_string()

    socket =
      socket
      |> assign(:stats, stats)
      |> assign(:phoenix_kit_version, version)

    {:ok, socket}
  end

  def handle_event("refresh_stats", _params, socket) do
    stats = Roles.get_extended_stats()

    socket =
      socket
      |> assign(:stats, stats)
      |> put_flash(:info, "Statistics refreshed successfully")

    {:noreply, socket}
  end
end
