defmodule PhoenixKitWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for PhoenixKit authentication interface.

  These components are used throughout the authentication system
  to provide a consistent user interface.
  """
  use Phoenix.Component

  use Gettext, backend: PhoenixKitWeb.Gettext
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS
  alias PhoenixKit.ThemeConfig

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:email]} type="email" label="Email"/>
        <.input field={@form[:password]} type="password" label="Password" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-base-100">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, ID, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-base-content">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox checkbox-primary"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="select select-bordered w-full mt-2"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "textarea textarea-bordered w-full mt-2 min-h-[6rem]",
          @errors != [] && "textarea-error"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "input input-bordered w-full mt-2",
          @errors != [] && "input-error"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="label">
      <span class="label-text font-semibold">{render_slot(@inner_block)}</span>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 flex gap-2 text-sm text-error phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-4 w-4 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "btn btn-primary phx-submit-loading:opacity-75",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an icon.
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(PhoenixKitWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PhoenixKitWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_error(msg), do: msg

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_flash("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with all flash messages.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex-none">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  @doc """
  Renders a theme switcher component for light/dark mode toggle.

  This component automatically integrates with the PhoenixKit theme system
  and persists theme preferences in localStorage.

  ## Examples

      <.theme_switcher />
      
      <.theme_switcher class="mr-4" />
      
      <.theme_switcher show_label={true} />

  ## Features

  - Automatic theme detection from system preferences
  - Light/Dark/Auto mode support  
  - DaisyUI integration
  - localStorage persistence
  - Accessible keyboard navigation
  - Beautiful icons and animations
  """
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :show_label, :boolean, default: false, doc: "Show text label next to switcher"

  attr :size, :string,
    default: "normal",
    values: ~w(small normal large),
    doc: "Size of the switcher"

  attr :rest, :global, doc: "Additional HTML attributes"

  def theme_switcher(assigns) do
    # Only render if theme system is enabled
    if ThemeConfig.theme_enabled?() do
      assigns = assign_theme_data(assigns)
      render_theme_switcher(assigns)
    else
      assigns = assign(assigns, :theme_enabled, false)

      ~H"""
      <!-- Theme system disabled -->
      """
    end
  end

  defp assign_theme_data(assigns) do
    theme_config = ThemeConfig.get_theme_config()
    all_themes = ThemeConfig.get_all_daisyui_themes()
    configured_themes = theme_config.themes
    theme_categories = group_themes_by_category(configured_themes)

    assigns
    |> assign(:theme_enabled, true)
    |> assign(:current_theme, theme_config.mode)
    |> assign(:configured_themes, configured_themes)
    |> assign(:all_daisyui_themes, all_themes)
    |> assign(:theme_categories, theme_categories)
    |> assign(:daisyui_version, ThemeConfig.get_daisyui_version())
    |> assign(:theme_controller_enabled, ThemeConfig.theme_controller_enabled?())
    |> assign(:storage_method, theme_config.storage)
    |> assign(:modern_css_variables, ThemeConfig.modern_css_variables())
    |> assign(:data_attributes, ThemeConfig.theme_data_attributes())
  end

  # Group themes by their categories for better UI organization
  defp group_themes_by_category(themes) do
    themes
    |> Enum.group_by(&ThemeConfig.theme_category/1)
    |> Map.new(fn {category, theme_list} -> {category, Enum.sort(theme_list)} end)
  end

  defp render_theme_switcher(assigns) do
    ~H"""
    <div
      class={["phoenix-kit-theme-switcher flex items-center gap-2", @class]}
      {@data_attributes}
      {@rest}
    >
      
    <!-- Theme Toggle Button with enhanced daisyUI 5 support -->
      <div class="dropdown dropdown-end">
        <div
          tabindex="0"
          role="button"
          class={theme_button_classes(@size)}
          id="phoenix-kit-theme-btn"
          aria-label={"Switch theme (current: #{theme_display_name(@current_theme)})"}
          title={"Current: #{theme_display_name(@current_theme)}"}
        >
          <.theme_icon theme={@current_theme} size={@size} />
        </div>
        
    <!-- Enhanced Dropdown Menu with categorized themes -->
        <ul
          tabindex="0"
          class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-100 rounded-box w-80 max-h-96 overflow-y-auto"
        >
          
    <!-- Theme Categories Section -->
          <div :if={map_size(@theme_categories) > 0} class="space-y-1">
            
    <!-- Light Themes -->
            <div :if={Map.get(@theme_categories, :light_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                ☀️ Light Themes
              </div>
              <div class="grid grid-cols-2 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :light_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-xs">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
            
    <!-- Dark Themes -->
            <div :if={Map.get(@theme_categories, :dark_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                🌙 Dark Themes
              </div>
              <div class="grid grid-cols-2 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :dark_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-xs">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
            
    <!-- Colorful Themes -->
            <div :if={Map.get(@theme_categories, :colorful_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                🎨 Colorful Themes
              </div>
              <div class="grid grid-cols-2 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :colorful_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-xs">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
            
    <!-- Professional Themes -->
            <div :if={Map.get(@theme_categories, :professional_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                💼 Professional
              </div>
              <div class="grid grid-cols-2 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :professional_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-xs">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
            
    <!-- New daisyUI 5 Themes -->
            <div :if={Map.get(@theme_categories, :new_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                ✨ New in v5
              </div>
              <div class="grid grid-cols-2 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :new_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-xs">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
            
    <!-- Custom PhoenixKit Themes -->
            <div :if={Map.get(@theme_categories, :custom_themes)} class="px-2 py-1">
              <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2">
                🚀 PhoenixKit
              </div>
              <div class="grid grid-cols-1 gap-1">
                <button
                  :for={theme <- Map.get(@theme_categories, :custom_themes, [])}
                  type="button"
                  class={theme_controller_button_classes(theme == @current_theme)}
                  phx-click={switch_theme_js(theme)}
                  data-theme={theme}
                  aria-pressed={to_string(theme == @current_theme)}
                >
                  <.theme_icon theme={theme} size="sm" />
                  <span class="text-sm font-medium">{theme_display_name(theme)}</span>
                  <.theme_check_icon :if={theme == @current_theme} />
                </button>
              </div>
            </div>
          </div>
          
    <!-- Separator -->
          <li><hr class="my-2" /></li>
          
    <!-- Auto mode (system preference) with enhanced UI -->
          <li>
            <button
              type="button"
              class={[
                "flex items-center gap-3 px-3 py-2 rounded-lg transition-all duration-200",
                if(@current_theme == :auto,
                  do: "bg-primary text-primary-content",
                  else: "hover:bg-base-200"
                )
              ]}
              phx-click={switch_theme_js(:auto)}
              data-theme="auto"
              aria-pressed={to_string(@current_theme == :auto)}
              title="Automatically switch between light and dark based on system preference"
            >
              <.theme_icon theme={:auto} size="sm" />
              <div class="flex flex-col items-start">
                <span class="text-sm font-medium">Auto (System)</span>
                <span class="text-xs opacity-60">Follows system preference</span>
              </div>
              <.theme_check_icon :if={@current_theme == :auto} />
            </button>
          </li>
        </ul>
      </div>
      
    <!-- Optional Label with theme count -->
      <span :if={@show_label} class="text-sm text-base-content/70">
        Theme <span class="text-xs opacity-50">({length(@configured_themes)})</span>
      </span>
    </div>
    """
  end

  # Enhanced theme icon component with size support and all daisyUI 5 themes
  defp theme_icon(assigns) do
    assigns =
      assigns
      |> assign_new(:size, fn -> "md" end)
      |> assign(:icon_classes, theme_icon_classes(assigns[:size] || "md"))

    ~H"""
    <span class={@icon_classes}>
      <%= case @theme do %>
        <% :light -> %>
          <svg fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
              clip-rule="evenodd"
            />
          </svg>
        <% :dark -> %>
          <svg fill="currentColor" viewBox="0 0 20 20">
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
          </svg>
        <% :auto -> %>
          <svg fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M3 5a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2h-2.22l.123.489.804.804A1 1 0 0113 18H7a1 1 0 01-.707-1.707l.804-.804L7.22 15H5a2 2 0 01-2-2V5zm5.771 7H5V5h10v7H8.771z"
              clip-rule="evenodd"
            />
          </svg>
        <% :synthwave -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
          </svg>
        <% :dracula -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z" />
          </svg>
        <% :nord -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2l1.5 4.5L18 8l-4.5 1.5L12 14l-1.5-4.5L6 8l4.5-1.5L12 2zm0 16.5L11 21l-3-1 1-3 3 1zm5-13L18 4l3 1-1 3-3-1zm-10 0L6 4l-3 1 1 3 3-1z" />
          </svg>
        <% :retro -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <rect x="2" y="6" width="20" height="12" rx="2" /><circle cx="7" cy="12" r="2" /><circle
              cx="17"
              cy="12"
              r="2"
            />
          </svg>
        <% :cyberpunk -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2L2 7v10c0 5.55 3.84 10 9 11 1.74-.96 3-2.74 3-4.8V14h5l1.94-3.5L23 9l-1.94-3.5L20 4l-8 0z" />
          </svg>
        <% :cupcake -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12.8 3.6c-.4-.8-1.2-.6-1.6 0L8 12h8l-3.2-8.4zm-6.3 9.9c-.4.4-.4 1 0 1.4l6 6c.4.4 1 .4 1.4 0l6-6c.4-.4.4-1 0-1.4L17 12H7l-0.5 1.5z" />
          </svg>
        <% :bumblebee -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <ellipse cx="12" cy="12" rx="10" ry="6" /><ellipse cx="12" cy="8" rx="8" ry="2" /><ellipse
              cx="12"
              cy="16"
              rx="8"
              ry="2"
            />
          </svg>
        <% :emerald -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2l4 4 4-2-2 4 4 4-4 2-2 4-4-2-4 2-2-4-4-2 4-4-2-4 4 2z" />
          </svg>
        <% :corporate -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <rect x="4" y="4" width="16" height="16" rx="2" /><rect x="9" y="9" width="6" height="2" /><rect
              x="9"
              y="12"
              width="6"
              height="2"
            />
          </svg>
        <% :caramellatte -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M7 3h10c1.1 0 2 .9 2 2v14c0 1.1-.9 2-2 2H7c-1.1 0-2-.9-2-2V5c0-1.1.9-2 2-2zm3 16h4v-2h-4v2zm0-4h4v-2h-4v2zm0-4h4V9h-4v2z" />
          </svg>
        <% :abyss -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" /><circle
              cx="12"
              cy="12"
              r="6"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
            /><circle cx="12" cy="12" r="2" />
          </svg>
        <% :silk -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
          </svg>
        <% :phoenixkit_pro -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /><circle
              cx="12"
              cy="12"
              r="3"
              fill="none"
              stroke="currentColor"
              stroke-width="1"
            />
          </svg>
        <% :phoenixkit_dark -> %>
          <svg fill="currentColor" viewBox="0 0 24 24">
            <path d="M21.64 13a1 1 0 0 0-1.05-.14 8.05 8.05 0 0 1-3.37.73A8.15 8.15 0 0 1 9.08 5.49a8.59 8.59 0 0 1 .25-2A1 1 0 0 0 8 2.36 10.14 10.14 0 1 0 22 14.05A1 1 0 0 0 21.64 13Z" /><circle
              cx="12"
              cy="12"
              r="3"
              fill="none"
              stroke="currentColor"
              stroke-width="1"
            />
          </svg>
        <% _ -> %>
          <!-- Default icon for unknown themes -->
          <svg fill="currentColor" viewBox="0 0 20 20">
            <path
              fill-rule="evenodd"
              d="M4 2a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V4a2 2 0 00-2-2H4zm0 2h12v8H4V4z"
              clip-rule="evenodd"
            />
          </svg>
      <% end %>
    </span>
    """
  end

  # Icon size classes
  defp theme_icon_classes("sm"), do: "w-4 h-4 flex-shrink-0"
  defp theme_icon_classes("lg"), do: "w-6 h-6 flex-shrink-0"
  defp theme_icon_classes(_), do: "w-5 h-5 flex-shrink-0"

  # Enhanced check mark icon for selected theme
  defp theme_check_icon(assigns) do
    ~H"""
    <svg
      class="w-4 h-4 text-primary flex-shrink-0 animate-pulse"
      fill="currentColor"
      viewBox="0 0 20 20"
      role="img"
      aria-label="Selected theme"
    >
      <path
        fill-rule="evenodd"
        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  # Theme controller button classes with enhanced styling
  defp theme_controller_button_classes(is_active) do
    base_classes =
      "flex items-center gap-2 px-2 py-1.5 rounded-md text-left transition-all duration-200 min-h-8"

    if is_active do
      "#{base_classes} bg-primary text-primary-content shadow-sm"
    else
      "#{base_classes} hover:bg-base-200 hover:scale-[1.02] active:scale-[0.98]"
    end
  end

  # Enhanced helper functions for daisyUI 5
  defp theme_button_classes("small"),
    do: "btn btn-sm btn-ghost btn-circle transition-all duration-200 hover:scale-110"

  defp theme_button_classes("large"),
    do: "btn btn-lg btn-ghost btn-circle transition-all duration-200 hover:scale-110"

  defp theme_button_classes(_),
    do: "btn btn-ghost btn-circle transition-all duration-200 hover:scale-110"

  # Enhanced theme display names with better formatting
  defp theme_display_name(:light), do: "Light"
  defp theme_display_name(:dark), do: "Dark"
  defp theme_display_name(:auto), do: "Auto"
  defp theme_display_name(:synthwave), do: "Synthwave"
  defp theme_display_name(:dracula), do: "Dracula"
  defp theme_display_name(:nord), do: "Nord"
  defp theme_display_name(:retro), do: "Retro"
  defp theme_display_name(:cyberpunk), do: "Cyberpunk"
  defp theme_display_name(:cupcake), do: "Cupcake"
  defp theme_display_name(:bumblebee), do: "Bumblebee"
  defp theme_display_name(:emerald), do: "Emerald"
  defp theme_display_name(:corporate), do: "Corporate"
  defp theme_display_name(:caramellatte), do: "Caramellatte"
  defp theme_display_name(:abyss), do: "Abyss"
  defp theme_display_name(:silk), do: "Silk"
  defp theme_display_name(:phoenixkit_pro), do: "PhoenixKit Pro"
  defp theme_display_name(:phoenixkit_dark), do: "PhoenixKit Dark"

  defp theme_display_name(theme) when is_atom(theme) do
    theme
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp theme_display_name(theme), do: to_string(theme)

  # Enhanced JavaScript for theme switching with daisyUI 5 support
  defp switch_theme_js(theme) do
    JS.dispatch("phoenixkit:theme-changed",
      detail: %{
        theme: theme,
        source: "theme-switcher",
        timestamp: System.system_time(:millisecond),
        daisyui_version: 5
      }
    )
    # Backward compatibility
    |> JS.dispatch("phoenix-kit:switch-theme", detail: %{theme: theme})
  end

  defp hide_flash(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-out duration-200",
         "opacity-100 translate-y-0 sm:translate-x-0", "opacity-0 translate-y-2 sm:translate-x-2"}
    )
  end
end
