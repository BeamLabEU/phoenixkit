defmodule PhoenixKit.Install.LayoutConfig do
  @moduledoc """
  Handles layout integration configuration for PhoenixKit installation.

  This module provides functionality to:
  - Detect app layouts using Phoenix conventions
  - Add layout configuration to config files
  - Handle recompilation requirements
  - Generate appropriate notices for layout setup
  """

  alias Igniter.Project.{Application, Config}
  alias Igniter.Project.Module, as: IgniterModule

  @doc """
  Adds layout integration configuration to the Phoenix application.

  ## Parameters
  - `igniter` - The igniter context

  ## Returns
  Updated igniter with layout configuration and notices.
  """
  def add_layout_integration_configuration(igniter) do
    case detect_app_layouts(igniter) do
      {igniter, nil} ->
        # No layouts detected, use PhoenixKit defaults
        add_layout_integration_notice(igniter, :no_layouts_detected)

      {igniter, {layouts_module, _}} ->
        # Add layout configuration to config.exs
        igniter
        |> add_layout_config(layouts_module)
        |> add_layout_integration_notice(:layouts_detected)
    end
  end

  # Detect app layouts using IgniterPhoenix
  defp detect_app_layouts(igniter) do
    case Application.app_name(igniter) do
      nil -> {igniter, nil}
      app_name -> detect_layouts_for_app(igniter, app_name)
    end
  end

  # Try to detect layouts module following Phoenix conventions
  defp detect_layouts_for_app(igniter, app_name) do
    app_web_module = Module.concat([Macro.camelize(to_string(app_name)) <> "Web"])
    layouts_module = Module.concat([app_web_module, "Layouts"])

    case IgniterModule.module_exists(igniter, layouts_module) do
      {true, igniter} ->
        {igniter, {layouts_module, :app}}

      {false, igniter} ->
        try_alternative_layouts_pattern(igniter, app_name)
    end
  end

  # Try alternative patterns like MyApp.Layouts
  defp try_alternative_layouts_pattern(igniter, app_name) do
    alt_layouts_module = Module.concat([Macro.camelize(to_string(app_name)), "Layouts"])

    case IgniterModule.module_exists(igniter, alt_layouts_module) do
      {true, igniter} -> {igniter, {alt_layouts_module, :app}}
      {false, igniter} -> {igniter, nil}
    end
  end

  # Add layout configuration to config.exs
  defp add_layout_config(igniter, layouts_module) do
    # Add layout configuration with inline comments
    igniter
    |> add_layout_config_with_comments(layouts_module)
    |> recompile_phoenix_kit_dependency()
  end

  # Add layout configuration with comments
  defp add_layout_config_with_comments(igniter, layouts_module) do
    # First add layout config using standard Igniter methods
    igniter
    |> Config.configure_new(
      "config.exs",
      :phoenix_kit,
      [:layout],
      {layouts_module, :app}
    )
    |> Config.configure_new(
      "config.exs",
      :phoenix_kit,
      [:root_layout],
      {layouts_module, :root}
    )
    # Then add comment above layout config
    |> add_comment_to_layout_config()
    |> add_manual_comment_instruction(layouts_module)
  end

  # Add comment above layout configuration in config file
  defp add_comment_to_layout_config(igniter) do
    config_path = "config/config.exs"

    Igniter.update_file(igniter, config_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      # Only add comment if it doesn't already exist
      if String.contains?(
           content,
           "# IMPORTANT: After changing these settings, run: mix deps.compile phoenix_kit --force"
         ) do
        # Comment already exists, no changes needed
        source
      else
        # Add comment before layout line
        updated_content =
          String.replace(
            content,
            "layout:",
            "# IMPORTANT: After changing these settings, run: mix deps.compile phoenix_kit --force\n  layout:",
            # Only replace first occurrence
            global: false
          )

        Rewrite.Source.update(source, :content, updated_content)
      end
    end)
  end

  # Add brief reminder about recompilation
  defp add_manual_comment_instruction(igniter, _layouts_module) do
    notice = "🎨 Layout integration configured"
    Igniter.add_notice(igniter, notice)
  end

  # Skip redundant layout notice since already covered
  defp add_layout_integration_notice(igniter, :layouts_detected) do
    igniter
  end

  defp add_layout_integration_notice(igniter, :no_layouts_detected) do
    notice = "💡 To integrate with your app's design, see layout configuration in README.md"
    Igniter.add_notice(igniter, notice)
  end

  # Recompile PhoenixKit dependency to pick up layout configuration changes
  defp recompile_phoenix_kit_dependency(igniter) do
    # Since this is running during installation, we need to recompile the dependency
    # to ensure the layout configuration changes are picked up immediately
    recompile_notice = """

    🔄 Recompiling PhoenixKit to apply layout configuration...
    """

    igniter = Igniter.add_notice(igniter, recompile_notice)

    # Run the recompilation in the background using System.cmd instead of Mix task
    # to avoid potential issues with Mix state during Igniter execution
    try do
      {output, exit_code} =
        System.cmd("mix", ["deps.compile", "phoenix_kit", "--force"], stderr_to_stdout: true)

      if exit_code == 0 do
        success_notice = "✅ PhoenixKit dependency recompiled successfully!"
        Igniter.add_notice(igniter, success_notice)
      else
        warning_notice =
          "⚠️ Could not automatically recompile PhoenixKit dependency. Output: #{String.slice(output, 0, 200)}"

        Igniter.add_warning(igniter, warning_notice)
      end
    rescue
      _ ->
        warning_notice =
          "⚠️ Could not automatically recompile PhoenixKit dependency. Please run: mix deps.compile phoenix_kit --force"

        Igniter.add_warning(igniter, warning_notice)
    end
  end
end
