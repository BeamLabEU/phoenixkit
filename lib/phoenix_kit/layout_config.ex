defmodule PhoenixKit.LayoutConfig do
  @moduledoc """
  Configuration manager for PhoenixKit layout integration.

  This module provides functions to retrieve and validate layout configuration
  from the application environment, with fallback to default PhoenixKit layouts.

  ## Configuration

  Configure layouts in your application config:

      # Minimal configuration - only app layout
      config :phoenix_kit, layout: {MyAppWeb.Layouts, :app}
      
      # Full configuration - both root and app layouts  
      config :phoenix_kit, 
        root_layout: {MyAppWeb.Layouts, :root},
        layout: {MyAppWeb.Layouts, :app}
        
      # With additional options
      config :phoenix_kit,
        layout: {MyAppWeb.Layouts, :app},
        page_title_prefix: "Auth"

  ## Usage

      iex> PhoenixKit.LayoutConfig.get_layout()
      {PhoenixKitWeb.Layouts, :app}
      
      iex> PhoenixKit.LayoutConfig.get_root_layout()
      {PhoenixKitWeb.Layouts, :root}
  """

  @default_layout {PhoenixKitWeb.Layouts, :app}
  @default_root_layout {PhoenixKitWeb.Layouts, :root}

  @doc """
  Gets the configured app layout module and template.

  Returns the configured layout tuple or falls back to default PhoenixKit layout.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :layout, {MyApp.Layouts, :app})
      iex> PhoenixKit.LayoutConfig.get_layout()
      {MyApp.Layouts, :app}
      
      iex> Application.delete_env(:phoenix_kit, :layout)
      iex> PhoenixKit.LayoutConfig.get_layout()
      {PhoenixKitWeb.Layouts, :app}
  """
  @spec get_layout() :: {module(), atom()}
  def get_layout do
    case Application.get_env(:phoenix_kit, :layout) do
      {module, template} when is_atom(module) and is_atom(template) ->
        validate_layout_module(module, template, @default_layout)

      _ ->
        @default_layout
    end
  end

  @doc """
  Gets the configured root layout module and template.

  Returns the configured root layout tuple or falls back to default PhoenixKit root layout.
  Root layout is optional and defaults to app layout if not specified.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :root_layout, {MyApp.Layouts, :root})
      iex> PhoenixKit.LayoutConfig.get_root_layout()
      {MyApp.Layouts, :root}
      
      iex> Application.delete_env(:phoenix_kit, :root_layout)
      iex> PhoenixKit.LayoutConfig.get_root_layout()
      {PhoenixKitWeb.Layouts, :root}
  """
  @spec get_root_layout() :: {module(), atom()}
  def get_root_layout do
    case Application.get_env(:phoenix_kit, :root_layout) do
      {module, template} when is_atom(module) and is_atom(template) ->
        validate_layout_module(module, template, @default_root_layout)

      _ ->
        # Fallback: try to use app layout's root layout, or default root layout
        case get_layout() do
          {layout_module, _} ->
            # Try to use the same module as app layout but with :root template
            validate_layout_module(layout_module, :root, @default_root_layout)

          _ ->
            @default_root_layout
        end
    end
  end

  @doc """
  Gets the configured page title prefix for authentication pages.

  ## Examples

      iex> Application.put_env(:phoenix_kit, :page_title_prefix, "Auth")
      iex> PhoenixKit.LayoutConfig.get_page_title_prefix()
      "Auth"
      
      iex> Application.delete_env(:phoenix_kit, :page_title_prefix)
      iex> PhoenixKit.LayoutConfig.get_page_title_prefix()
      nil
  """
  @spec get_page_title_prefix() :: String.t() | nil
  def get_page_title_prefix do
    case Application.get_env(:phoenix_kit, :page_title_prefix) do
      prefix when is_binary(prefix) -> prefix
      _ -> nil
    end
  end

  @doc """
  Checks if a custom layout is configured (not using default PhoenixKit layouts).

  ## Examples

      iex> Application.put_env(:phoenix_kit, :layout, {MyApp.Layouts, :app})
      iex> PhoenixKit.LayoutConfig.custom_layout?()
      true
      
      iex> Application.delete_env(:phoenix_kit, :layout)
      iex> PhoenixKit.LayoutConfig.custom_layout?()
      false
  """
  @spec custom_layout?() :: boolean()
  def custom_layout? do
    get_layout() != @default_layout
  end

  @doc """
  Gets all layout configuration as a map for debugging purposes.

  ## Examples

      iex> PhoenixKit.LayoutConfig.get_config()
      %{
        layout: {PhoenixKitWeb.Layouts, :app},
        root_layout: {PhoenixKitWeb.Layouts, :root},
        page_title_prefix: nil,
        custom_layout?: false
      }
  """
  @spec get_config() :: map()
  def get_config do
    %{
      layout: get_layout(),
      root_layout: get_root_layout(),
      page_title_prefix: get_page_title_prefix(),
      custom_layout?: custom_layout?()
    }
  end

  # Private functions

  @spec validate_layout_module(module(), atom(), {module(), atom()}) :: {module(), atom()}
  defp validate_layout_module(module, template, fallback) do
    # For PhoenixKitWeb.Layouts, always allow (it's our own module)
    if module == PhoenixKitWeb.Layouts do
      {module, template}
    else
      # For external modules, try multiple validation approaches
      cond do
        # First check: module is already loaded
        Code.ensure_loaded?(module) ->
          {module, template}

        # Second check: try to load module (may fail during compilation)
        match?({:module, _}, Code.ensure_loaded(module)) ->
          {module, template}

        # Third check: assume external modules will be available at runtime
        # Only warn if we're in a running application context (not compilation)
        Process.whereis(:application_controller) != nil ->
          require Logger

          # Use debug level for auto-generated test module names to reduce noise
          module_string = to_string(module)

          is_auto_generated_test =
            String.contains?(module_string, "Test") and
              Application.get_env(:phoenix_kit, :layout) == nil

          if is_auto_generated_test do
            # Don't log anything for auto-generated test modules - they're expected to not exist
            :ok
          else
            Logger.warning(
              "[PhoenixKit] Layout module #{inspect(module)} not found at runtime, using fallback #{inspect(fallback)}"
            )
          end

          fallback

        # During compilation, trust that external modules will be available
        true ->
          {module, template}
      end
    end
  end
end
