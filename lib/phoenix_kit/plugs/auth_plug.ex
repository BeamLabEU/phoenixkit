defmodule PhoenixKit.Plugs.AuthPlug do
  @moduledoc """
  Authentication and authorization plug for PhoenixKit endpoints.

  This plug provides configurable authentication and authorization
  for PhoenixKit dashboard and monitoring endpoints.

  ## Configuration

  Add to your endpoint or router:

      plug PhoenixKit.Plugs.AuthPlug,
        enabled: true,
        basic_auth: [username: "admin", password: "secret"],
        allowed_ips: ["127.0.0.1", "::1"]

  ## Options

  - `:enabled` - Enable/disable authentication (default: true)
  - `:basic_auth` - Basic HTTP authentication credentials
  - `:allowed_ips` - List of allowed IP addresses
  - `:custom_auth` - Custom authentication function
  - `:redirect_to` - Redirect URL for unauthorized access
  """

  import Plug.Conn

  def init(opts) do
    %{
      enabled: Keyword.get(opts, :enabled, true),
      basic_auth: Keyword.get(opts, :basic_auth),
      allowed_ips: Keyword.get(opts, :allowed_ips, []),
      custom_auth: Keyword.get(opts, :custom_auth),
      redirect_to: Keyword.get(opts, :redirect_to, "/")
    }
  end

  def call(conn, %{enabled: false}), do: conn

  def call(conn, opts) do
    cond do
      skip_auth?(conn) ->
        conn

      ip_authorized?(conn, opts.allowed_ips) ->
        conn

      basic_auth_valid?(conn, opts.basic_auth) ->
        conn

      custom_auth_valid?(conn, opts.custom_auth) ->
        conn

      true ->
        handle_unauthorized(conn, opts)
    end
  end

  defp skip_auth?(conn) do
    # Skip authentication for static assets
    conn.request_path =~ ~r/\.(css|js|png|jpg|jpeg|gif|ico|svg)$/
  end

  defp ip_authorized?(conn, allowed_ips) when is_list(allowed_ips) and length(allowed_ips) > 0 do
    client_ip = get_client_ip(conn)

    Enum.any?(allowed_ips, fn allowed_ip ->
      case :inet.parse_address(String.to_charlist(allowed_ip)) do
        {:ok, parsed_ip} ->
          client_ip == parsed_ip

        {:error, _} ->
          false
      end
    end)
  end

  defp ip_authorized?(_, _), do: false

  defp basic_auth_valid?(conn, basic_auth) when is_list(basic_auth) do
    username = Keyword.get(basic_auth, :username)
    password = Keyword.get(basic_auth, :password)

    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, decoded} ->
            case String.split(decoded, ":", parts: 2) do
              [^username, ^password] -> true
              _ -> false
            end

          _ ->
            false
        end

      _ ->
        false
    end
  end

  defp basic_auth_valid?(_, _), do: false

  defp custom_auth_valid?(conn, custom_auth) when is_function(custom_auth, 1) do
    custom_auth.(conn)
  end

  defp custom_auth_valid?(_, _), do: false

  defp handle_unauthorized(conn, opts) do
    if opts.basic_auth do
      conn
      |> put_resp_header("www-authenticate", "Basic realm=\"PhoenixKit\"")
      |> send_resp(401, "Unauthorized")
      |> halt()
    else
      conn
      |> Phoenix.Controller.redirect(to: opts.redirect_to)
      |> halt()
    end
  end

  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip_string | _] ->
        ip_string
        |> String.split(",")
        |> List.first()
        |> String.trim()
        |> String.to_charlist()
        |> :inet.parse_address()
        |> case do
          {:ok, ip} -> ip
          _ -> conn.remote_ip
        end

      _ ->
        conn.remote_ip
    end
  end
end
