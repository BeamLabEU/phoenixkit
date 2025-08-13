defmodule PhoenixKitWeb.TestRedirectIfAuthLive do
  @moduledoc """
  Test component for redirect_if_user_is_authenticated authentication level.
  This page should redirect authenticated users away (like login/register pages).
  """
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="hero py-8 min-h-[80vh] bg-base-300">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold text-warning">redirect_if_user_is_authenticated</h1>
          <p class="py-6">
            This page is protected by <code>redirect_if_user_is_authenticated</code> authentication.
            If you are logged in, you should be redirected away from this page.
          </p>
          <div class="badge badge-warning">Authentication: REDIRECT IF LOGGED IN</div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
