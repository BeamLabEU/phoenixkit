defmodule PhoenixKit.ThemeConfig do
  @moduledoc """
  Configuration manager for PhoenixKit theme system.

  This module provides functions to retrieve and manage theme configuration
  from the application environment, with support for light/dark mode switching
  and custom color schemes.

  ## Configuration

  Configure themes in your application config:

      # Minimal configuration - enable theme system
      config :phoenix_kit, theme_enabled: true
      
      # Full theme configuration
      config :phoenix_kit, 
        theme_enabled: true,
        theme: %{
          mode: :auto,                    # :light, :dark, :auto
          primary_color: "#3b82f6",      # Primary brand color
          themes: [:light, :dark],        # Available themes
          storage: :local_storage         # :local_storage, :session, :cookie
        }

  ## Usage

      iex> PhoenixKit.ThemeConfig.theme_enabled?()
      true
      
      iex> PhoenixKit.ThemeConfig.get_theme_mode()
      :auto
      
      iex> PhoenixKit.ThemeConfig.theme_css_variables()
      "--primary-color: #3b82f6; --theme-mode: auto;"

  ## DaisyUI Integration

  PhoenixKit integrates with DaisyUI themes out of the box:
  - `light` theme maps to DaisyUI's `light` theme
  - `dark` theme maps to DaisyUI's `dark` theme
  - Custom themes can be configured through DaisyUI's theme system
  """

  @default_theme_config %{
    mode: :auto,
    primary_color: "#3b82f6",
    themes: [:light, :dark],
    storage: :local_storage
  }

  @doc """
  Checks if the theme system is enabled.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme_enabled, true)
      iex> PhoenixKit.ThemeConfig.theme_enabled?()
      true
      
      iex> Application.put_env(:phoenix_kit, :theme_enabled, false)
      iex> PhoenixKit.ThemeConfig.theme_enabled?()
      false
  """
  @spec theme_enabled?() :: boolean()
  def theme_enabled? do
    Application.get_env(:phoenix_kit, :theme_enabled, false)
  end

  @doc """
  Gets the complete theme configuration.

  Returns the configured theme map or falls back to default configuration.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme, %{mode: :dark})
      iex> PhoenixKit.ThemeConfig.get_theme_config()
      %{mode: :dark, primary_color: "#3b82f6", themes: [:light, :dark], storage: :local_storage}
      
      iex> Application.delete_env(:phoenix_kit, :theme)
      iex> PhoenixKit.ThemeConfig.get_theme_config()
      %{mode: :auto, primary_color: "#3b82f6", themes: [:light, :dark], storage: :local_storage}
  """
  @spec get_theme_config() :: map()
  def get_theme_config do
    case Application.get_env(:phoenix_kit, :theme) do
      theme when is_map(theme) ->
        Map.merge(@default_theme_config, theme)

      _ ->
        @default_theme_config
    end
  end

  @doc """
  Gets the configured theme mode.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme, %{mode: :dark})
      iex> PhoenixKit.ThemeConfig.get_theme_mode()
      :dark
      
      iex> Application.delete_env(:phoenix_kit, :theme)
      iex> PhoenixKit.ThemeConfig.get_theme_mode()
      :auto
  """
  @spec get_theme_mode() :: :light | :dark | :auto
  def get_theme_mode do
    get_theme_config().mode
  end

  @doc """
  Gets the configured primary color.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme, %{primary_color: "#10b981"})
      iex> PhoenixKit.ThemeConfig.get_primary_color()
      "#10b981"
  """
  @spec get_primary_color() :: String.t()
  def get_primary_color do
    get_theme_config().primary_color
  end

  @doc """
  Gets the list of supported themes.

  ## Examples

      iex> PhoenixKit.ThemeConfig.get_supported_themes()
      [:light, :dark]
  """
  @spec get_supported_themes() :: [atom()]
  def get_supported_themes do
    get_theme_config().themes
  end

  @doc """
  Gets the theme storage method.

  ## Examples

      iex> PhoenixKit.ThemeConfig.get_storage_method()
      :local_storage
  """
  @spec get_storage_method() :: :local_storage | :session | :cookie
  def get_storage_method do
    get_theme_config().storage
  end

  @doc """
  Generates CSS custom properties (variables) for the theme system.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_css_variables()
      "--primary-color: #3b82f6; --theme-mode: auto;"
      
      iex> PhoenixKit.ThemeConfig.theme_css_variables(%{primary_color: "#10b981", mode: :dark})
      "--primary-color: #10b981; --theme-mode: dark;"
  """
  @spec theme_css_variables(map() | nil) :: String.t()
  def theme_css_variables(theme \\ nil) do
    config = theme || get_theme_config()

    variables = [
      "--primary-color: #{config.primary_color}",
      "--theme-mode: #{config.mode}"
    ]

    Enum.join(variables, "; ") <> ";"
  end

  @doc """
  Generates data attributes for theme system integration.

  Used in HTML templates to set theme-related data attributes.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_data_attributes()
      [{"data-theme-mode", "auto"}, {"data-theme-storage", "local_storage"}]
  """
  @spec theme_data_attributes() :: [{String.t(), String.t()}]
  def theme_data_attributes do
    config = get_theme_config()

    [
      {"data-theme-mode", to_string(config.mode)},
      {"data-theme-storage", to_string(config.storage)},
      {"data-themes", Enum.map_join(config.themes, ",", &to_string/1)}
    ]
  end

  @doc """
  Validates if a given theme is supported.

  ## Examples

      iex> PhoenixKit.ThemeConfig.valid_theme?(:light)
      true
      
      iex> PhoenixKit.ThemeConfig.valid_theme?(:purple)
      false
  """
  @spec valid_theme?(atom()) :: boolean()
  def valid_theme?(theme) when is_atom(theme) do
    theme in get_supported_themes()
  end

  def valid_theme?(_), do: false

  @doc """
  Returns the default theme mode for fallback scenarios.

  ## Examples

      iex> PhoenixKit.ThemeConfig.default_theme_mode()
      :light
  """
  @spec default_theme_mode() :: :light
  def default_theme_mode, do: :light

  @doc """
  Gets DaisyUI-compatible theme name.

  Maps PhoenixKit theme modes to DaisyUI theme names.

  ## Examples

      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:light)
      "light"
      
      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:dark)
      "dark"
      
      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:auto)
      "light"
  """
  @spec daisy_theme_name(atom()) :: String.t()
  def daisy_theme_name(:light), do: "light"
  def daisy_theme_name(:dark), do: "dark"
  # Default fallback for auto mode
  def daisy_theme_name(:auto), do: "light"
  # Safe fallback
  def daisy_theme_name(_), do: "light"

  @doc """
  Gets all theme configuration as a map for debugging purposes.

  ## Examples

      iex> PhoenixKit.ThemeConfig.debug_config()
      %{
        enabled: false,
        mode: :auto,
        primary_color: "#3b82f6",
        themes: [:light, :dark],
        storage: :local_storage,
        css_variables: "--primary-color: #3b82f6; --theme-mode: auto;",
        data_attributes: [{"data-theme-mode", "auto"}, ...]
      }
  """
  @spec debug_config() :: map()
  def debug_config do
    config = get_theme_config()

    %{
      enabled: theme_enabled?(),
      mode: config.mode,
      primary_color: config.primary_color,
      themes: config.themes,
      storage: config.storage,
      css_variables: theme_css_variables(config),
      data_attributes: theme_data_attributes()
    }
  end
end
