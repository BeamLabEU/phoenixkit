defmodule BeamLab.PhoenixKitWeb.NavigationComponents do
  @moduledoc """
  Navigation components for PhoenixKit authentication system.
  
  This module provides ready-to-use navbar components for easy integration 
  into Phoenix applications using PhoenixKit in library mode.
  
  ## Usage
  
  Import in your layout module:
  
      import BeamLab.PhoenixKitWeb.NavigationComponents
  
  Then use in templates:
  
      <.simple_navbar current_scope={@current_scope} />
      
  or for advanced dropdown menu:
  
      <.advanced_navbar current_scope={@current_scope} app_name="MyApp" />
  """
  use Phoenix.Component
  
  alias BeamLab.PhoenixKitWeb.CoreComponents
  alias Phoenix.LiveView.JS

  @doc """
  Renders a simple horizontal navigation bar with authentication links.
  
  Based on the standalone PhoenixKit navbar design. Shows authentication 
  state and provides login/logout functionality.
  
  ## Examples
  
      <.simple_navbar current_scope={@current_scope} />
      
      <.simple_navbar 
        current_scope={@current_scope}
        class="bg-base-200"
        show_email={false} />
  """
  attr :current_scope, :map, default: nil, doc: "Current user scope from PhoenixKit authentication"
  attr :class, :string, default: "menu menu-horizontal w-full relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end", doc: "Additional CSS classes"
  attr :show_email, :boolean, default: true, doc: "Whether to show user email when authenticated"

  def simple_navbar(assigns) do
    ~H"""
    <ul class={@class}>
      <%= if @current_scope do %>
        <%= if @show_email do %>
          <li>
            {@current_scope.user.email}
          </li>
        <% end %>
        <li>
          <.link href="/phoenix_kit/settings">Settings</.link>
        </li>
        <li>
          <.link href="/phoenix_kit/log-out" method="delete">Log out</.link>
        </li>
      <% else %>
        <li>
          <.link href="/phoenix_kit/register">Register</.link>
        </li>
        <li>
          <.link href="/phoenix_kit/log-in">Log in</.link>
        </li>
      <% end %>
    </ul>
    """
  end

  @doc """
  Renders a modern navigation bar with dropdown menu and app branding.
  
  Features a full navbar with app name/logo on the left and user menu 
  dropdown on the right. Based on the DaisyUI navbar component.
  
  ## Examples
  
      <.advanced_navbar current_scope={@current_scope} app_name="MyApp" />
      
      <.advanced_navbar 
        current_scope={@current_scope}
        app_name="MyApp"
        home_path="/dashboard"
        include_theme_toggle={true} />
  """
  attr :current_scope, :map, default: nil, doc: "Current user scope from PhoenixKit authentication"
  attr :app_name, :string, required: true, doc: "Application name to display"
  attr :home_path, :string, default: "/", doc: "Path for the home/app name link"
  attr :class, :string, default: "navbar bg-base-100", doc: "CSS classes for the navbar"
  attr :include_theme_toggle, :boolean, default: false, doc: "Whether to include theme toggle button"

  def advanced_navbar(assigns) do
    ~H"""
    <nav class={@class}>
      <div class="navbar-start">
        <.link navigate={@home_path} class="btn btn-ghost text-xl">{@app_name}</.link>
      </div>
      <div class="navbar-end">
        <%= if @include_theme_toggle do %>
          <.theme_toggle />
        <% end %>
        
        <%= if @current_scope do %>
          <.user_menu user={@current_scope.user} />
        <% else %>
          <.link navigate="/phoenix_kit/log-in" class="btn btn-ghost">Log in</.link>
          <.link navigate="/phoenix_kit/register" class="btn btn-primary">Sign up</.link>
        <% end %>
      </div>
    </nav>
    """
  end

  @doc """
  Renders a user dropdown menu for authenticated users.
  
  Shows user email and provides access to settings and logout functionality.
  Designed to be used within advanced_navbar or standalone.
  
  ## Examples
  
      <.user_menu user={@current_scope.user} />
      
      <.user_menu 
        user={@current_scope.user}
        show_profile_link={true}
        additional_links={[
          %{text: "Dashboard", path: "/dashboard"},
          %{text: "Billing", path: "/billing"}
        ]} />
  """
  attr :user, :map, required: true, doc: "User record with email field"
  attr :show_profile_link, :boolean, default: false, doc: "Whether to show profile link"
  attr :additional_links, :list, default: [], doc: "Additional menu items as %{text: string, path: string}"

  def user_menu(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost">
        {@user.email}
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
        <%= if @show_profile_link do %>
          <li><.link navigate="/phoenix_kit/profile">Profile</.link></li>
        <% end %>
        
        <%= for link <- @additional_links do %>
          <li><.link navigate={link.path}>{link.text}</.link></li>
        <% end %>
        
        <li><.link navigate="/phoenix_kit/settings">Settings</.link></li>
        <li>
          <.link href="/phoenix_kit/log-out" method="delete">
            Log out
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a theme toggle component for switching between light/dark/system themes.
  
  Provides three-way theme switching with visual feedback. Requires the theme
  switching JavaScript to be loaded (included in PhoenixKit by default).
  
  ## Examples
  
      <.theme_toggle />
      
      <.theme_toggle class="ml-4" />
  """
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def theme_toggle(assigns) do
    ~H"""
    <div class={"card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full #{@class}"}>
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <CoreComponents.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <CoreComponents.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <CoreComponents.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end