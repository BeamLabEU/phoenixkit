defmodule Mix.Tasks.PhoenixKit.MigrateToDaisyui5 do
  @shortdoc "Migrates PhoenixKit installation to daisyUI 5 with Tailwind CSS 4 support"

  @moduledoc """
  Migrates existing PhoenixKit installations to support daisyUI 5 and Tailwind CSS 4.

  This task performs the following operations:

  ## Automatic Migration Steps:

  1. **Configuration Update** - Updates theme configuration to support 35+ themes
  2. **CSS Integration** - Creates modern CSS files with @plugin directives  
  3. **JavaScript Upgrade** - Installs enhanced theme-controller integration
  4. **Component Enhancement** - Updates theme_switcher with new UI
  5. **Documentation** - Generates updated setup guides

  ## Usage:

      # Basic migration (interactive)
      mix phoenix_kit.migrate_to_daisyui5
      
      # Migration with specific options
      mix phoenix_kit.migrate_to_daisyui5 --themes=synthwave,dracula,nord --auto-confirm
      
      # Preview changes without applying
      mix phoenix_kit.migrate_to_daisyui5 --dry-run

  ## Options:

    * `--themes` - Comma-separated list of themes to include (default: light,dark,synthwave,dracula,nord)
    * `--target-dir` - Target directory for generated files (default: auto-detected)
    * `--backup` - Create backup of existing files before migration (default: true)
    * `--auto-confirm` - Skip interactive confirmations
    * `--dry-run` - Preview changes without applying them
    * `--tailwind-version` - Target Tailwind CSS version (3 or 4, default: 4)
    * `--force` - Overwrite existing files without prompting

  ## Examples:

      # Migrate with popular themes
      mix phoenix_kit.migrate_to_daisyui5 --themes=light,dark,synthwave,dracula,nord,caramellatte
      
      # Corporate installation with professional themes  
      mix phoenix_kit.migrate_to_daisyui5 --themes=light,dark,corporate,business,luxury --auto-confirm
      
      # Preview migration for existing setup
      mix phoenix_kit.migrate_to_daisyui5 --dry-run

  The migration will preserve existing PhoenixKit functionality while upgrading
  to the latest daisyUI 5 features and Tailwind CSS 4 compatibility.
  """

  use Mix.Task

  alias PhoenixKit.ThemeConfig

  # All available daisyUI 5 themes
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

  # Default migration configuration
  @defaults %{
    themes: [:light, :dark, :synthwave, :dracula, :nord],
    backup: true,
    auto_confirm: false,
    dry_run: false,
    tailwind_version: 4,
    force: false
  }

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:phoenix_kit)

    config = parse_options(args)
    project_info = detect_project_info()

    Mix.shell().info([
      :green,
      "🚀 PhoenixKit daisyUI 5 Migration Tool",
      :reset,
      "\n",
      "Migrating to daisyUI 5 with ",
      :bright,
      "#{length(config.themes)} themes",
      :reset
    ])

    if config.dry_run do
      Mix.shell().info([:yellow, "DRY RUN MODE - No files will be modified", :reset])
    end

    # Validate project structure
    validate_project!(project_info)

    # Show migration plan
    show_migration_plan(config, project_info)

    # Get user confirmation unless auto-confirm
    unless config.auto_confirm or config.dry_run do
      unless Mix.shell().yes?("\nProceed with migration?") do
        Mix.shell().info("Migration cancelled.")
        exit({:shutdown, 0})
      end
    end

    # Execute migration steps
    perform_migration(config, project_info)

    Mix.shell().info([
      :green,
      "\n✅ Migration completed successfully!",
      :reset,
      "\n",
      "Run ",
      :bright,
      "`mix deps.get && mix assets.build`",
      :reset,
      " to apply changes."
    ])
  end

  # Parse command line options
  defp parse_options(args) do
    switches = [
      themes: :string,
      target_dir: :string,
      backup: :boolean,
      auto_confirm: :boolean,
      dry_run: :boolean,
      tailwind_version: :integer,
      force: :boolean
    ]

    aliases = [
      t: :themes,
      d: :target_dir,
      b: :backup,
      y: :auto_confirm,
      n: :dry_run,
      f: :force
    ]

    {opts, _args} = OptionParser.parse!(args, switches: switches, aliases: aliases)

    themes =
      case opts[:themes] do
        nil ->
          @defaults.themes

        themes_str ->
          themes_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_atom/1)
          |> Enum.filter(&(&1 in @daisyui_5_themes))
      end

    %{
      themes: themes,
      target_dir: opts[:target_dir],
      backup: Keyword.get(opts, :backup, @defaults.backup),
      auto_confirm: Keyword.get(opts, :auto_confirm, @defaults.auto_confirm),
      dry_run: Keyword.get(opts, :dry_run, @defaults.dry_run),
      tailwind_version: Keyword.get(opts, :tailwind_version, @defaults.tailwind_version),
      force: Keyword.get(opts, :force, @defaults.force)
    }
  end

  # Detect project information
  defp detect_project_info do
    project_name = Mix.Project.config()[:app]
    project_dir = File.cwd!()

    # Detect web module
    web_module =
      case File.ls(Path.join(project_dir, "lib")) do
        {:ok, files} ->
          files
          |> Enum.find(fn file ->
            String.ends_with?(file, "_web") and
              File.dir?(Path.join([project_dir, "lib", file]))
          end)

        _ ->
          nil
      end

    # Detect assets directory
    assets_dir =
      cond do
        File.dir?(Path.join(project_dir, "assets")) -> Path.join(project_dir, "assets")
        File.dir?(Path.join(project_dir, "priv/static")) -> Path.join(project_dir, "priv/static")
        true -> Path.join(project_dir, "assets")
      end

    %{
      name: project_name,
      dir: project_dir,
      web_module: web_module,
      assets_dir: assets_dir,
      has_phoenix_kit: has_phoenix_kit_dependency?(),
      existing_theme_config: detect_existing_theme_config()
    }
  end

  # Check if PhoenixKit is already installed
  defp has_phoenix_kit_dependency? do
    Mix.Project.config()[:deps]
    |> Enum.any?(fn
      {:phoenix_kit, _} -> true
      {:phoenix_kit, _, _} -> true
      _ -> false
    end)
  end

  # Detect existing theme configuration
  defp detect_existing_theme_config do
    try do
      if ThemeConfig.theme_enabled?() do
        %{
          enabled: true,
          current_themes: ThemeConfig.get_supported_themes(),
          daisyui_version: ThemeConfig.get_daisyui_version() || 4
        }
      else
        %{enabled: false}
      end
    rescue
      _ -> %{enabled: false}
    end
  end

  # Validate project structure
  defp validate_project!(project_info) do
    unless project_info.has_phoenix_kit do
      Mix.shell().error([
        :red,
        "Error: ",
        :reset,
        "PhoenixKit is not installed in this project.\n",
        "Run ",
        :bright,
        "`mix phoenix_kit.install`",
        :reset,
        " first."
      ])

      System.halt(1)
    end
  end

  # Show migration plan
  defp show_migration_plan(config, project_info) do
    Mix.shell().info([
      :cyan,
      "\n📋 Migration Plan:",
      :reset,
      "\n"
    ])

    # Current status
    current_themes = project_info.existing_theme_config[:current_themes] || []
    current_version = project_info.existing_theme_config[:daisyui_version] || 4

    Mix.shell().info([
      "📌 Current Status:\n",
      "   • daisyUI version: ",
      :bright,
      "#{current_version}",
      :reset,
      "\n",
      "   • Themes: ",
      :bright,
      "#{inspect(current_themes)}",
      :reset,
      "\n"
    ])

    # Migration targets
    Mix.shell().info([
      "🎯 Migration Targets:\n",
      "   • daisyUI version: ",
      :bright,
      "5",
      :reset,
      "\n",
      "   • Tailwind CSS: ",
      :bright,
      "#{config.tailwind_version}",
      :reset,
      "\n",
      "   • Themes: ",
      :bright,
      "#{inspect(config.themes)}",
      :reset,
      "\n",
      "   • New themes: ",
      :green,
      "#{length(config.themes) - length(current_themes)} themes",
      :reset,
      "\n"
    ])

    # Migration steps
    Mix.shell().info([
      "🔄 Migration Steps:\n",
      "   1. Update theme configuration\n",
      "   2. Generate modern CSS files with @plugin directives\n",
      "   3. Install enhanced JavaScript integration\n",
      "   4. Update theme_switcher component\n",
      "   5. Create configuration examples\n",
      "   6. Generate migration documentation\n"
    ])

    if config.backup do
      Mix.shell().info([
        "💾 Backup: ",
        :green,
        "Enabled",
        :reset,
        " (original files will be backed up)\n"
      ])
    end
  end

  # Perform the actual migration
  defp perform_migration(config, project_info) do
    steps = [
      {"Backing up existing files", &backup_existing_files/2},
      {"Updating theme configuration", &update_theme_config/2},
      {"Generating CSS files", &generate_css_files/2},
      {"Installing JavaScript files", &install_javascript_files/2},
      {"Creating configuration examples", &create_config_examples/2},
      {"Updating component integration", &update_component_integration/2},
      {"Generating documentation", &generate_documentation/2}
    ]

    total_steps = length(steps)

    Enum.with_index(steps, 1)
    |> Enum.each(fn {{description, step_fn}, index} ->
      Mix.shell().info([
        :cyan,
        "[#{index}/#{total_steps}] ",
        :reset,
        description,
        "..."
      ])

      unless config.dry_run do
        step_fn.(config, project_info)
      else
        Mix.shell().info([:yellow, "   (dry run - skipped)", :reset])
      end
    end)
  end

  # Backup existing files
  defp backup_existing_files(config, project_info) do
    return_if_dry_run(config)

    if config.backup do
      backup_dir = Path.join(project_info.dir, "phoenix_kit_backup_#{timestamp()}")
      File.mkdir_p!(backup_dir)

      # Backup theme-related files
      files_to_backup = [
        "config/config.exs",
        "lib/#{project_info.web_module}/components/core_components.ex",
        Path.join(project_info.assets_dir, "tailwind.config.js"),
        Path.join(project_info.assets_dir, "css/app.css")
      ]

      files_to_backup
      |> Enum.filter(&File.exists?/1)
      |> Enum.each(fn file ->
        backup_file = Path.join(backup_dir, Path.basename(file))
        File.cp!(file, backup_file)
      end)

      Mix.shell().info([
        :green,
        "   ✓ Backup created: ",
        :reset,
        backup_dir
      ])
    end
  end

  # Update theme configuration in config/config.exs
  defp update_theme_config(config, project_info) do
    return_if_dry_run(config)

    config_file = Path.join(project_info.dir, "config/config.exs")

    updated_config = """

    # PhoenixKit daisyUI 5 Theme Configuration (Auto-generated by migration)
    config :phoenix_kit,
      theme_enabled: true,
      theme: %{
        mode: :auto,                              # :light, :dark, :auto, or any daisyUI theme
        primary_color: "oklch(55% 0.3 240)",     # Modern OKLCH color format
        themes: #{inspect(config.themes)},        # Selected daisyUI 5 themes (#{length(config.themes)} total)
        storage: :local_storage,                  # :local_storage, :session, :cookie
        daisyui_version: 5,                      # daisyUI version
        theme_controller: true,                   # Enable built-in theme-controller
        oklch_colors: %{                         # Modern OKLCH color definitions
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
    """

    # Append to config file if PhoenixKit config doesn't exist
    if File.exists?(config_file) do
      content = File.read!(config_file)

      unless String.contains?(content, ":phoenix_kit") do
        File.write!(config_file, content <> updated_config)
      end
    end

    Mix.shell().info([
      :green,
      "   ✓ Theme configuration updated with ",
      :reset,
      "#{length(config.themes)} themes"
    ])
  end

  # Generate CSS files with daisyUI 5 integration
  defp generate_css_files(config, project_info) do
    return_if_dry_run(config)

    css_dir = Path.join(project_info.assets_dir, "css")
    File.mkdir_p!(css_dir)

    # Generate Tailwind CSS 4 configuration
    if config.tailwind_version == 4 do
      generate_tailwind_css4_config(config, css_dir)
    else
      generate_tailwind_css3_config(config, project_info.assets_dir)
    end

    Mix.shell().info([
      :green,
      "   ✓ CSS configuration generated for Tailwind CSS ",
      :reset,
      "#{config.tailwind_version}"
    ])
  end

  # Generate Tailwind CSS 4 configuration
  defp generate_tailwind_css4_config(config, css_dir) do
    theme_list =
      config.themes
      |> Enum.map(&to_string/1)
      |> Enum.map_join(", ", fn
        "light" -> "light --default"
        "dark" -> "dark --prefersdark"
        theme -> theme
      end)

    css_content = """
    /* Phoenix Kit daisyUI 5 Integration (Auto-generated) */
    @import "tailwindcss";

    /* Configure source paths for content scanning */
    @source "./lib/**/*.{ex,heex,js}";
    @source "./assets/**/*.js";
    @source "./lib/*_web/phoenix_kit_live/**/*.{ex,heex}";

    /* daisyUI 5 Plugin Configuration */
    @plugin "daisyui" {
      themes: #{theme_list};
      root: ":root";
      logs: true;
    }

    /* Import PhoenixKit daisyUI 5 enhancements */
    @import "./phoenix_kit_daisyui5.css";
    """

    File.write!(Path.join(css_dir, "phoenix_kit_themes.css"), css_content)

    # Copy enhanced CSS file
    source_css = Application.app_dir(:phoenix_kit, "priv/static/assets/phoenix_kit_daisyui5.css")
    target_css = Path.join(css_dir, "phoenix_kit_daisyui5.css")
    File.cp!(source_css, target_css)
  end

  # Generate Tailwind CSS 3 configuration
  defp generate_tailwind_css3_config(config, assets_dir) do
    config_content = """
    /** 
     * Tailwind CSS 3 + daisyUI 5 Configuration (Auto-generated)
     * Generated by PhoenixKit migration tool
     */
    module.exports = {
      content: [
        "./js/**/*.js",
        "./lib/**/*.{ex,heex,js}",
        "./assets/**/*.js",
        "./lib/*_web/phoenix_kit_live/**/*.{ex,heex}"
      ],
      
      plugins: [
        require("daisyui")
      ],
      
      daisyui: {
        themes: #{inspect(Enum.map(config.themes, &to_string/1))},
        darkTheme: "dark",
        base: true,
        styled: true,
        utils: true,
        logs: true,
        themeRoot: ":root"
      }
    };
    """

    File.write!(Path.join(assets_dir, "tailwind.config.js"), config_content)
  end

  # Install JavaScript files
  defp install_javascript_files(config, project_info) do
    return_if_dry_run(config)

    js_dir = Path.join(project_info.assets_dir, "js")
    File.mkdir_p!(js_dir)

    # Copy enhanced JavaScript file
    source_js = Application.app_dir(:phoenix_kit, "priv/static/assets/phoenix_kit_daisyui5.js")
    target_js = Path.join(js_dir, "phoenix_kit_themes.js")
    File.cp!(source_js, target_js)

    # Update app.js to include the new theme system
    app_js_path = Path.join(js_dir, "app.js")

    if File.exists?(app_js_path) do
      content = File.read!(app_js_path)

      unless String.contains?(content, "phoenix_kit_themes") do
        updated_content =
          content <>
            "\n\n// PhoenixKit daisyUI 5 Theme System\nimport \"./phoenix_kit_themes.js\";\n"

        File.write!(app_js_path, updated_content)
      end
    end

    Mix.shell().info([
      :green,
      "   ✓ JavaScript files installed with theme-controller integration"
    ])
  end

  # Create configuration examples
  defp create_config_examples(config, project_info) do
    return_if_dry_run(config)

    examples_dir = Path.join(project_info.dir, "phoenix_kit_examples")
    File.mkdir_p!(examples_dir)

    # Copy example files
    example_files = [
      {"tailwind_config_daisyui5.js", "tailwind.config.daisyui5.example.js"},
      {"tailwind_css4_config.css", "tailwind_css4.example.css"}
    ]

    example_files
    |> Enum.each(fn {source_name, target_name} ->
      source_path = Application.app_dir(:phoenix_kit, "priv/static/examples/#{source_name}")
      target_path = Path.join(examples_dir, target_name)

      if File.exists?(source_path) do
        File.cp!(source_path, target_path)
      end
    end)

    Mix.shell().info([
      :green,
      "   ✓ Configuration examples created in ",
      :reset,
      examples_dir
    ])
  end

  # Update component integration
  defp update_component_integration(config, project_info) do
    return_if_dry_run(config)

    # Create integration helper file
    if project_info.web_module do
      integration_dir =
        Path.join([project_info.dir, "lib", project_info.web_module, "components"])

      File.mkdir_p!(integration_dir)

      integration_content = """
      defmodule #{Macro.camelize(project_info.web_module)}.PhoenixKitIntegration do
        @moduledoc \"\"\"
        PhoenixKit daisyUI 5 integration helpers.
        
        This module provides helper functions for integrating PhoenixKit theme system
        with your Phoenix application components.
        \"\"\"
        
        import Phoenix.Component
        alias PhoenixKit.ThemeConfig
        
        @doc \"\"\"
        Renders a theme-aware component wrapper.
        \"\"\"
        def theme_wrapper(assigns) do
          ~H\"\"\"
          <div class="phoenix-kit-theme-wrapper" data-theme={current_theme()}>
            <%%= render_slot(@inner_block) %>
          </div>
          \"\"\"
        end
        
        @doc \"\"\"
        Get current theme for use in components.
        \"\"\"
        def current_theme do
          if ThemeConfig.theme_enabled?() do
            ThemeConfig.daisy_theme_name(ThemeConfig.get_theme_mode())
          else
            "light"
          end
        end
        
        @doc \"\"\"
        Get all configured themes.
        \"\"\"
        def available_themes do
          if ThemeConfig.theme_enabled?() do
            ThemeConfig.get_supported_themes()
          else
            [:light, :dark]
          end
        end
      end
      """

      File.write!(Path.join(integration_dir, "phoenix_kit_integration.ex"), integration_content)
    end

    Mix.shell().info([
      :green,
      "   ✓ Component integration helpers created"
    ])
  end

  # Generate migration documentation
  defp generate_documentation(config, project_info) do
    return_if_dry_run(config)

    docs_dir = Path.join(project_info.dir, "phoenix_kit_docs")
    File.mkdir_p!(docs_dir)

    migration_doc = """
    # PhoenixKit daisyUI 5 Migration - #{timestamp_readable()}

    This document describes the migration performed on your PhoenixKit installation.

    ## Migration Summary

    - **From**: daisyUI 4.x → **To**: daisyUI 5.x
    - **Tailwind CSS**: Version #{config.tailwind_version}
    - **Themes**: #{length(config.themes)} themes configured
    - **Project**: #{project_info.name}

    ## Configured Themes

    #{config.themes |> Enum.map(&"- `#{&1}`") |> Enum.join("\n")}

    ## Files Modified/Created

    ### Configuration
    - `config/config.exs` - Updated theme configuration
    - `phoenix_kit_examples/` - Configuration examples

    ### Assets
    - `assets/css/phoenix_kit_themes.css` - Modern CSS configuration  
    - `assets/js/phoenix_kit_themes.js` - Enhanced JavaScript integration

    ### Components
    - `lib/#{project_info.web_module}/components/phoenix_kit_integration.ex` - Integration helpers

    ## Next Steps

    1. **Install Dependencies**:
       ```bash
       mix deps.get
       npm install daisyui@^5.0.0  # If using npm
       ```

    2. **Build Assets**:
       ```bash
       mix assets.build
       ```

    3. **Test Integration**:
       - Visit `/phoenix_kit/daisy-test` to verify theme system
       - Test theme switching functionality
       - Verify all #{length(config.themes)} themes work correctly

    4. **Customize Configuration**:
       - Edit `config/config.exs` to adjust theme selection
       - Review examples in `phoenix_kit_examples/`
       - Customize OKLCH colors as needed

    ## Theme Controller Usage

    The migration enables daisyUI 5's built-in theme-controller system:

    ```heex
    <!-- Radio button theme switcher -->
    <input type="radio" name="theme" class="theme-controller" value="synthwave" />

    <!-- Checkbox theme toggle -->
    <input type="checkbox" class="toggle theme-controller" value="dark" />

    <!-- Enhanced PhoenixKit theme switcher -->
    <.theme_switcher />
    ```

    ## Troubleshooting

    If you encounter issues:

    1. Check that daisyUI 5 is installed: `npm list daisyui`
    2. Verify theme configuration in `config/config.exs`
    3. Run diagnostic: Visit `/phoenix_kit/daisy-test`
    4. Check browser console for JavaScript errors

    ## Support

    For additional help:
    - Review PhoenixKit documentation
    - Check daisyUI 5 migration guide
    - Open GitHub issues for bugs

    ---
    *Migration completed at #{DateTime.utc_now()}*
    """

    File.write!(Path.join(docs_dir, "MIGRATION.md"), migration_doc)

    Mix.shell().info([
      :green,
      "   ✓ Migration documentation created in ",
      :reset,
      docs_dir
    ])
  end

  # Helper functions
  defp return_if_dry_run(%{dry_run: true}), do: :ok
  defp return_if_dry_run(_), do: nil

  defp timestamp do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> to_string()
  end

  defp timestamp_readable do
    DateTime.utc_now()
    |> DateTime.to_string()
  end
end
