defmodule PhonixKit do
  @moduledoc """
  Минимальный Phoenix компонент для welcome страниц.
  """
  
  use Phoenix.Component

  @doc """
  Рендерит welcome страницу с градиентным фоном.
  
  ## Примеры:
  
      <PhonixKit.welcome title="Добро пожаловать!" />
      
      <PhonixKit.welcome title="Hello World" subtitle="Ваш проект готов!" />
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: "Phonix Kit успешно установлен"
  attr :class, :string, default: ""
  
  def welcome(assigns) do
    ~H"""
    <div class={"min-h-screen bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center #{@class}"}>
      <div class="text-center text-white px-4">
        <h1 class="text-6xl font-bold mb-4">
          <%= @title %>
        </h1>
        <p class="text-xl opacity-90">
          <%= @subtitle %>
        </p>
      </div>
    </div>
    """
  end
end