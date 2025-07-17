defmodule PhoenixKit.Utils do
  @moduledoc """
  Utility functions for PhoenixKit and Phoenix applications.

  This module provides commonly used helper functions for:
  - Date and time formatting
  - String manipulation
  - Validation
  - File handling
  - Development tools
  - Performance utilities
  """

  # Date and Time utilities

  @doc """
  Formats a date in human-readable format.

  ## Examples

      iex> PhoenixKit.Utils.format_date(~D[2024-01-15])
      "January 15, 2024"
  """
  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  @doc """
  Returns a relative time string for the given datetime.

  ## Examples

      iex> PhoenixKit.Utils.time_ago(DateTime.utc_now())
      "just now"
  """
  def time_ago(%DateTime{} = datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 2_592_000 -> "#{div(diff, 86400)} days ago"
      true -> format_date(DateTime.to_date(datetime))
    end
  end

  @doc """
  Formats a datetime for display.

  ## Examples

      iex> PhoenixKit.Utils.format_datetime(~U[2024-01-15 14:30:00Z])
      "2024-01-15 14:30:00"
  """
  def format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end

  # String utilities

  @doc """
  Truncates a string to the specified length.

  ## Examples

      iex> PhoenixKit.Utils.truncate("Hello World", 5)
      "Hello..."
  """
  def truncate(string, length) when is_binary(string) and is_integer(length) and length > 0 do
    if String.length(string) > length do
      String.slice(string, 0, length) <> "..."
    else
      string
    end
  end

  @doc """
  Converts a string to a URL-friendly slug.

  ## Examples

      iex> PhoenixKit.Utils.slug("Hello World!")
      "hello-world"
  """
  def slug(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  @doc """
  Capitalizes the first letter of each word in a string.

  ## Examples

      iex> PhoenixKit.Utils.title_case("hello world")
      "Hello World"
  """
  def title_case(string) when is_binary(string) do
    string
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Validation utilities

  @doc """
  Validates an email address format.

  ## Examples

      iex> PhoenixKit.Utils.validate_email("user@example.com")
      true
      
      iex> PhoenixKit.Utils.validate_email("invalid-email")
      false
  """
  def validate_email(email) when is_binary(email) do
    email_regex = ~r/^[^\s]+@[^\s]+\.[^\s]+$/
    Regex.match?(email_regex, email)
  end

  @doc """
  Validates password strength.

  ## Examples

      iex> PhoenixKit.Utils.validate_password_strength("weak")
      :weak
      
      iex> PhoenixKit.Utils.validate_password_strength("SecureP@ss123")
      :strong
  """
  def validate_password_strength(password) when is_binary(password) do
    length = String.length(password)
    has_upper = Regex.match?(~r/[A-Z]/, password)
    has_lower = Regex.match?(~r/[a-z]/, password)
    has_digit = Regex.match?(~r/\d/, password)
    has_special = Regex.match?(~r/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/, password)

    score =
      length_score(length) + bool_to_score(has_upper) +
        bool_to_score(has_lower) + bool_to_score(has_digit) +
        bool_to_score(has_special)

    cond do
      score >= 8 -> :strong
      score >= 5 -> :medium
      true -> :weak
    end
  end

  defp length_score(length) when length >= 12, do: 3
  defp length_score(length) when length >= 8, do: 2
  defp length_score(length) when length >= 6, do: 1
  defp length_score(_), do: 0

  defp bool_to_score(true), do: 1
  defp bool_to_score(false), do: 0

  # File utilities

  @doc """
  Returns human-readable file size.

  ## Examples

      iex> PhoenixKit.Utils.format_file_size(1024)
      "1.0 KB"
  """
  def format_file_size(bytes) when is_integer(bytes) and bytes >= 0 do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  @doc """
  Validates file type against allowed extensions.

  ## Examples

      iex> PhoenixKit.Utils.validate_file_type("image.jpg", ["jpg", "png"])
      true
  """
  def validate_file_type(filename, allowed_types)
      when is_binary(filename) and is_list(allowed_types) do
    extension =
      filename
      |> Path.extname()
      |> String.downcase()
      |> String.trim_leading(".")

    extension in allowed_types
  end

  @doc """
  Gets file size from file path.

  ## Examples

      iex> PhoenixKit.Utils.get_file_size("/path/to/file.txt")
      {:ok, 1024}
  """
  def get_file_size(file_path) when is_binary(file_path) do
    case File.stat(file_path) do
      {:ok, %File.Stat{size: size}} -> {:ok, size}
      {:error, reason} -> {:error, reason}
    end
  end

  # Development utilities

  @doc """
  Benchmarks a function and returns result with execution time.

  ## Examples

      iex> PhoenixKit.Utils.benchmark(fn -> Enum.sum(1..1000) end)
      {500500, 0.15}
  """
  def benchmark(function) when is_function(function, 0) do
    start_time = System.monotonic_time()
    result = function.()
    end_time = System.monotonic_time()

    duration = System.convert_time_unit(end_time - start_time, :native, :millisecond)
    {result, duration}
  end

  @doc """
  Prints connection debug information.
  """
  def debug_conn(%Plug.Conn{} = conn) do
    IO.puts("""
    === Connection Debug Info ===
    Method: #{conn.method}
    Path: #{conn.request_path}
    Query: #{conn.query_string}
    Status: #{conn.status}
    Remote IP: #{format_ip(conn.remote_ip)}
    Headers: #{inspect(conn.req_headers, pretty: true)}
    =============================
    """)

    conn
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp format_ip(ip), do: inspect(ip)

  # Cache utilities

  @doc """
  Gets value from cache or sets it with the result of the function.

  ## Examples

      iex> PhoenixKit.Utils.cache_get_or_set("key", 3600, fn -> "computed_value" end)
      "computed_value"
  """
  def cache_get_or_set(key, ttl, function)
      when is_binary(key) and is_integer(ttl) and is_function(function, 0) do
    case get_from_cache(key) do
      {:ok, value} ->
        value

      {:error, :not_found} ->
        value = function.()
        set_in_cache(key, value, ttl)
        value
    end
  end

  @doc """
  Invalidates cache entries matching the given pattern.

  ## Examples

      iex> PhoenixKit.Utils.invalidate_cache("user:*")
      :ok
  """
  def invalidate_cache(pattern) when is_binary(pattern) do
    # In a real implementation, this would clear cache entries
    # For now, we'll just return :ok
    :ok
  end

  # Performance utilities

  @doc """
  Formats a number with thousand separators.

  ## Examples

      iex> PhoenixKit.Utils.format_number(1234567)
      "1,234,567"
  """
  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
  end

  @doc """
  Converts bytes to human readable format.

  ## Examples

      iex> PhoenixKit.Utils.format_bytes(1024)
      "1.0 KB"
  """
  def format_bytes(bytes) when is_integer(bytes) and bytes >= 0 do
    format_file_size(bytes)
  end

  @doc """
  Generates a random string of the specified length.

  ## Examples

      iex> PhoenixKit.Utils.random_string(10)
      "A3xK9mN2qR"
  """
  def random_string(length) when is_integer(length) and length > 0 do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @doc """
  Safely parses an integer from a string.

  ## Examples

      iex> PhoenixKit.Utils.safe_parse_int("123")
      {:ok, 123}
      
      iex> PhoenixKit.Utils.safe_parse_int("abc")
      {:error, :invalid_integer}
  """
  def safe_parse_int(string) when is_binary(string) do
    case Integer.parse(string) do
      {integer, ""} -> {:ok, integer}
      _ -> {:error, :invalid_integer}
    end
  end

  # Private helper functions

  defp get_from_cache(key) do
    # In a real implementation, this would get from cache (Redis, ETS, etc.)
    # For now, we'll always return not found
    {:error, :not_found}
  end

  defp set_in_cache(key, value, ttl) do
    # In a real implementation, this would set in cache
    # For now, we'll just return :ok
    :ok
  end
end
