defmodule PhoenixKit.Plugs.TelemetryPlug do
  @moduledoc """
  Telemetry and metrics collection plug for PhoenixKit.

  This plug collects request metrics and telemetry data that can be
  displayed in the PhoenixKit dashboard.

  ## Usage

  Add to your endpoint or router:

      plug PhoenixKit.Plugs.TelemetryPlug

  ## Options

  - `:enabled` - Enable/disable telemetry collection (default: true)
  - `:sample_rate` - Sample rate for metric collection (default: 1.0)
  - `:exclude_paths` - List of paths to exclude from metrics
  - `:include_query_params` - Include query parameters in metrics (default: false)
  """

  import Plug.Conn

  def init(opts) do
    %{
      enabled: Keyword.get(opts, :enabled, true),
      sample_rate: Keyword.get(opts, :sample_rate, 1.0),
      exclude_paths: Keyword.get(opts, :exclude_paths, []),
      include_query_params: Keyword.get(opts, :include_query_params, false)
    }
  end

  def call(conn, %{enabled: false}), do: conn

  def call(conn, opts) do
    if should_collect_metrics?(conn, opts) do
      start_time = System.monotonic_time()

      conn
      |> put_private(:phoenix_kit_start_time, start_time)
      |> put_private(:phoenix_kit_telemetry_opts, opts)
      |> register_before_send(&collect_response_metrics/1)
    else
      conn
    end
  end

  defp should_collect_metrics?(conn, opts) do
    cond do
      # Skip if path is excluded
      conn.request_path in opts.exclude_paths ->
        false

      # Skip if sample rate doesn't match
      :rand.uniform() > opts.sample_rate ->
        false

      # Skip static assets
      conn.request_path =~ ~r/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/ ->
        false

      true ->
        true
    end
  end

  defp collect_response_metrics(conn) do
    case conn.private do
      %{phoenix_kit_start_time: start_time, phoenix_kit_telemetry_opts: opts} ->
        end_time = System.monotonic_time()
        duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)

        metrics = %{
          method: conn.method,
          path: get_path(conn, opts),
          status: conn.status,
          duration: duration,
          timestamp: DateTime.utc_now(),
          user_agent: get_user_agent(conn),
          remote_ip: format_ip(conn.remote_ip),
          bytes_sent: get_content_length(conn)
        }

        # Store metrics (in a real implementation, you'd send to a metrics store)
        :telemetry.execute([:phoenix_kit, :request], metrics, %{})

        # Store in ETS for dashboard display
        store_metrics(metrics)

        conn

      _ ->
        conn
    end
  end

  defp get_path(conn, opts) do
    base_path = conn.request_path

    if opts.include_query_params && conn.query_string != "" do
      "#{base_path}?#{conn.query_string}"
    else
      base_path
    end
  end

  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      _ -> "unknown"
    end
  end

  defp format_ip({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  defp format_ip(ip) when is_tuple(ip) do
    :inet.ntoa(ip) |> to_string()
  end

  defp format_ip(_), do: "unknown"

  defp get_content_length(conn) do
    case get_resp_header(conn, "content-length") do
      [length_str | _] ->
        case Integer.parse(length_str) do
          {length, _} -> length
          _ -> 0
        end

      _ ->
        0
    end
  end

  defp store_metrics(metrics) do
    # Create ETS table if it doesn't exist
    table_name = :phoenix_kit_metrics

    unless :ets.whereis(table_name) != :undefined do
      :ets.new(table_name, [:public, :named_table, :ordered_set])
    end

    # Store with timestamp as key for ordering
    key = {System.monotonic_time(), make_ref()}
    :ets.insert(table_name, {key, metrics})

    # Keep only last 1000 entries
    case :ets.info(table_name, :size) do
      size when size > 1000 ->
        # Remove oldest entries
        :ets.first(table_name)
        |> case do
          :"$end_of_table" -> :ok
          first_key -> :ets.delete(table_name, first_key)
        end

      _ ->
        :ok
    end
  end
end
