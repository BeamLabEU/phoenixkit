defmodule PhoenixKit.ThemeConfig do
  @moduledoc """
  Configuration manager for PhoenixKit theme system with daisyUI 5 support.

  This module provides functions to retrieve and manage theme configuration
  from the application environment, with support for 35+ daisyUI themes,
  modern CSS variables, OKLCH color formats, and theme-controller integration.

  ## Configuration

  Configure themes in your application config:

      # Minimal configuration - enable theme system with daisyUI 5
      config :phoenix_kit, theme_enabled: true
      
      # Full theme configuration with daisyUI 5 themes
      config :phoenix_kit, 
        theme_enabled: true,
        theme: %{
          mode: :auto,                              # :light, :dark, :auto, or any daisyUI theme
          primary_color: "oklch(55% 0.3 240)",     # OKLCH format supported
          themes: [:light, :dark, :synthwave, :dracula, :nord], # 35+ themes available
          storage: :local_storage,                  # :local_storage, :session, :cookie
          daisyui_version: 5,                      # daisyUI version (4 or 5)
          theme_controller: true                    # Enable built-in theme-controller
        }

  ## Usage

      iex> PhoenixKit.ThemeConfig.theme_enabled?()
      true
      
      iex> PhoenixKit.ThemeConfig.get_theme_mode()
      :auto
      
      iex> PhoenixKit.ThemeConfig.modern_css_variables()
      "--color-primary: oklch(55% 0.3 240); --theme-mode: auto;"

  ## daisyUI 5 Integration

  PhoenixKit now supports all 35+ daisyUI 5 themes:
  - **Light**: light, cupcake, bumblebee, emerald, corporate, garden, lofi, pastel, fantasy, wireframe
  - **Dark**: dark, synthwave, halloween, forest, black, luxury, dracula, business, night, coffee
  - **Colorful**: retro, cyberpunk, valentine, aqua, acid, lemonade, winter
  - **Professional**: cmyk, autumn, dim, nord, sunset
  - **New in v5**: caramellatte, abyss, silk
  - Full theme-controller integration for automatic theme switching
  - OKLCH color format support for precise color matching
  """

  # All supported daisyUI 5 themes (35+ themes)
  @daisyui_5_themes [
    # Light themes
    :light,
    :cupcake,
    :bumblebee,
    :emerald,
    :corporate,
    :garden,
    :lofi,
    :pastel,
    :fantasy,
    :wireframe,

    # Dark themes  
    :dark,
    :synthwave,
    :halloween,
    :forest,
    :black,
    :luxury,
    :dracula,
    :business,
    :night,
    :coffee,

    # Colorful themes
    :retro,
    :cyberpunk,
    :valentine,
    :aqua,
    :acid,
    :lemonade,
    :winter,

    # Professional themes
    :cmyk,
    :autumn,
    :dim,
    :nord,
    :sunset,

    # New in daisyUI 5
    :caramellatte,
    :abyss,
    :silk
  ]

  @default_theme_config %{
    theme: "auto",
    # OKLCH color format (modern standard)
    primary_color: "oklch(55% 0.3 240)",
    # Default theme selection
    themes: [:light, :dark, :synthwave, :dracula, :nord],
    storage: :local_storage,
    # daisyUI 5 + Tailwind CSS 4 only
    daisyui_version: 5,
    tailwind_version: 4,
    # Always enabled for modern architecture
    theme_controller: true,
    # OKLCH color definitions for all semantic tokens
    oklch_colors: %{
      primary: "oklch(55% 0.3 240)",
      secondary: "oklch(70% 0.25 200)",
      accent: "oklch(65% 0.25 160)",
      neutral: "oklch(50% 0.05 240)",
      "base-100": "oklch(98% 0.02 240)",
      "base-200": "oklch(95% 0.03 240)",
      "base-300": "oklch(92% 0.04 240)",
      "base-content": "oklch(20% 0.05 240)"
    }
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
  Gets the configured default theme.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme, %{theme: "dark"})
      iex> PhoenixKit.ThemeConfig.get_theme()
      "dark"
      
      iex> Application.delete_env(:phoenix_kit, :theme)
      iex> PhoenixKit.ThemeConfig.get_theme()
      "auto"
  """
  @spec get_theme() :: String.t()
  def get_theme do
    case get_theme_config()[:theme] do
      theme when is_binary(theme) -> theme
      theme when is_atom(theme) -> to_string(theme)
      _ -> "auto"
    end
  end

  @doc """
  Gets the configured primary color in OKLCH format.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :theme, %{primary_color: "oklch(60% 0.2 180)"})
      iex> PhoenixKit.ThemeConfig.get_primary_color()
      "oklch(60% 0.2 180)"
  """
  @spec get_primary_color() :: String.t()
  def get_primary_color do
    get_theme_config().primary_color
  end

  @doc """
  Gets all available daisyUI 5 themes.

  Returns the complete list of 35+ supported daisyUI themes as strings.

  ## Examples

      iex> PhoenixKit.ThemeConfig.get_all_daisyui_themes()
      ["light", "dark", "synthwave", "dracula", "nord", "caramellatte", ...]
  """
  @spec get_all_daisyui_themes() :: [String.t()]
  def get_all_daisyui_themes, do: Enum.map(@daisyui_5_themes, &to_string/1)

  @doc """
  Gets the list of configured themes for the current application.

  ## Examples

      iex> PhoenixKit.ThemeConfig.get_supported_themes()
      [:light, :dark, :synthwave, :dracula, :nord]
  """
  @spec get_supported_themes() :: [atom()]
  def get_supported_themes do
    get_theme_config().themes
  end

  @doc """
  Checks if a theme is available in daisyUI 5.

  ## Examples

      iex> PhoenixKit.ThemeConfig.daisyui_theme_available?(:synthwave)
      true
      
      iex> PhoenixKit.ThemeConfig.daisyui_theme_available?(:nonexistent)
      false
  """
  @spec daisyui_theme_available?(atom()) :: boolean()
  def daisyui_theme_available?(theme) when is_atom(theme) do
    theme in @daisyui_5_themes
  end

  def daisyui_theme_available?(_), do: false

  @doc """
  Gets the configured daisyUI version.

  ## Examples

      iex> PhoenixKit.ThemeConfig.get_daisyui_version()
      5
  """
  @spec get_daisyui_version() :: integer()
  def get_daisyui_version do
    get_theme_config()[:daisyui_version] || 5
  end

  @doc """
  Checks if theme-controller is enabled.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_controller_enabled?()
      true
  """
  @spec theme_controller_enabled?() :: boolean()
  def theme_controller_enabled? do
    get_theme_config()[:theme_controller] || false
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
  Generates modern CSS custom properties with daisyUI 5 support.

  Uses the new daisyUI 5 CSS variable naming convention and supports OKLCH colors.

  ## Examples

      iex> PhoenixKit.ThemeConfig.modern_css_variables()
      "--color-primary: oklch(55% 0.3 240); --theme-mode: auto;"
      
      iex> PhoenixKit.ThemeConfig.modern_css_variables(%{oklch_colors: %{primary: "oklch(60% 0.2 180)"}})
      "--color-primary: oklch(60% 0.2 180); --theme-mode: auto;"
  """
  @spec modern_css_variables(map() | nil) :: String.t()
  def modern_css_variables(theme \\ nil) do
    config = theme || get_theme_config()
    oklch_colors = config[:oklch_colors] || @default_theme_config[:oklch_colors]

    variables = [
      "--color-primary: #{oklch_colors[:primary]}",
      "--color-secondary: #{oklch_colors[:secondary]}",
      "--color-accent: #{oklch_colors[:accent]}",
      "--color-neutral: #{oklch_colors[:neutral]}",
      "--color-base-100: #{oklch_colors[:"base-100"]}",
      "--color-base-200: #{oklch_colors[:"base-200"]}",
      "--color-base-300: #{oklch_colors[:"base-300"]}",
      "--color-base-content: #{oklch_colors[:"base-content"]}",
      "--theme-mode: #{get_theme()}",
      "--daisyui-version: #{get_daisyui_version()}"
    ]

    Enum.join(variables, "; ") <> ";"
  end


  @doc """
  Generates data attributes for daisyUI 5 theme system integration.

  Used in HTML templates to set theme-related data attributes with v5 support.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_data_attributes()
      [{"data-theme-mode", "auto"}, {"data-theme-storage", "local_storage"}, {"data-daisyui-version", "5"}]
  """
  @spec theme_data_attributes() :: [{String.t(), String.t()}]
  def theme_data_attributes do
    config = get_theme_config()

    [
      {"data-theme", get_theme()},
      {"data-theme-storage", to_string(config.storage)},
      {"data-themes", Enum.map_join(config.themes, ",", &to_string/1)},
      {"data-daisyui-version", to_string(get_daisyui_version())},
      {"data-theme-controller", to_string(theme_controller_enabled?())},
      {"data-total-themes", to_string(length(@daisyui_5_themes))}
    ]
  end

  @doc """
  Generates theme-controller specific attributes for daisyUI integration.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_controller_attributes(:synthwave)
      [{"data-theme", "synthwave"}, {"value", "synthwave"}, {"class", "theme-controller"}]
  """
  @spec theme_controller_attributes(atom()) :: [{String.t(), String.t()}]
  def theme_controller_attributes(theme) when is_atom(theme) do
    theme_str = daisy_theme_name(theme)

    [
      {"data-theme", theme_str},
      {"value", theme_str},
      {"class", "theme-controller"}
    ]
  end

  @doc """
  Validates if a given theme is supported in the current configuration.

  ## Examples

      iex> PhoenixKit.ThemeConfig.valid_theme?(:light)
      true
      
      iex> PhoenixKit.ThemeConfig.valid_theme?(:synthwave)
      true  # if configured in themes list
      
      iex> PhoenixKit.ThemeConfig.valid_theme?(:nonexistent)
      false
  """
  @spec valid_theme?(atom()) :: boolean()
  def valid_theme?(theme) when is_atom(theme) do
    # Check both configured themes and all available daisyUI themes
    theme in get_supported_themes() or theme in @daisyui_5_themes
  end

  def valid_theme?(_), do: false

  @doc """
  Validates if a given theme is in the user's configured theme list.

  ## Examples

      iex> PhoenixKit.ThemeConfig.configured_theme?(:light)
      true
      
      iex> PhoenixKit.ThemeConfig.configured_theme?(:synthwave)
      false  # unless explicitly configured
  """
  @spec configured_theme?(atom()) :: boolean()
  def configured_theme?(theme) when is_atom(theme) do
    theme in get_supported_themes()
  end

  def configured_theme?(_), do: false

  @doc """
  Returns the default theme mode for fallback scenarios.

  ## Examples

      iex> PhoenixKit.ThemeConfig.default_theme_mode()
      :light
  """
  @spec default_theme_mode() :: :light
  def default_theme_mode, do: :light

  @doc """
  Gets daisyUI-compatible theme name with v5 support.

  Maps PhoenixKit theme modes to daisyUI theme names, supporting all 35+ themes.

  ## Examples

      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:light)
      "light"
      
      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:synthwave)
      "synthwave"
      
      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:caramellatte)
      "caramellatte"
      
      iex> PhoenixKit.ThemeConfig.daisy_theme_name(:auto)
      "light"  # fallback for auto mode
  """
  @spec daisy_theme_name(atom()) :: String.t()
  # Auto mode defaults to light
  def daisy_theme_name(:auto), do: "light"

  def daisy_theme_name(theme) when is_atom(theme) do
    theme_str = to_string(theme)

    # Validate theme exists in daisyUI 5
    if theme in @daisyui_5_themes do
      theme_str
    else
      # Safe fallback
      "light"
    end
  end

  # Safe fallback for non-atoms
  def daisy_theme_name(_), do: "light"

  @doc """
  Gets theme category for UI grouping.

  ## Examples

      iex> PhoenixKit.ThemeConfig.theme_category(:light)
      :light_themes
      
      iex> PhoenixKit.ThemeConfig.theme_category(:synthwave) 
      :dark_themes
      
      iex> PhoenixKit.ThemeConfig.theme_category(:caramellatte)
      :new_themes
  """
  @spec theme_category(atom()) :: atom()
  def theme_category(theme)
      when theme in [
             :light,
             :cupcake,
             :bumblebee,
             :emerald,
             :corporate,
             :garden,
             :lofi,
             :pastel,
             :fantasy,
             :wireframe
           ],
      do: :light_themes

  def theme_category(theme)
      when theme in [
             :dark,
             :synthwave,
             :halloween,
             :forest,
             :black,
             :luxury,
             :dracula,
             :business,
             :night,
             :coffee
           ],
      do: :dark_themes

  def theme_category(theme)
      when theme in [:retro, :cyberpunk, :valentine, :aqua, :acid, :lemonade, :winter],
      do: :colorful_themes

  def theme_category(theme) when theme in [:cmyk, :autumn, :dim, :nord, :sunset],
    do: :professional_themes

  def theme_category(theme) when theme in [:caramellatte, :abyss, :silk], do: :new_themes
  def theme_category(_), do: :unknown

  @doc """
  Gets all theme configuration for debugging daisyUI 5 + Tailwind CSS 4 setup.

  ## Examples

      iex> PhoenixKit.ThemeConfig.debug_config()
      %{
        enabled: true,
        default_theme: "auto",
        daisyui_version: 5,
        tailwind_version: 4,
        configured_themes: ["light", "dark", "synthwave"],
        available_themes: 35,
        oklch_colors: %{primary: "oklch(55% 0.3 240)", ...},
        css_variables: "--color-primary: oklch(55% 0.3 240); ..."
      }
  """
  @spec debug_config() :: map()
  def debug_config do
    config = get_theme_config()

    %{
      enabled: theme_enabled?(),
      default_theme: get_theme(),
      daisyui_version: get_daisyui_version(),
      tailwind_version: config[:tailwind_version] || 4,
      theme_controller: theme_controller_enabled?(),
      primary_color: config.primary_color,
      configured_themes: get_supported_themes(),
      available_themes: length(@daisyui_5_themes),
      all_themes: get_all_daisyui_themes(),
      storage: config.storage,
      oklch_colors: config[:oklch_colors],
      css_variables: modern_css_variables(config),
      data_attributes: theme_data_attributes()
    }
  end

  @doc """
  Gets configuration for parent application integration with Tailwind CSS 4.

  Returns complete setup instructions for modern @plugin integration.

  ## Examples

      iex> PhoenixKit.ThemeConfig.parent_app_config()
      %{
        default_theme: "auto",
        css_plugin: "@plugin \"daisyui\" { themes: light --default, dark --prefersdark, synthwave; }",
        content_paths: ["./lib/**/*.{ex,heex}", "./deps/phoenix_kit/**/*.{ex,heex}"],
        integration_example: "/* In your app.css */\\n@import \"tailwindcss\";\\n@plugin \"daisyui\" { themes: light, dark; };"
      }
  """
  @spec parent_app_config() :: map()
  def parent_app_config do
    config = get_theme_config()
    themes = get_supported_themes()
    default_theme = get_theme()

    theme_list =
      themes
      |> Enum.map(&to_string/1)
      |> Enum.map_join(", ", fn
        "light" -> "light --default"
        "dark" -> "dark --prefersdark"
        theme -> theme
      end)

    integration_css = """
    /* In your app.css */
    @import "tailwindcss";
    @plugin "daisyui" {
      themes: #{theme_list};
    };
    """

    %{
      enabled: theme_enabled?(),
      architecture: "daisyUI 5 + Tailwind CSS 4",
      default_theme: default_theme,
      themes: Enum.map(themes, &to_string/1),
      css_plugin: "@plugin \"daisyui\" { themes: #{theme_list}; }",
      content_paths: [
        "./lib/**/*.{ex,heex,js}",
        "./assets/**/*.js", 
        "./deps/phoenix_kit/**/*.{ex,heex}"
      ],
      integration_example: String.trim(integration_css),
      oklch_colors: config[:oklch_colors],
      storage: config.storage
    }
  end
end
