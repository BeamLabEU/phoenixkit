defmodule PhoenixKit.UtilitiesController do
  use Phoenix.Controller,
    formats: [:html, :json]

  import Plug.Conn
  import Phoenix.HTML

  alias PhoenixKit.UtilitiesHTML

  @moduledoc """
  Utilities controller for PhoenixKit extension.

  Showcases helper functions and development tools.
  """

  @doc """
  Renders the utilities page with available tools and helpers.
  """
  def index(conn, _params) do
    utilities = get_available_utilities()

    conn
    |> put_view(UtilitiesHTML)
    |> render(:index,
      title: "PhoenixKit Utilities",
      subtitle: "Helper functions and development tools",
      utilities: utilities,
      categories: get_utility_categories()
    )
  end

  defp get_available_utilities do
    [
      %{
        name: "Date Formatters",
        category: "formatting",
        description: "Common date and time formatting functions",
        functions: [
          %{
            name: "format_date/1",
            signature: "format_date(date)",
            description: "Formats a date in human-readable format",
            example: "PhoenixKit.Utils.format_date(~D[2024-01-15]) # \"January 15, 2024\""
          },
          %{
            name: "time_ago/1",
            signature: "time_ago(datetime)",
            description: "Returns relative time string",
            example: "PhoenixKit.Utils.time_ago(datetime) # \"2 hours ago\""
          }
        ]
      },
      %{
        name: "String Helpers",
        category: "formatting",
        description: "String manipulation and formatting utilities",
        functions: [
          %{
            name: "truncate/2",
            signature: "truncate(string, length)",
            description: "Truncates string to specified length",
            example: "PhoenixKit.Utils.truncate(\"Long text...\", 10) # \"Long text...\""
          },
          %{
            name: "slug/1",
            signature: "slug(string)",
            description: "Converts string to URL-friendly slug",
            example: "PhoenixKit.Utils.slug(\"Hello World\") # \"hello-world\""
          }
        ]
      },
      %{
        name: "Validation Helpers",
        category: "validation",
        description: "Common validation functions for forms",
        functions: [
          %{
            name: "validate_email/1",
            signature: "validate_email(email)",
            description: "Validates email format",
            example: "PhoenixKit.Utils.validate_email(\"user@example.com\") # true"
          },
          %{
            name: "validate_password_strength/1",
            signature: "validate_password_strength(password)",
            description: "Checks password complexity",
            example: "PhoenixKit.Utils.validate_password_strength(\"SecureP@ss123\") # :strong"
          }
        ]
      },
      %{
        name: "File Helpers",
        category: "files",
        description: "File handling and processing utilities",
        functions: [
          %{
            name: "get_file_size/1",
            signature: "get_file_size(file_path)",
            description: "Returns human-readable file size",
            example: "PhoenixKit.Utils.get_file_size(\"/path/to/file\") # \"1.5 MB\""
          },
          %{
            name: "validate_file_type/2",
            signature: "validate_file_type(file, allowed_types)",
            description: "Validates file type against allowed list",
            example: "PhoenixKit.Utils.validate_file_type(upload, [\"jpg\", \"png\"]) # true"
          }
        ]
      },
      %{
        name: "Development Tools",
        category: "development",
        description: "Tools for debugging and development",
        functions: [
          %{
            name: "benchmark/1",
            signature: "benchmark(function)",
            description: "Measures function execution time",
            example:
              "PhoenixKit.Utils.benchmark(fn -> expensive_operation() end) # {result, 150.2}"
          },
          %{
            name: "debug_conn/1",
            signature: "debug_conn(conn)",
            description: "Prints connection debug information",
            example: "PhoenixKit.Utils.debug_conn(conn) # Prints conn details"
          }
        ]
      },
      %{
        name: "Cache Helpers",
        category: "performance",
        description: "Caching utilities for improved performance",
        functions: [
          %{
            name: "cache_get_or_set/3",
            signature: "cache_get_or_set(key, ttl, function)",
            description: "Gets from cache or sets with function result",
            example:
              "PhoenixKit.Utils.cache_get_or_set(\"user:1\", 3600, fn -> fetch_user(1) end)"
          },
          %{
            name: "invalidate_cache/1",
            signature: "invalidate_cache(pattern)",
            description: "Invalidates cache entries matching pattern",
            example: "PhoenixKit.Utils.invalidate_cache(\"user:*\") # Clears all user cache"
          }
        ]
      }
    ]
  end

  defp get_utility_categories do
    [
      %{
        name: "formatting",
        label: "Formatting",
        icon: "✏️",
        description: "Text and data formatting utilities"
      },
      %{
        name: "validation",
        label: "Validation",
        icon: "✅",
        description: "Input validation helpers"
      },
      %{
        name: "files",
        label: "File Handling",
        icon: "📁",
        description: "File processing utilities"
      },
      %{
        name: "development",
        label: "Development",
        icon: "🔧",
        description: "Debugging and development tools"
      },
      %{
        name: "performance",
        label: "Performance",
        icon: "🚀",
        description: "Caching and optimization helpers"
      }
    ]
  end
end
