defmodule Mix.Tasks.PhoenixKit.Update do
  @moduledoc """
  Update PhoenixKit to the latest version.

  This task helps migrate from older versions of PhoenixKit by:

  1. Detecting the current version
  2. Applying necessary migrations
  3. Updating routes and configuration
  4. Providing migration instructions

  ## Usage

      mix phoenix_kit.update

  ## Options

    * `--from-version` - Specify the version to migrate from (auto-detected if not provided)
    * `--dry-run` - Show what would be changed without applying changes
    * `--force` - Force update even if no migration is needed

  ## Examples

      # Auto-detect version and update
      mix phoenix_kit.update

      # Update from specific version
      mix phoenix_kit.update --from-version 0.2.1

      # Preview changes without applying
      mix phoenix_kit.update --dry-run

  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_kit,
      example: "mix phoenix_kit.update",
      positional: [],
      schema: [
        from_version: :string,
        dry_run: :boolean,
        force: :boolean
      ],
      defaults: [
        from_version: nil,
        dry_run: false,
        force: false
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter, argv) do
    options = info(argv, nil)
    current_version = detect_current_version()
    target_version = "0.3.0"

    if options.defaults[:dry_run] do
      preview_changes(igniter, current_version, target_version)
    else
      apply_migration(igniter, current_version, target_version, options)
    end
  end

  defp detect_current_version do
    # Try to detect current version from dependency
    case get_dependency_version(:phoenix_kit) do
      {:ok, version} -> version
      # Default assumption
      {:error, _} -> "0.2.1"
    end
  end

  defp get_dependency_version(dep) do
    case Application.spec(dep, :vsn) do
      vsn when is_list(vsn) -> {:ok, List.to_string(vsn)}
      _ -> {:error, :not_found}
    end
  end

  defp preview_changes(igniter, from_version, to_version) do
    changes = generate_migration_plan(from_version, to_version)

    igniter
    |> Igniter.add_notice("=== PhoenixKit Migration Preview ===")
    |> Igniter.add_notice("From version: #{from_version}")
    |> Igniter.add_notice("To version: #{to_version}")
    |> Igniter.add_notice("")
    |> Igniter.add_notice("Changes that would be applied:")
    |> add_change_notices(changes)
  end

  defp apply_migration(igniter, from_version, to_version, options) do
    cond do
      from_version == to_version and not options.defaults[:force] ->
        igniter
        |> Igniter.add_notice("PhoenixKit is already at version #{to_version}")
        |> Igniter.add_notice("Use --force to re-apply migration")

      Version.compare(from_version, "0.3.0") == :lt ->
        migrate_from_pre_v030(igniter, from_version)

      true ->
        igniter
        |> Igniter.add_notice("No migration needed for version #{from_version}")
    end
  end

  defp migrate_from_pre_v030(igniter, from_version) do
    igniter
    |> Igniter.add_notice("Migrating from PhoenixKit #{from_version} to 0.3.0...")
    |> update_dependency_version()
    |> remove_old_routes()
    |> add_new_routes()
    |> update_imports()
    |> remove_old_components()
    |> add_new_configuration()
    |> Igniter.add_notice("Migration completed!")
    |> Igniter.add_notice("")
    |> Igniter.add_notice("⚠️  BREAKING CHANGES:")
    |> Igniter.add_notice("- PhoenixKit.welcome component has been removed")
    |> Igniter.add_notice("- URL structure changed from /phoenix-kit to /phoenix_kit")
    |> Igniter.add_notice(
      "- Router macro changed from phoenix_kit_routes() to PhoenixKit.routes()"
    )
    |> Igniter.add_notice("")
    |> Igniter.add_notice("✅ What's new:")
    |> Igniter.add_notice("- Full MVC architecture with 4 controllers")
    |> Igniter.add_notice("- 3 LiveView components for real-time interfaces")
    |> Igniter.add_notice("- 100+ utility functions")
    |> Igniter.add_notice("- Security and telemetry systems")
    |> Igniter.add_notice("- Modern daisyUI design")
    |> Igniter.add_notice("")
    |> Igniter.add_notice("Visit http://localhost:4000/phoenix_kit to see the new interface!")
  end

  defp update_dependency_version(igniter) do
    Igniter.Project.Deps.add_dependency(igniter, {:phoenix_kit, "~> 0.3.0"})
  end

  defp remove_old_routes(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      zipper
      |> Igniter.Code.Common.remove_code("phoenix_kit_routes()")
      |> Igniter.Code.Common.remove_code("import PhoenixKit.Router")
    end)
  end

  defp add_new_routes(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    code_to_add = """
    # PhoenixKit v0.3.0 routes
    scope "/phoenix_kit" do
      pipe_through :browser
      PhoenixKit.routes()
    end
    """

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      Igniter.Code.Common.add_code(zipper, code_to_add)
    end)
  end

  defp update_imports(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      Igniter.Code.Common.add_code(zipper, "import PhoenixKit", :beginning)
    end)
  end

  defp remove_old_components(igniter) do
    # This would scan for and remove old PhoenixKit.welcome components
    # For now, just add a notice
    Igniter.add_notice(
      igniter,
      "⚠️  Please manually remove all <PhoenixKit.welcome> components from your templates"
    )
  end

  defp add_new_configuration(igniter) do
    config_content = """
    # PhoenixKit v0.3.0 Configuration
    config :phoenix_kit, PhoenixKit,
      # Basic settings
      enable_dashboard: true,
      enable_live_view: true,
      auto_refresh_interval: 30_000,
      
      # Security
      require_authentication: false,
      allowed_ips: ["127.0.0.1", "::1"],
      
      # Telemetry
      telemetry_enabled: true,
      telemetry_sample_rate: 1.0,
      
      # Themes
      theme: :default,
      custom_css: false
    """

    Igniter.Project.Config.configure(igniter, "config.exs", [:phoenix_kit], config_content)
  end

  defp generate_migration_plan(from_version, to_version) do
    [
      "Update dependency from #{from_version} to #{to_version}",
      "Remove old phoenix_kit_routes() calls",
      "Add new PhoenixKit.routes() calls",
      "Update router imports",
      "Remove PhoenixKit.welcome component usage",
      "Add new configuration options",
      "Update static assets"
    ]
  end

  defp add_change_notices(igniter, changes) do
    Enum.reduce(changes, igniter, fn change, acc ->
      Igniter.add_notice(acc, "- #{change}")
    end)
  end
end
