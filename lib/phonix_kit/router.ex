defmodule PhonixKit.Router do
  @moduledoc """
  Router helper для автоматического добавления PhonixKit маршрутов.
  
  ## Использование
  
  В вашем router.ex добавьте:
  
      import PhonixKit.Router
      
      scope "/" do
        pipe_through :browser
        phonix_kit_routes()
      end
      
  Или с кастомным путем:
  
      scope "/" do
        pipe_through :browser
        phonix_kit_routes("/welcome")
      end
  """

  defmacro phonix_kit_routes(path \\ "/phonix-kit") do
    quote do
      import Phoenix.Router
      
      live unquote(path), PhonixKit.Live.WelcomeLive, :index
      live unquote(path) <> "/:title", PhonixKit.Live.WelcomeLive, :index
      live unquote(path) <> "/:title/:subtitle", PhonixKit.Live.WelcomeLive, :index
    end
  end
  
  @doc """
  Альтернативный способ добавления только основного маршрута.
  
  ## Пример:
  
      scope "/" do
        pipe_through :browser
        phonix_kit_welcome_route()
      end
  """
  defmacro phonix_kit_welcome_route(path \\ "/welcome") do
    quote do
      import Phoenix.Router
      
      live unquote(path), PhonixKit.Live.WelcomeLive, :index
    end
  end
end