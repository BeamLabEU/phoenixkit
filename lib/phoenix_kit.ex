defmodule PhoenixKit do
  @moduledoc """
  PhoenixKit - A powerful extension library for Phoenix Framework.

  This library provides additional functionality, pages, and components
  that can be easily integrated into any Phoenix application.

  ## Features

  - Dashboard with real-time metrics
  - Pre-built UI components
  - Utility functions for common Phoenix tasks
  - Easy installation and configuration

  ## Usage

  Add the routes to your Phoenix router:

      import PhoenixKit
      
      scope "/" do
        pipe_through :browser
        
        PhoenixKit.routes()
      end

  """

  @doc """
  Returns the configuration for PhoenixKit routes.

  This macro generates the necessary routes for the PhoenixKit extension.
  It includes both traditional controller routes and LiveView routes.

  ## Example

      # In your router.ex
      import PhoenixKit
      
      scope "/" do
        pipe_through :browser
        PhoenixKit.routes()
      end

  """
  defmacro routes do
    quote do
      import Phoenix.LiveView.Router

      scope "/phoenix_kit", PhoenixKit do
        pipe_through :browser

        # Traditional controller routes
        get "/", PageController, :index
        get "/dashboard", DashboardController, :index
        get "/components", ComponentsController, :index
        get "/utilities", UtilitiesController, :index

        # API routes for dashboard data
        scope "/api" do
          pipe_through :api
          get "/stats", DashboardController, :stats
          get "/metrics", DashboardController, :metrics
        end

        # LiveView routes
        live "/live", DashboardLive, :index
        live "/live/stats", StatsLive, :index
        live "/live/monitor", MonitorLive, :index
      end
    end
  end

  @version "0.3.0"

  @doc """
  Returns the current version of PhoenixKit.
  """
  def version, do: @version

  @doc """
  Returns configuration for PhoenixKit.

  ## Options

  - `:enable_dashboard` - Enable/disable dashboard (default: true)
  - `:enable_live_view` - Enable/disable LiveView components (default: true)
  - `:custom_theme` - Custom theme configuration

  """
  def config do
    Application.get_env(:phoenix_kit, PhoenixKit, [])
  end

  @doc """
  Returns whether a specific feature is enabled.
  """
  def feature_enabled?(feature) when is_atom(feature) do
    config()
    |> Keyword.get(feature, true)
  end

  @doc """
  Helper function to inject PhoenixKit assets into a Phoenix application.
  """
  def inject_assets do
    """
    <!-- PhoenixKit Styles -->
    <link rel="stylesheet" href="/phoenix_kit/assets/css/phoenix_kit.css">

    <!-- PhoenixKit Scripts -->
    <script src="/phoenix_kit/assets/js/phoenix_kit.js"></script>
    """
  end

  @doc """
  Returns comprehensive system information and statistics.
  """
  def system_info do
    %{
      version: version(),
      elixir_version: System.version(),
      otp_version: System.otp_release(),
      phoenix_version: get_phoenix_version(),
      uptime: get_uptime(),
      memory: get_memory_info(),
      process_count: :erlang.system_info(:process_count),
      config: config()
    }
  end

  # Private functions

  defp get_phoenix_version do
    case Application.spec(:phoenix, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> "Unknown"
    end
  end

  defp get_uptime do
    {uptime, _} = :erlang.statistics(:wall_clock)
    uptime
  end

  defp get_memory_info do
    %{
      total: :erlang.memory(:total),
      processes: :erlang.memory(:processes),
      system: :erlang.memory(:system),
      atom: :erlang.memory(:atom),
      binary: :erlang.memory(:binary),
      ets: :erlang.memory(:ets)
    }
  end
end
