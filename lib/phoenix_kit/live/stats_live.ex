defmodule PhoenixKit.StatsLive do
  use Phoenix.LiveView

  @moduledoc """
  LiveView for detailed statistics and analytics.

  Provides detailed breakdowns of system metrics, performance analytics,
  and historical data visualization.
  """

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(10_000, self(), :update_stats)
    end

    {:ok,
     assign(socket,
       stats: generate_stats(),
       time_range: "24h",
       selected_tab: "overview"
     )}
  end

  def handle_event("change_time_range", %{"range" => range}, socket) do
    {:noreply, assign(socket, time_range: range, stats: generate_stats())}
  end

  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_tab: tab)}
  end

  def handle_info(:update_stats, socket) do
    {:noreply, assign(socket, stats: generate_stats())}
  end

  def render(assigns) do
    ~H"""
    <div class="stats-live">
      <div class="stats-header">
        <h1>📊 PhoenixKit Statistics</h1>
        <div class="time-range-selector">
          <label>Time Range:</label>
          <%= for range <- ["1h", "6h", "24h", "7d", "30d"] do %>
            <button
              phx-click="change_time_range"
              phx-value-range={range}
              class={"btn btn-sm #{if @time_range == range, do: "btn-primary", else: "btn-secondary"}"}
            >
              {range}
            </button>
          <% end %>
        </div>
      </div>
      
    <!-- Tab Navigation -->
      <div class="tab-navigation">
        <%= for {tab, label} <- tabs() do %>
          <button
            phx-click="select_tab"
            phx-value-tab={tab}
            class={"tab-btn #{if @selected_tab == tab, do: "active", else: ""}"}
          >
            {label}
          </button>
        <% end %>
      </div>
      
    <!-- Tab Content -->
      <div class="tab-content">
        <%= case @selected_tab do %>
          <% "overview" -> %>
            <.overview_tab stats={@stats} />
          <% "performance" -> %>
            <.performance_tab stats={@stats} />
          <% "memory" -> %>
            <.memory_tab stats={@stats} />
          <% "processes" -> %>
            <.processes_tab stats={@stats} />
          <% "network" -> %>
            <.network_tab stats={@stats} />
        <% end %>
      </div>
    </div>
    """
  end

  # Tab components

  def overview_tab(assigns) do
    ~H"""
    <div class="overview-tab">
      <div class="overview-grid">
        <div class="overview-card">
          <h3>System Health</h3>
          <div class="health-score">
            <div class="score-circle">
              <span class="score-value">{@stats.health_score}</span>
              <span class="score-label">/ 100</span>
            </div>
            <div class="health-indicators">
              <div class="indicator">
                <span class="indicator-label">CPU:</span>
                <span class={"indicator-value status-#{@stats.cpu_status}"}>{@stats.cpu_usage}%</span>
              </div>
              <div class="indicator">
                <span class="indicator-label">Memory:</span>
                <span class={"indicator-value status-#{@stats.memory_status}"}>
                  {@stats.memory_percentage}%
                </span>
              </div>
              <div class="indicator">
                <span class="indicator-label">Disk:</span>
                <span class={"indicator-value status-#{@stats.disk_status}"}>
                  {@stats.disk_usage}%
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="overview-card">
          <h3>Traffic Overview</h3>
          <div class="traffic-stats">
            <div class="stat-row">
              <span>Total Requests:</span>
              <span class="stat-value">{format_number(@stats.total_requests)}</span>
            </div>
            <div class="stat-row">
              <span>Avg Response Time:</span>
              <span class="stat-value">{@stats.avg_response_time}ms</span>
            </div>
            <div class="stat-row">
              <span>Error Rate:</span>
              <span class="stat-value">{@stats.error_rate}%</span>
            </div>
            <div class="stat-row">
              <span>Success Rate:</span>
              <span class="stat-value">{@stats.success_rate}%</span>
            </div>
          </div>
        </div>

        <div class="overview-card">
          <h3>Top Endpoints</h3>
          <div class="endpoints-list">
            <%= for endpoint <- @stats.top_endpoints do %>
              <div class="endpoint-item">
                <span class="endpoint-path">{endpoint.path}</span>
                <span class="endpoint-count">{endpoint.count}</span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def performance_tab(assigns) do
    ~H"""
    <div class="performance-tab">
      <div class="performance-metrics">
        <h3>Performance Metrics</h3>
        <div class="metrics-grid">
          <div class="metric-box">
            <h4>Response Time Distribution</h4>
            <div class="distribution-chart">
              <%= for {range, percentage} <- @stats.response_time_distribution do %>
                <div class="distribution-bar">
                  <span class="range-label">{range}</span>
                  <div class="bar-container">
                    <div class="bar" style={"width: #{percentage}%"}></div>
                  </div>
                  <span class="percentage">{percentage}%</span>
                </div>
              <% end %>
            </div>
          </div>

          <div class="metric-box">
            <h4>Throughput</h4>
            <div class="throughput-stats">
              <div class="throughput-item">
                <span class="label">Requests/sec:</span>
                <span class="value">{@stats.requests_per_second}</span>
              </div>
              <div class="throughput-item">
                <span class="label">Peak RPS:</span>
                <span class="value">{@stats.peak_rps}</span>
              </div>
              <div class="throughput-item">
                <span class="label">Data Transfer:</span>
                <span class="value">{@stats.data_transfer}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def memory_tab(assigns) do
    ~H"""
    <div class="memory-tab">
      <div class="memory-breakdown">
        <h3>Memory Usage Breakdown</h3>
        <div class="memory-categories">
          <%= for category <- @stats.memory_breakdown do %>
            <div class="memory-category">
              <div class="category-header">
                <span class="category-name">{category.name}</span>
                <span class="category-size">{format_bytes(category.size)}</span>
                <span class="category-percentage">({category.percentage}%)</span>
              </div>
              <div class="category-bar">
                <div class="bar-fill" style={"width: #{category.percentage}%"}></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="gc-stats">
        <h3>Garbage Collection Statistics</h3>
        <div class="gc-metrics">
          <div class="gc-metric">
            <span class="metric-label">GC Runs:</span>
            <span class="metric-value">{@stats.gc_runs}</span>
          </div>
          <div class="gc-metric">
            <span class="metric-label">Words Reclaimed:</span>
            <span class="metric-value">{format_number(@stats.words_reclaimed)}</span>
          </div>
          <div class="gc-metric">
            <span class="metric-label">Avg GC Time:</span>
            <span class="metric-value">{@stats.avg_gc_time}ms</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def processes_tab(assigns) do
    ~H"""
    <div class="processes-tab">
      <div class="process-overview">
        <h3>Process Statistics</h3>
        <div class="process-stats">
          <div class="stat-item">
            <span class="stat-label">Total Processes:</span>
            <span class="stat-value">{@stats.total_processes}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">Running:</span>
            <span class="stat-value">{@stats.running_processes}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">Waiting:</span>
            <span class="stat-value">{@stats.waiting_processes}</span>
          </div>
        </div>
      </div>

      <div class="top-processes">
        <h3>Top Memory Consumers</h3>
        <div class="processes-table">
          <div class="table-header">
            <span>Process</span>
            <span>Memory</span>
            <span>Message Queue</span>
            <span>Reductions</span>
          </div>
          <%= for process <- @stats.top_processes do %>
            <div class="table-row">
              <span class="process-name">{process.name}</span>
              <span class="process-memory">{format_bytes(process.memory)}</span>
              <span class="process-queue">{process.message_queue_len}</span>
              <span class="process-reductions">{format_number(process.reductions)}</span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def network_tab(assigns) do
    ~H"""
    <div class="network-tab">
      <div class="network-overview">
        <h3>Network Statistics</h3>
        <div class="network-stats">
          <div class="stat-group">
            <h4>Inbound</h4>
            <div class="stat-item">
              <span class="stat-label">Bytes In:</span>
              <span class="stat-value">{format_bytes(@stats.bytes_in)}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">Packets In:</span>
              <span class="stat-value">{format_number(@stats.packets_in)}</span>
            </div>
          </div>
          <div class="stat-group">
            <h4>Outbound</h4>
            <div class="stat-item">
              <span class="stat-label">Bytes Out:</span>
              <span class="stat-value">{format_bytes(@stats.bytes_out)}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">Packets Out:</span>
              <span class="stat-value">{format_number(@stats.packets_out)}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="connection-stats">
        <h3>Connection Statistics</h3>
        <div class="connection-metrics">
          <div class="connection-item">
            <span class="label">Active Connections:</span>
            <span class="value">{@stats.active_connections}</span>
          </div>
          <div class="connection-item">
            <span class="label">Total Connections:</span>
            <span class="value">{@stats.total_connections}</span>
          </div>
          <div class="connection-item">
            <span class="label">Connection Errors:</span>
            <span class="value">{@stats.connection_errors}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp tabs do
    [
      {"overview", "Overview"},
      {"performance", "Performance"},
      {"memory", "Memory"},
      {"processes", "Processes"},
      {"network", "Network"}
    ]
  end

  defp generate_stats do
    %{
      health_score: :rand.uniform(100),
      cpu_usage: :rand.uniform(100),
      cpu_status: random_status(),
      memory_percentage: :rand.uniform(100),
      memory_status: random_status(),
      disk_usage: :rand.uniform(100),
      disk_status: random_status(),
      total_requests: :rand.uniform(1_000_000),
      avg_response_time: :rand.uniform(200) + 50,
      error_rate: Float.round(:rand.uniform() * 10, 2),
      success_rate: Float.round(90 + :rand.uniform() * 10, 2),
      top_endpoints: generate_top_endpoints(),
      response_time_distribution: generate_response_time_distribution(),
      requests_per_second: :rand.uniform(1000),
      peak_rps: :rand.uniform(5000),
      data_transfer: "#{:rand.uniform(100)} MB/s",
      memory_breakdown: generate_memory_breakdown(),
      gc_runs: :rand.uniform(10000),
      words_reclaimed: :rand.uniform(1_000_000),
      avg_gc_time: :rand.uniform(50),
      total_processes: :rand.uniform(10000),
      running_processes: :rand.uniform(500),
      waiting_processes: :rand.uniform(500),
      top_processes: generate_top_processes(),
      bytes_in: :rand.uniform(1_000_000_000),
      bytes_out: :rand.uniform(1_000_000_000),
      packets_in: :rand.uniform(1_000_000),
      packets_out: :rand.uniform(1_000_000),
      active_connections: :rand.uniform(1000),
      total_connections: :rand.uniform(10000),
      connection_errors: :rand.uniform(100)
    }
  end

  defp random_status do
    Enum.random([:good, :warning, :critical])
  end

  defp generate_top_endpoints do
    [
      %{path: "/api/users", count: :rand.uniform(10000)},
      %{path: "/api/posts", count: :rand.uniform(8000)},
      %{path: "/api/comments", count: :rand.uniform(5000)},
      %{path: "/dashboard", count: :rand.uniform(3000)},
      %{path: "/login", count: :rand.uniform(2000)}
    ]
  end

  defp generate_response_time_distribution do
    [
      {"0-50ms", :rand.uniform(40)},
      {"50-100ms", :rand.uniform(30)},
      {"100-200ms", :rand.uniform(20)},
      {"200-500ms", :rand.uniform(10)},
      {"500ms+", :rand.uniform(5)}
    ]
  end

  defp generate_memory_breakdown do
    [
      %{name: "Process Memory", size: :rand.uniform(500_000_000), percentage: :rand.uniform(40)},
      %{name: "Atom Table", size: :rand.uniform(50_000_000), percentage: :rand.uniform(10)},
      %{name: "Code", size: :rand.uniform(100_000_000), percentage: :rand.uniform(15)},
      %{name: "Binary", size: :rand.uniform(200_000_000), percentage: :rand.uniform(20)},
      %{name: "ETS", size: :rand.uniform(80_000_000), percentage: :rand.uniform(15)}
    ]
  end

  defp generate_top_processes do
    [
      %{
        name: "Phoenix.Endpoint",
        memory: :rand.uniform(50_000_000),
        message_queue_len: :rand.uniform(100),
        reductions: :rand.uniform(1_000_000)
      },
      %{
        name: "GenServer",
        memory: :rand.uniform(30_000_000),
        message_queue_len: :rand.uniform(50),
        reductions: :rand.uniform(500_000)
      },
      %{
        name: "Task.Supervisor",
        memory: :rand.uniform(20_000_000),
        message_queue_len: :rand.uniform(20),
        reductions: :rand.uniform(200_000)
      },
      %{
        name: "Ecto.Repo",
        memory: :rand.uniform(40_000_000),
        message_queue_len: :rand.uniform(80),
        reductions: :rand.uniform(800_000)
      },
      %{
        name: "LiveView",
        memory: :rand.uniform(15_000_000),
        message_queue_len: :rand.uniform(30),
        reductions: :rand.uniform(300_000)
      }
    ]
  end

  defp format_bytes(bytes) do
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
end
