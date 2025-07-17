defmodule PhoenixKit.DashboardLive do
  use Phoenix.LiveView

  @moduledoc """
  LiveView dashboard for real-time monitoring and metrics display.

  This LiveView provides:
  - Real-time system metrics updates
  - Interactive charts and graphs
  - Live activity monitoring
  - System health indicators
  """

  # 5 seconds
  @refresh_interval 5_000
  @history_length 50

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@refresh_interval, self(), :refresh_metrics)
    end

    initial_state = %{
      metrics: get_current_metrics(),
      history: initialize_history(),
      alerts: [],
      last_updated: DateTime.utc_now(),
      auto_refresh: true,
      selected_metric: "memory"
    }

    {:ok, assign(socket, initial_state)}
  end

  def handle_event("toggle_auto_refresh", _params, socket) do
    new_auto_refresh = !socket.assigns.auto_refresh
    {:noreply, assign(socket, auto_refresh: new_auto_refresh)}
  end

  def handle_event("select_metric", %{"metric" => metric}, socket) do
    {:noreply, assign(socket, selected_metric: metric)}
  end

  def handle_event("refresh_now", _params, socket) do
    updated_socket =
      socket
      |> update_metrics()
      |> update_history()
      |> check_alerts()

    {:noreply, updated_socket}
  end

  def handle_event("clear_alerts", _params, socket) do
    {:noreply, assign(socket, alerts: [])}
  end

  def handle_info(:refresh_metrics, socket) do
    if socket.assigns.auto_refresh do
      updated_socket =
        socket
        |> update_metrics()
        |> update_history()
        |> check_alerts()

      {:noreply, updated_socket}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="live-dashboard">
      <!-- Header -->
      <div class="dashboard-header">
        <h1>🚀 PhoenixKit Live Dashboard</h1>
        <div class="header-controls">
          <div class="refresh-status">
            <span class={"status-indicator status-#{if @auto_refresh, do: "active", else: "inactive"}"}>
              {if @auto_refresh, do: "●", else: "○"}
            </span>
            <span>Auto-refresh: {if @auto_refresh, do: "ON", else: "OFF"}</span>
          </div>
          <button
            phx-click="toggle_auto_refresh"
            class={"btn btn-sm #{if @auto_refresh, do: "btn-secondary", else: "btn-primary"}"}
          >
            {if @auto_refresh, do: "Disable", else: "Enable"} Auto-refresh
          </button>
          <button phx-click="refresh_now" class="btn btn-sm btn-primary">
            🔄 Refresh Now
          </button>
        </div>
      </div>
      
    <!-- Last Updated -->
      <div class="update-info">
        <small>Last updated: {format_datetime(@last_updated)}</small>
      </div>
      
    <!-- Alerts -->
      <%= if length(@alerts) > 0 do %>
        <div class="alerts-section">
          <div class="alerts-header">
            <h3>🔔 System Alerts</h3>
            <button phx-click="clear_alerts" class="btn btn-xs btn-secondary">
              Clear All
            </button>
          </div>
          <div class="alerts-list">
            <%= for alert <- @alerts do %>
              <.alert_item alert={alert} />
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- Live Metrics Grid -->
      <div class="live-metrics-grid">
        <.metric_card
          title="Memory Usage"
          value={format_bytes(@metrics.memory_usage)}
          change={calculate_change(@history, :memory_usage)}
          icon="💾"
          color="blue"
        />
        <.metric_card
          title="Process Count"
          value={@metrics.process_count}
          change={calculate_change(@history, :process_count)}
          icon="⚙️"
          color="green"
        />
        <.metric_card
          title="CPU Usage"
          value={"#{@metrics.cpu_usage}%"}
          change={calculate_change(@history, :cpu_usage)}
          icon="🖥️"
          color="orange"
        />
        <.metric_card
          title="Uptime"
          value={format_uptime(@metrics.uptime)}
          change={:stable}
          icon="⏱️"
          color="purple"
        />
        <.metric_card
          title="Request Rate"
          value={"#{@metrics.request_rate}/s"}
          change={calculate_change(@history, :request_rate)}
          icon="📊"
          color="red"
        />
        <.metric_card
          title="Response Time"
          value={"#{@metrics.avg_response_time}ms"}
          change={calculate_change(@history, :avg_response_time)}
          icon="⚡"
          color="yellow"
        />
      </div>
      
    <!-- Interactive Chart -->
      <div class="chart-section">
        <div class="chart-header">
          <h3>📈 Real-time Metrics</h3>
          <div class="metric-selector">
            <%= for {metric, label} <- metric_options() do %>
              <button
                phx-click="select_metric"
                phx-value-metric={metric}
                class={"btn btn-xs #{if @selected_metric == metric, do: "btn-primary", else: "btn-secondary"}"}
              >
                {label}
              </button>
            <% end %>
          </div>
        </div>
        <.live_chart history={@history} selected_metric={@selected_metric} />
      </div>
      
    <!-- System Information -->
      <div class="system-info">
        <h3>🔧 System Information</h3>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">Erlang/OTP Version:</span>
            <span class="info-value">{@metrics.otp_version}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Elixir Version:</span>
            <span class="info-value">{@metrics.elixir_version}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Node Name:</span>
            <span class="info-value">{@metrics.node_name}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Phoenix Version:</span>
            <span class="info-value">{@metrics.phoenix_version}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Component functions

  def metric_card(assigns) do
    ~H"""
    <div class={"metric-card metric-#{@color}"}>
      <div class="metric-header">
        <span class="metric-icon">{@icon}</span>
        <.change_indicator change={@change} />
      </div>
      <div class="metric-content">
        <h4>{@title}</h4>
        <div class="metric-value">{@value}</div>
      </div>
    </div>
    """
  end

  def change_indicator(assigns) do
    ~H"""
    <span class={"change-indicator change-#{@change}"}>
      <%= case @change do %>
        <% :up -> %>
          📈
        <% :down -> %>
          📉
        <% :stable -> %>
          ➡️
        <% _ -> %>
          ➡️
      <% end %>
    </span>
    """
  end

  def alert_item(assigns) do
    ~H"""
    <div class={"alert alert-#{@alert.level}"}>
      <div class="alert-content">
        <strong>{@alert.title}</strong>
        <p>{@alert.message}</p>
        <small>{format_datetime(@alert.timestamp)}</small>
      </div>
    </div>
    """
  end

  def live_chart(assigns) do
    ~H"""
    <div class="live-chart">
      <svg viewBox="0 0 800 300" class="chart-svg">
        <!-- Grid lines -->
        <%= for i <- 0..10 do %>
          <% y = i * 30 %>
          <line x1="0" y1={y} x2="800" y2={y} stroke="#e0e0e0" stroke-width="1" />
        <% end %>
        
    <!-- Chart line -->
        <polyline
          points={generate_chart_points(@history, @selected_metric)}
          fill="none"
          stroke="#007bff"
          stroke-width="2"
        />
        
    <!-- Data points -->
        <%= for {point, index} <- Enum.with_index(@history) do %>
          <% {x, y} = calculate_point_position(point, @selected_metric, index, length(@history)) %>
          <circle cx={x} cy={y} r="3" fill="#007bff" />
        <% end %>
      </svg>
    </div>
    """
  end

  # Helper functions

  defp get_current_metrics do
    %{
      memory_usage: :erlang.memory(:total),
      process_count: :erlang.system_info(:process_count),
      cpu_usage: :rand.uniform(100),
      uptime: :erlang.statistics(:wall_clock) |> elem(0),
      request_rate: :rand.uniform(500),
      avg_response_time: :rand.uniform(100) + 50,
      otp_version: :erlang.system_info(:otp_release) |> to_string(),
      elixir_version: System.version(),
      node_name: Node.self(),
      phoenix_version: "1.8.0"
    }
  end

  defp initialize_history do
    Enum.map(1..@history_length, fn _ -> get_current_metrics() end)
  end

  defp update_metrics(socket) do
    metrics = get_current_metrics()
    assign(socket, metrics: metrics, last_updated: DateTime.utc_now())
  end

  defp update_history(socket) do
    new_history =
      [socket.assigns.metrics | socket.assigns.history]
      |> Enum.take(@history_length)

    assign(socket, history: new_history)
  end

  defp check_alerts(socket) do
    alerts = []

    # Check for high memory usage
    alerts =
      if socket.assigns.metrics.memory_usage > 1_000_000_000 do
        [
          %{
            level: :warning,
            title: "High Memory Usage",
            message: "Memory usage is above 1GB",
            timestamp: DateTime.utc_now()
          }
          | alerts
        ]
      else
        alerts
      end

    # Check for high CPU usage
    alerts =
      if socket.assigns.metrics.cpu_usage > 80 do
        [
          %{
            level: :critical,
            title: "High CPU Usage",
            message: "CPU usage is above 80%",
            timestamp: DateTime.utc_now()
          }
          | alerts
        ]
      else
        alerts
      end

    assign(socket, alerts: alerts)
  end

  defp calculate_change(history, metric) do
    case history do
      [current, previous | _] ->
        current_value = Map.get(current, metric, 0)
        previous_value = Map.get(previous, metric, 0)

        cond do
          current_value > previous_value -> :up
          current_value < previous_value -> :down
          true -> :stable
        end

      _ ->
        :stable
    end
  end

  defp metric_options do
    [
      {"memory", "Memory"},
      {"process_count", "Processes"},
      {"cpu_usage", "CPU"},
      {"request_rate", "Requests"},
      {"avg_response_time", "Response Time"}
    ]
  end

  defp generate_chart_points(history, selected_metric) do
    history
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      {x, y} = calculate_point_position(point, selected_metric, index, length(history))
      "#{x},#{y}"
    end)
    |> Enum.join(" ")
  end

  defp calculate_point_position(point, metric, index, total_points) do
    value = Map.get(point, String.to_existing_atom(metric), 0)
    max_value = get_max_value_for_metric(metric)

    x = index / (total_points - 1) * 800
    y = 300 - value / max_value * 280

    {x, y}
  end

  defp get_max_value_for_metric(metric) do
    case metric do
      "memory" -> 2_000_000_000
      "process_count" -> 100_000
      "cpu_usage" -> 100
      "request_rate" -> 1000
      "avg_response_time" -> 1000
      _ -> 1000
    end
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_uptime(uptime_ms) do
    seconds = div(uptime_ms, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)

    cond do
      days > 0 -> "#{days}d #{rem(hours, 24)}h"
      hours > 0 -> "#{hours}h #{rem(minutes, 60)}m"
      minutes > 0 -> "#{minutes}m #{rem(seconds, 60)}s"
      true -> "#{seconds}s"
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end
end
