defmodule PhoenixKitWeb.TestRequireAuthLive do
  @moduledoc """
  Test component for phoenix_kit_mount_current_user authentication level.
  This page shows current user information without requiring authentication.
  """
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="hero py-8 min-h-[80vh] bg-info">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold text-info-content">phoenix_kit_mount_current_user</h1>
          <div class="py-6 text-info-content">
            <p class="mb-4">
              This page uses PhoenixKit <code>phoenix_kit_mount_current_user</code>.
              It mounts current user without requiring authentication.
            </p>

            <%= if @current_user do %>
              <div class="alert alert-success">
                <div>
                  <h3 class="font-bold">User is logged in!</h3>
                  <div class="text-sm">
                    <p><strong>Email:</strong> {@current_user.email}</p>
                    <p><strong>ID:</strong> {@current_user.id}</p>
                    <%= if @current_user.confirmed_at do %>
                      <p><strong>Status:</strong> Confirmed</p>
                    <% else %>
                      <p><strong>Status:</strong> Not confirmed</p>
                    <% end %>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="alert alert-warning">
                <div>
                  <h3 class="font-bold">No user logged in</h3>
                  <p class="text-sm">Page is accessible but current_user is nil</p>
                </div>
              </div>
            <% end %>
          </div>
          <div class="badge badge-info">PhoenixKit Mount: ALWAYS ACCESSIBLE</div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
