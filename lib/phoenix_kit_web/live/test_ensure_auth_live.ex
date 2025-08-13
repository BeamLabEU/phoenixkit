defmodule PhoenixKitWeb.TestEnsureAuthLive do
  @moduledoc """
  Test component for phoenix_kit_ensure_authenticated authentication level.
  This page should only be accessible to authenticated users using PhoenixKit auth.
  """
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="hero py-8 min-h-[80vh] bg-success">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold text-success-content">phoenix_kit_ensure_authenticated</h1>
          <div class="py-6 text-success-content">
            <p class="mb-4">
              This page is protected by PhoenixKit <code>phoenix_kit_ensure_authenticated</code>.
              You can only see this if you are logged in through PhoenixKit auth system.
            </p>

            <%= if @current_user do %>
              <div class="alert alert-info">
                <div>
                  <h3 class="font-bold">Welcome, authenticated user!</h3>
                  <div class="text-sm">
                    <p><strong>Email:</strong> {@current_user.email}</p>
                    <p><strong>User ID:</strong> {@current_user.id}</p>
                    <%= if @current_user.confirmed_at do %>
                      <p><strong>Account:</strong> Confirmed at {@current_user.confirmed_at}</p>
                    <% else %>
                      <p><strong>Account:</strong> Not yet confirmed</p>
                    <% end %>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="alert alert-error">
                <div>
                  <p>This should never be visible - authentication is required!</p>
                </div>
              </div>
            <% end %>
          </div>
          <div class="badge badge-success">PhoenixKit Authentication: REQUIRED</div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
