defmodule PhoenixKit.DashboardHTML do
  use Phoenix.Component
  import Phoenix.HTML

  @moduledoc """
  HTML components and templates for the PhoenixKit dashboard.
  """

  # Templates are defined as functions below

  @doc """
  Renders the main dashboard page.
  """
  def index(assigns) do
    ~H"""
    <div class="dashboard-container">
      <!-- Dashboard Header -->
      <div class="dashboard-header">
        <h1>{@title}</h1>
        <div class="header-actions">
          <button class="btn btn-sm" onclick="refreshDashboard()">
            🔄 Refresh
          </button>
          <.link href="/phoenix_kit/live" class="btn btn-sm btn-primary">
            Live View
          </.link>
        </div>
      </div>
      
    <!-- Stats Cards -->
      <div class="stats-grid">
        <.stat_card title="Uptime" value={format_uptime(@stats.uptime)} icon="⏱️" trend="stable" />
        <.stat_card
          title="Memory Usage"
          value={format_memory(@stats.memory_usage)}
          icon="💾"
          trend="up"
        />
        <.stat_card title="Process Count" value={@stats.process_count} icon="⚙️" trend="stable" />
        <.stat_card
          title="Request Count"
          value={format_number(@stats.request_count)}
          icon="📊"
          trend="up"
        />
        <.stat_card
          title="Avg Response Time"
          value={"#{@stats.response_time}ms"}
          icon="⚡"
          trend="down"
        />
      </div>
      
    <!-- Charts Section -->
      <div class="charts-section">
        <div class="chart-row">
          <div class="chart-container">
            <h3>Memory Usage Timeline</h3>
            <.timeline_chart data={@charts.memory_timeline} type="memory" />
          </div>
          <div class="chart-container">
            <h3>Request Timeline</h3>
            <.timeline_chart data={@charts.request_timeline} type="requests" />
          </div>
        </div>
        <div class="chart-row">
          <div class="chart-container full-width">
            <h3>Response Time Timeline</h3>
            <.timeline_chart data={@charts.response_time_timeline} type="response_time" />
          </div>
        </div>
      </div>
      
    <!-- Recent Activity -->
      <div class="activity-section">
        <h3>Recent Activity</h3>
        <div class="activity-list">
          <%= for activity <- @recent_activity do %>
            <.activity_item activity={activity} />
          <% end %>
        </div>
      </div>
    </div>

    <script>
      function refreshDashboard() {
        fetch('/phoenix_kit/api/stats')
          .then(response => response.json())
          .then(data => {
            // Update dashboard with new data
            console.log('Dashboard refreshed:', data);
            location.reload(); // Simple refresh for now
          })
          .catch(error => console.error('Error refreshing dashboard:', error));
      }

      // Auto-refresh every 30 seconds
      setInterval(refreshDashboard, 30000);
    </script>
    """
  end

  @doc """
  Renders a statistics card.
  """
  def stat_card(assigns) do
    ~H"""
    <div class="stat-card">
      <div class="stat-header">
        <span class="stat-icon">{@icon}</span>
        <span class={"stat-trend trend-#{@trend}"}></span>
      </div>
      <div class="stat-content">
        <h3 class="stat-title">{@title}</h3>
        <div class="stat-value">{@value}</div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a timeline chart (simplified SVG representation).
  """
  def timeline_chart(assigns) do
    ~H"""
    <div class="timeline-chart" data-type={@type}>
      <svg class="chart-svg" viewBox="0 0 400 200">
        <!-- Chart background -->
        <rect x="0" y="0" width="400" height="200" fill="#f8f9fa" />
        
    <!-- Chart lines -->
        <%= for {point, index} <- Enum.with_index(@data) do %>
          <% x = index * (400 / length(@data)) %>
          <% y = 200 - point.value / max_value(@data) * 180 %>
          <%= if index > 0 do %>
            <% prev_point = Enum.at(@data, index - 1) %>
            <% prev_x = (index - 1) * (400 / length(@data)) %>
            <% prev_y = 200 - prev_point.value / max_value(@data) * 180 %>
            <line x1={prev_x} y1={prev_y} x2={x} y2={y} stroke="#007bff" stroke-width="2" />
          <% end %>
          <circle cx={x} cy={y} r="3" fill="#007bff" />
        <% end %>
      </svg>
    </div>
    """
  end

  @doc """
  Renders an activity item.
  """
  def activity_item(assigns) do
    ~H"""
    <div class={"activity-item activity-#{@activity.type}"}>
      <div class="activity-icon">
        <%= case @activity.type do %>
          <% "info" -> %>
            ℹ️
          <% "success" -> %>
            ✅
          <% "warning" -> %>
            ⚠️
          <% "error" -> %>
            ❌
          <% _ -> %>
            📝
        <% end %>
      </div>
      <div class="activity-content">
        <span class="activity-message">{@activity.message}</span>
        <span class="activity-time">{format_time(@activity.timestamp)}</span>
      </div>
    </div>
    """
  end

  # Helper functions

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

  defp format_memory(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_number(number) when number >= 1_000_000 do
    "#{Float.round(number / 1_000_000, 1)}M"
  end

  defp format_number(number) when number >= 1_000 do
    "#{Float.round(number / 1_000, 1)}K"
  end

  defp format_number(number), do: to_string(number)

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp max_value(data) do
    data
    |> Enum.map(& &1.value)
    |> Enum.max()
  end
end
