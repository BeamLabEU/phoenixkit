defmodule PhonixKit.Live.DashboardLive do
  @moduledoc """
  Простая LiveView страница dashboard с заголовком.
  """
  
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      title: "Dashboard",
      subtitle: "Панель управления PhonixKit"
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    title = params["title"] || socket.assigns.title
    subtitle = params["subtitle"] || socket.assigns.subtitle
    
    {:noreply, assign(socket, title: title, subtitle: subtitle)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-500 to-slate-700 flex items-center justify-center">
      <div class="text-center text-white px-4 max-w-2xl">
        <h1 class="text-6xl font-bold mb-4 transition-transform duration-300 hover:scale-105">
          <%= @title %>
        </h1>
        
        <p class="text-xl opacity-90 mb-8">
          <%= @subtitle %>
        </p>

        <div class="text-sm opacity-75">
          <p>📊 Простая dashboard страница</p>
          <p>⚡ Создана с помощью Phoenix LiveView</p>
        </div>
      </div>
    </div>
    """
  end
end