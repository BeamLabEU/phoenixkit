defmodule Mix.Tasks.PhoenixKit.Uninstall do
  @moduledoc """
  Uninstall PhoenixKit from a Phoenix application.

  This task removes PhoenixKit from your Phoenix application by:

  1. Removing PhoenixKit routes from your router
  2. Removing static assets from your priv/static directory
  3. Removing configuration from your config files
  4. Removing the dependency from mix.exs

  ## Usage

      mix phoenix_kit.uninstall

  ## Options

    * `--keep-config` - Keep PhoenixKit configuration in config files
    * `--keep-assets` - Keep static assets in priv/static
    * `--keep-dependency` - Keep dependency in mix.exs

  ## Examples

      # Complete uninstallation
      mix phoenix_kit.uninstall

      # Uninstall but keep configuration
      mix phoenix_kit.uninstall --keep-config

      # Uninstall but keep assets and config
      mix phoenix_kit.uninstall --keep-config --keep-assets

  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_kit,
      example: "mix phoenix_kit.uninstall",
      positional: [],
      schema: [
        keep_config: :boolean,
        keep_assets: :boolean,
        keep_dependency: :boolean
      ],
      defaults: [
        keep_config: false,
        keep_assets: false,
        keep_dependency: false
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter, argv) do
    options = info(argv, nil)

    igniter
    |> remove_routes()
    |> remove_router_import()
    |> maybe_remove_assets(options)
    |> maybe_remove_config(options)
    |> maybe_remove_dependency(options)
    |> Igniter.add_notice("PhoenixKit uninstalled successfully!")
    |> Igniter.add_notice("Don't forget to run 'mix deps.get' to clean up dependencies")
  end

  defp remove_routes(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      # Remove PhoenixKit routes from the router
      remove_phoenix_kit_routes(zipper)
    end)
  end

  defp remove_phoenix_kit_routes(zipper) do
    # Look for PhoenixKit.routes() calls and remove them
    Igniter.Code.Common.within(zipper, fn zipper ->
      if Igniter.Code.Common.contains_code?(zipper, "PhoenixKit.routes()") do
        Igniter.Code.Common.remove_code(zipper, "PhoenixKit.routes()")
      else
        zipper
      end
    end)
  end

  defp remove_router_import(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      # Remove import PhoenixKit from the router
      Igniter.Code.Common.remove_code(zipper, "import PhoenixKit")
    end)
  end

  defp maybe_remove_assets(igniter, %{schema: schema}) do
    if Keyword.get(schema, :keep_assets, false) do
      igniter
    else
      remove_assets(igniter)
    end
  end

  defp remove_assets(igniter) do
    igniter
    |> Igniter.remove_file("priv/static/phoenix_kit/phoenix_kit.css")
    |> Igniter.remove_file("priv/static/phoenix_kit/phoenix_kit.js")
    |> Igniter.remove_file("priv/static/phoenix_kit")
  end

  defp maybe_remove_config(igniter, %{schema: schema}) do
    if Keyword.get(schema, :keep_config, false) do
      igniter
    else
      remove_config(igniter)
    end
  end

  defp remove_config(igniter) do
    # Remove PhoenixKit configuration from config files
    igniter
    |> Igniter.Project.Config.remove_config("config.exs", [:phoenix_kit])
    |> Igniter.Project.Config.remove_config("dev.exs", [:phoenix_kit])
    |> Igniter.Project.Config.remove_config("prod.exs", [:phoenix_kit])
    |> Igniter.Project.Config.remove_config("test.exs", [:phoenix_kit])
  end

  defp maybe_remove_dependency(igniter, %{schema: schema}) do
    if Keyword.get(schema, :keep_dependency, false) do
      igniter
    else
      remove_dependency(igniter)
    end
  end

  defp remove_dependency(igniter) do
    Igniter.Project.Deps.remove_dependency(igniter, :phoenix_kit)
  end
end
