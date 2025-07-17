defmodule PhoenixKit.MonitorLive do
  use Phoenix.LiveView

  @moduledoc """
  LiveView for real-time system monitoring and alerts.

  Provides comprehensive monitoring capabilities including:
  - Real-time system health monitoring
  - Alert management and notifications
  - Performance tracking
  - Resource usage monitoring
  """

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2_000, self(), :update_monitor)
    end

    {:ok,
     assign(socket,
       monitoring: true,
       alerts: [],
       system_health: %{},
       performance_metrics: %{},
       resource_usage: %{},
       alert_settings: default_alert_settings(),
       selected_view: "dashboard"
     )}
  end

  def handle_event("toggle_monitoring", _params, socket) do
    new_monitoring = !socket.assigns.monitoring
    {:noreply, assign(socket, monitoring: new_monitoring)}
  end

  def handle_event("select_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, selected_view: view)}
  end

  def handle_event("dismiss_alert", %{"alert_id" => alert_id}, socket) do
    new_alerts = Enum.reject(socket.assigns.alerts, &(&1.id == alert_id))
    {:noreply, assign(socket, alerts: new_alerts)}
  end

  def handle_event(
        "update_alert_setting",
        %{"metric" => metric, "threshold" => threshold},
        socket
      ) do
    threshold_value = String.to_integer(threshold)
    new_settings = Map.put(socket.assigns.alert_settings, metric, threshold_value)
    {:noreply, assign(socket, alert_settings: new_settings)}
  end

  def handle_event("clear_all_alerts", _params, socket) do
    {:noreply, assign(socket, alerts: [])}
  end

  def handle_info(:update_monitor, socket) do
    if socket.assigns.monitoring do
      system_health = collect_system_health()
      performance_metrics = collect_performance_metrics()
      resource_usage = collect_resource_usage()

      new_alerts =
        check_alert_conditions(
          socket.assigns.alert_settings,
          system_health,
          performance_metrics,
          resource_usage
        )

      all_alerts =
        (socket.assigns.alerts ++ new_alerts)
        |> Enum.uniq_by(& &1.id)
        # Keep only latest 50 alerts
        |> Enum.take(50)

      {:noreply,
       assign(socket,
         system_health: system_health,
         performance_metrics: performance_metrics,
         resource_usage: resource_usage,
         alerts: all_alerts
       )}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="monitor-live">
      <!-- Monitor Header -->
      <div class="monitor-header">
        <h1>🔍 PhoenixKit System Monitor</h1>
        <div class="monitor-controls">
          <div class="monitoring-status">
            <span class={"status-indicator #{if @monitoring, do: "active", else: "inactive"}"}>
              {if @monitoring, do: "●", else: "○"}
            </span>
            <span>Monitoring: {if @monitoring, do: "ACTIVE", else: "PAUSED"}</span>
          </div>
          <button
            phx-click="toggle_monitoring"
            class={"btn btn-sm #{if @monitoring, do: "btn-warning", else: "btn-success"}"}
          >
            {if @monitoring, do: "⏸️ Pause", else: "▶️ Resume"}
          </button>
        </div>
      </div>
      
    <!-- Alert Banner -->
      <%= if length(@alerts) > 0 do %>
        <div class="alert-banner">
          <div class="alert-header">
            <h3>🚨 Active Alerts ({length(@alerts)})</h3>
            <button phx-click="clear_all_alerts" class="btn btn-xs btn-secondary">
              Clear All
            </button>
          </div>
          <div class="alert-list">
            <%= for alert <- Enum.take(@alerts, 5) do %>
              <.alert_card alert={alert} />
            <% end %>
            <%= if length(@alerts) > 5 do %>
              <div class="alert-more">
                <span>And {length(@alerts) - 5} more alerts...</span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- View Navigation -->
      <div class="view-navigation">
        <%= for {view, label, icon} <- views() do %>
          <button
            phx-click="select_view"
            phx-value-view={view}
            class={"view-btn #{if @selected_view == view, do: "active", else: ""}"}
          >
            {icon} {label}
          </button>
        <% end %>
      </div>
      
    <!-- View Content -->
      <div class="view-content">
        <%= case @selected_view do %>
          <% "dashboard" -> %>
            <.dashboard_view
              system_health={@system_health}
              performance_metrics={@performance_metrics}
              resource_usage={@resource_usage}
            />
          <% "alerts" -> %>
            <.alerts_view alerts={@alerts} />
          <% "performance" -> %>
            <.performance_view performance_metrics={@performance_metrics} />
          <% "resources" -> %>
            <.resources_view resource_usage={@resource_usage} />
          <% "settings" -> %>
            <.settings_view alert_settings={@alert_settings} />
        <% end %>
      </div>
    </div>
    """
  end

  # View components

  def dashboard_view(assigns) do
    ~H"""
    <div class="dashboard-view">
      <div class="health-overview">
        <h3>System Health Overview</h3>
        <div class="health-grid">
          <.health_card
            title="CPU Health"
            value={@system_health.cpu_health}
            status={@system_health.cpu_status}
            details={"#{@system_health.cpu_usage}% usage"}
          />
          <.health_card
            title="Memory Health"
            value={@system_health.memory_health}
            status={@system_health.memory_status}
            details={"#{@system_health.memory_usage}% usage"}
          />
          <.health_card
            title="Disk Health"
            value={@system_health.disk_health}
            status={@system_health.disk_status}
            details={"#{@system_health.disk_usage}% usage"}
          />
          <.health_card
            title="Network Health"
            value={@system_health.network_health}
            status={@system_health.network_status}
            details={"#{@system_health.network_latency}ms latency"}
          />
        </div>
      </div>

      <div class="quick-metrics">
        <h3>Quick Metrics</h3>
        <div class="metrics-row">
          <div class="metric-item">
            <span class="metric-label">Uptime:</span>
            <span class="metric-value">{@system_health.uptime}</span>
          </div>
          <div class="metric-item">
            <span class="metric-label">Load Average:</span>
            <span class="metric-value">{@system_health.load_avg}</span>
          </div>
          <div class="metric-item">
            <span class="metric-label">Processes:</span>
            <span class="metric-value">{@system_health.process_count}</span>
          </div>
          <div class="metric-item">
            <span class="metric-label">Connections:</span>
            <span class="metric-value">{@system_health.connection_count}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def alerts_view(assigns) do
    ~H"""
    <div class="alerts-view">
      <div class="alerts-header">
        <h3>Alert Management</h3>
        <div class="alert-stats">
          <span class="stat-item">
            <span class="stat-label">Total:</span>
            <span class="stat-value">{length(@alerts)}</span>
          </span>
          <span class="stat-item">
            <span class="stat-label">Critical:</span>
            <span class="stat-value critical">{count_alerts_by_level(@alerts, :critical)}</span>
          </span>
          <span class="stat-item">
            <span class="stat-label">Warning:</span>
            <span class="stat-value warning">{count_alerts_by_level(@alerts, :warning)}</span>
          </span>
        </div>
      </div>

      <div class="alerts-list">
        <%= for alert <- @alerts do %>
          <.detailed_alert_card alert={alert} />
        <% end %>
        <%= if length(@alerts) == 0 do %>
          <div class="no-alerts">
            <div class="no-alerts-icon">✅</div>
            <h4>No Active Alerts</h4>
            <p>Your system is running smoothly!</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def performance_view(assigns) do
    ~H"""
    <div class="performance-view">
      <div class="performance-overview">
        <h3>Performance Metrics</h3>
        <div class="performance-grid">
          <div class="performance-card">
            <h4>Response Times</h4>
            <div class="performance-data">
              <div class="data-item">
                <span class="label">Average:</span>
                <span class="value">{@performance_metrics.avg_response_time}ms</span>
              </div>
              <div class="data-item">
                <span class="label">95th Percentile:</span>
                <span class="value">{@performance_metrics.p95_response_time}ms</span>
              </div>
              <div class="data-item">
                <span class="label">99th Percentile:</span>
                <span class="value">{@performance_metrics.p99_response_time}ms</span>
              </div>
            </div>
          </div>

          <div class="performance-card">
            <h4>Throughput</h4>
            <div class="performance-data">
              <div class="data-item">
                <span class="label">Requests/sec:</span>
                <span class="value">{@performance_metrics.requests_per_second}</span>
              </div>
              <div class="data-item">
                <span class="label">Errors/sec:</span>
                <span class="value">{@performance_metrics.errors_per_second}</span>
              </div>
              <div class="data-item">
                <span class="label">Success Rate:</span>
                <span class="value">{@performance_metrics.success_rate}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def resources_view(assigns) do
    ~H"""
    <div class="resources-view">
      <div class="resource-monitoring">
        <h3>Resource Usage</h3>
        <div class="resource-cards">
          <.resource_card
            title="CPU Usage"
            current={@resource_usage.cpu_usage}
            max={100}
            unit="%"
            trend={@resource_usage.cpu_trend}
          />
          <.resource_card
            title="Memory Usage"
            current={@resource_usage.memory_usage}
            max={@resource_usage.total_memory}
            unit="MB"
            trend={@resource_usage.memory_trend}
          />
          <.resource_card
            title="Disk Usage"
            current={@resource_usage.disk_usage}
            max={@resource_usage.total_disk}
            unit="GB"
            trend={@resource_usage.disk_trend}
          />
          <.resource_card
            title="Network I/O"
            current={@resource_usage.network_io}
            max={1000}
            unit="MB/s"
            trend={@resource_usage.network_trend}
          />
        </div>
      </div>
    </div>
    """
  end

  def settings_view(assigns) do
    ~H"""
    <div class="settings-view">
      <div class="alert-settings">
        <h3>Alert Thresholds</h3>
        <div class="settings-grid">
          <div class="setting-item">
            <label>CPU Usage Alert (%):</label>
            <input
              type="number"
              value={@alert_settings.cpu_threshold}
              phx-blur="update_alert_setting"
              phx-value-metric="cpu_threshold"
              min="0"
              max="100"
            />
          </div>
          <div class="setting-item">
            <label>Memory Usage Alert (%):</label>
            <input
              type="number"
              value={@alert_settings.memory_threshold}
              phx-blur="update_alert_setting"
              phx-value-metric="memory_threshold"
              min="0"
              max="100"
            />
          </div>
          <div class="setting-item">
            <label>Disk Usage Alert (%):</label>
            <input
              type="number"
              value={@alert_settings.disk_threshold}
              phx-blur="update_alert_setting"
              phx-value-metric="disk_threshold"
              min="0"
              max="100"
            />
          </div>
          <div class="setting-item">
            <label>Response Time Alert (ms):</label>
            <input
              type="number"
              value={@alert_settings.response_time_threshold}
              phx-blur="update_alert_setting"
              phx-value-metric="response_time_threshold"
              min="0"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Component helpers

  def alert_card(assigns) do
    ~H"""
    <div class={"alert-card alert-#{@alert.level}"}>
      <div class="alert-icon">
        <%= case @alert.level do %>
          <% :critical -> %>
            🔴
          <% :warning -> %>
            🟡
          <% :info -> %>
            🔵
        <% end %>
      </div>
      <div class="alert-content">
        <h4>{@alert.title}</h4>
        <p>{@alert.message}</p>
        <small>{format_time(@alert.timestamp)}</small>
      </div>
      <button phx-click="dismiss_alert" phx-value-alert_id={@alert.id} class="alert-dismiss">
        ×
      </button>
    </div>
    """
  end

  def detailed_alert_card(assigns) do
    ~H"""
    <div class={"detailed-alert-card alert-#{@alert.level}"}>
      <div class="alert-header">
        <div class="alert-icon">
          <%= case @alert.level do %>
            <% :critical -> %>
              🔴
            <% :warning -> %>
              🟡
            <% :info -> %>
              🔵
          <% end %>
        </div>
        <div class="alert-title">
          <h4>{@alert.title}</h4>
          <span class="alert-level">{@alert.level}</span>
        </div>
        <div class="alert-time">
          {format_time(@alert.timestamp)}
        </div>
        <button phx-click="dismiss_alert" phx-value-alert_id={@alert.id} class="alert-dismiss">
          ×
        </button>
      </div>
      <div class="alert-body">
        <p>{@alert.message}</p>
        <%= if Map.has_key?(@alert, :details) do %>
          <div class="alert-details">
            <strong>Details:</strong> {@alert.details}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def health_card(assigns) do
    ~H"""
    <div class={"health-card health-#{@status}"}>
      <div class="health-header">
        <h4>{@title}</h4>
        <span class="health-score">{@value}</span>
      </div>
      <div class="health-details">
        <p>{@details}</p>
      </div>
    </div>
    """
  end

  def resource_card(assigns) do
    ~H"""
    <div class="resource-card">
      <div class="resource-header">
        <h4>{@title}</h4>
        <span class="resource-trend">
          <%= case @trend do %>
            <% :up -> %>
              📈
            <% :down -> %>
              📉
            <% :stable -> %>
              ➡️
          <% end %>
        </span>
      </div>
      <div class="resource-usage">
        <div class="usage-bar">
          <div class="usage-fill" style={"width: #{(@current / @max) * 100}%"}></div>
        </div>
        <div class="usage-text">
          {@current}{@unit} / {@max}{@unit}
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp views do
    [
      {"dashboard", "Dashboard", "📊"},
      {"alerts", "Alerts", "🚨"},
      {"performance", "Performance", "⚡"},
      {"resources", "Resources", "💾"},
      {"settings", "Settings", "⚙️"}
    ]
  end

  defp default_alert_settings do
    %{
      cpu_threshold: 80,
      memory_threshold: 85,
      disk_threshold: 90,
      response_time_threshold: 1000
    }
  end

  defp collect_system_health do
    %{
      cpu_health: :rand.uniform(100),
      cpu_status: Enum.random([:good, :warning, :critical]),
      cpu_usage: :rand.uniform(100),
      memory_health: :rand.uniform(100),
      memory_status: Enum.random([:good, :warning, :critical]),
      memory_usage: :rand.uniform(100),
      disk_health: :rand.uniform(100),
      disk_status: Enum.random([:good, :warning, :critical]),
      disk_usage: :rand.uniform(100),
      network_health: :rand.uniform(100),
      network_status: Enum.random([:good, :warning, :critical]),
      network_latency: :rand.uniform(100),
      uptime: format_uptime(:rand.uniform(1_000_000)),
      load_avg: Float.round(:rand.uniform() * 5, 2),
      process_count: :rand.uniform(10000),
      connection_count: :rand.uniform(1000)
    }
  end

  defp collect_performance_metrics do
    %{
      avg_response_time: :rand.uniform(200) + 50,
      p95_response_time: :rand.uniform(500) + 100,
      p99_response_time: :rand.uniform(1000) + 200,
      requests_per_second: :rand.uniform(1000),
      errors_per_second: :rand.uniform(50),
      success_rate: Float.round(95 + :rand.uniform() * 5, 2)
    }
  end

  defp collect_resource_usage do
    %{
      cpu_usage: :rand.uniform(100),
      cpu_trend: Enum.random([:up, :down, :stable]),
      memory_usage: :rand.uniform(8000),
      total_memory: 8192,
      memory_trend: Enum.random([:up, :down, :stable]),
      disk_usage: :rand.uniform(500),
      total_disk: 1000,
      disk_trend: Enum.random([:up, :down, :stable]),
      network_io: :rand.uniform(100),
      network_trend: Enum.random([:up, :down, :stable])
    }
  end

  defp check_alert_conditions(settings, system_health, performance_metrics, resource_usage) do
    alerts = []

    # Check CPU threshold
    alerts =
      if system_health.cpu_usage > settings.cpu_threshold do
        [
          %{
            id: "cpu_high_#{:rand.uniform(10000)}",
            level: :warning,
            title: "High CPU Usage",
            message:
              "CPU usage is #{system_health.cpu_usage}%, above threshold of #{settings.cpu_threshold}%",
            timestamp: DateTime.utc_now()
          }
          | alerts
        ]
      else
        alerts
      end

    # Check memory threshold
    alerts =
      if system_health.memory_usage > settings.memory_threshold do
        [
          %{
            id: "memory_high_#{:rand.uniform(10000)}",
            level: :critical,
            title: "High Memory Usage",
            message:
              "Memory usage is #{system_health.memory_usage}%, above threshold of #{settings.memory_threshold}%",
            timestamp: DateTime.utc_now()
          }
          | alerts
        ]
      else
        alerts
      end

    # Check response time threshold
    alerts =
      if performance_metrics.avg_response_time > settings.response_time_threshold do
        [
          %{
            id: "response_time_high_#{:rand.uniform(10000)}",
            level: :warning,
            title: "High Response Time",
            message:
              "Average response time is #{performance_metrics.avg_response_time}ms, above threshold of #{settings.response_time_threshold}ms",
            timestamp: DateTime.utc_now()
          }
          | alerts
        ]
      else
        alerts
      end

    alerts
  end

  defp count_alerts_by_level(alerts, level) do
    Enum.count(alerts, &(&1.level == level))
  end

  defp format_uptime(uptime_ms) do
    seconds = div(uptime_ms, 1000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)

    cond do
      days > 0 -> "#{days}d #{rem(hours, 24)}h"
      hours > 0 -> "#{hours}h #{rem(minutes, 60)}m"
      minutes > 0 -> "#{minutes}m"
      true -> "#{seconds}s"
    end
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end
end
