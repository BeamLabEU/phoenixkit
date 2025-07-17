defmodule PhoenixKit.DashboardController do
  use Phoenix.Controller,
    formats: [:html, :json]

  import Plug.Conn
  import Phoenix.HTML

  alias PhoenixKit.DashboardHTML

  @moduledoc """
  Dashboard controller for PhoenixKit extension.

  Provides system monitoring, metrics, and analytics functionality.
  """

  @doc """
  Renders the main dashboard page with system overview.
  """
  def index(conn, _params) do
    dashboard_data = get_dashboard_data()

    conn
    |> put_view(DashboardHTML)
    |> render(:index,
      title: "PhoenixKit Dashboard",
      stats: dashboard_data.stats,
      charts: dashboard_data.charts,
      recent_activity: dashboard_data.recent_activity
    )
  end

  @doc """
  API endpoint for fetching current system statistics.
  Returns JSON data for AJAX requests.
  """
  def stats(conn, _params) do
    stats = get_system_stats()

    conn
    |> put_resp_content_type("application/json")
    |> json(stats)
  end

  @doc """
  API endpoint for fetching detailed metrics.
  """
  def metrics(conn, _params) do
    metrics = get_detailed_metrics()

    conn
    |> put_resp_content_type("application/json")
    |> json(metrics)
  end

  # Private helper functions

  defp get_detailed_metrics do
    %{
      system: get_system_stats(),
      memory: get_memory_details(),
      processes: get_process_details(),
      network: get_network_stats(),
      timestamp: DateTime.utc_now()
    }
  end

  defp get_memory_details do
    memory = :erlang.memory()

    %{
      total: memory[:total],
      processes: memory[:processes],
      system: memory[:system],
      atom: memory[:atom],
      binary: memory[:binary],
      code: memory[:code],
      ets: memory[:ets]
    }
  end

  defp get_process_details do
    %{
      count: :erlang.system_info(:process_count),
      limit: :erlang.system_info(:process_limit),
      run_queue: :erlang.statistics(:run_queue),
      reductions: :erlang.statistics(:reductions) |> elem(0)
    }
  end

  defp get_network_stats do
    %{
      active_connections: :rand.uniform(100),
      bytes_in: :rand.uniform(1_000_000),
      bytes_out: :rand.uniform(1_000_000)
    }
  end

  defp get_dashboard_data do
    %{
      stats: get_system_stats(),
      charts: get_chart_data(),
      recent_activity: get_recent_activity()
    }
  end

  defp get_system_stats do
    %{
      uptime: get_uptime(),
      memory_usage: get_memory_usage(),
      process_count: get_process_count(),
      request_count: get_request_count(),
      response_time: get_avg_response_time(),
      timestamp: DateTime.utc_now()
    }
  end

  defp get_chart_data do
    %{
      memory_timeline: generate_memory_timeline(),
      request_timeline: generate_request_timeline(),
      response_time_timeline: generate_response_time_timeline()
    }
  end

  defp get_recent_activity do
    [
      %{
        type: "info",
        message: "PhoenixKit dashboard initialized",
        timestamp: DateTime.utc_now() |> DateTime.add(-300, :second)
      },
      %{
        type: "success",
        message: "All systems operational",
        timestamp: DateTime.utc_now() |> DateTime.add(-150, :second)
      },
      %{
        type: "warning",
        message: "High memory usage detected",
        timestamp: DateTime.utc_now() |> DateTime.add(-60, :second)
      }
    ]
  end

  # System metric collection functions

  defp get_uptime do
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    uptime_ms
  end

  defp get_memory_usage do
    :erlang.memory(:total)
  end

  defp get_process_count do
    :erlang.system_info(:process_count)
  end

  defp get_request_count do
    # This would typically come from your application's metrics
    :rand.uniform(10000)
  end

  defp get_avg_response_time do
    # This would typically come from your application's metrics
    :rand.uniform(100) + 50
  end

  # Chart data generation (mock data for demonstration)

  defp generate_memory_timeline do
    1..20
    |> Enum.map(fn i ->
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-i * 60, :second),
        value: :rand.uniform(1000) + 500
      }
    end)
    |> Enum.reverse()
  end

  defp generate_request_timeline do
    1..20
    |> Enum.map(fn i ->
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-i * 60, :second),
        value: :rand.uniform(200) + 50
      }
    end)
    |> Enum.reverse()
  end

  defp generate_response_time_timeline do
    1..20
    |> Enum.map(fn i ->
      %{
        timestamp: DateTime.utc_now() |> DateTime.add(-i * 60, :second),
        value: :rand.uniform(50) + 25
      }
    end)
    |> Enum.reverse()
  end
end
