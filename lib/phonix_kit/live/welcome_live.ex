defmodule PhonixKit.Live.WelcomeLive do
  @moduledoc """
  Интерактивная LiveView страница приветствия с анимациями и счетчиком.
  """
  
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      title: "Добро пожаловать!",
      subtitle: "PhonixKit LiveView успешно работает",
      counter: 0,
      animated: false
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    title = params["title"] || socket.assigns.title
    subtitle = params["subtitle"] || socket.assigns.subtitle
    
    {:noreply, assign(socket, title: title, subtitle: subtitle)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, counter: socket.assigns.counter + 1)}
  end

  @impl true
  def handle_event("decrement", _params, socket) do
    new_counter = max(0, socket.assigns.counter - 1)
    {:noreply, assign(socket, counter: new_counter)}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, counter: 0)}
  end

  @impl true
  def handle_event("toggle_animation", _params, socket) do
    {:noreply, assign(socket, animated: !socket.assigns.animated)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center transition-all duration-500 #{if @animated, do: "animate-pulse"}"}>
      <div class="text-center text-white px-4 max-w-2xl">
        <h1 class="text-6xl font-bold mb-4 transition-transform duration-300 hover:scale-105">
          <%= @title %>
        </h1>
        
        <p class="text-xl opacity-90 mb-8">
          <%= @subtitle %>
        </p>

        <!-- Интерактивный счетчик -->
        <div class="bg-white bg-opacity-20 rounded-lg p-6 mb-6 backdrop-blur-sm">
          <h2 class="text-2xl font-semibold mb-4">Интерактивный счетчик</h2>
          
          <div class="text-4xl font-bold mb-4 transition-all duration-300">
            <%= @counter %>
          </div>
          
          <div class="flex justify-center gap-4 flex-wrap">
            <button 
              phx-click="decrement"
              class="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded transition-colors duration-200"
            >
              −
            </button>
            
            <button 
              phx-click="increment"
              class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded transition-colors duration-200"
            >
              +
            </button>
            
            <button 
              phx-click="reset"
              class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded transition-colors duration-200"
            >
              Сброс
            </button>
          </div>
        </div>

        <!-- Анимация -->
        <div class="mb-6">
          <button 
            phx-click="toggle_animation"
            class="bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-2 px-6 rounded transition-colors duration-200"
          >
            <%= if @animated, do: "⏸️ Остановить анимацию", else: "▶️ Включить анимацию" %>
          </button>
        </div>

        <!-- Информация -->
        <div class="text-sm opacity-75">
          <p>🚀 Это LiveView страница с реальным временем обновления</p>
          <p>✨ Все взаимодействия происходят без JavaScript</p>
        </div>
      </div>
    </div>
    """
  end
end