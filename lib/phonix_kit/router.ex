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
      
      live unquote(path) <> "/dashboard", PhonixKit.Live.DashboardLive, :index
      live unquote(path) <> "/dashboard/:title", PhonixKit.Live.DashboardLive, :index
      live unquote(path) <> "/dashboard/:title/:subtitle", PhonixKit.Live.DashboardLive, :index
    end
  end
  
  @doc """
  Альтернативный способ добавления только welcome маршрута.
  
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
  
  @doc """
  Альтернативный способ добавления только dashboard маршрута.
  
  ## Пример:
  
      scope "/" do
        pipe_through :browser
        phonix_kit_dashboard_route()
      end
  """
  defmacro phonix_kit_dashboard_route(path \\ "/dashboard") do
    quote do
      import Phoenix.Router
      
      live unquote(path), PhonixKit.Live.DashboardLive, :index
    end
  end
end