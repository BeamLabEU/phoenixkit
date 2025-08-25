if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.PhoenixKit.Install do
    @moduledoc """
    Igniter installer for PhoenixKit authentication system.

    This task automatically installs PhoenixKit into a Phoenix application by:
    1. Auto-detecting and configuring Ecto repo
    2. Setting up mailer configuration for development and production
    3. Modifying the router to include PhoenixKit routes

    ## Usage

    ```bash
    mix phoenix_kit.install
    ```

    With custom options:

    ```bash
    mix phoenix_kit.install --repo MyApp.Repo --router-path lib/my_app_web/router.ex
    ```

    ## Options

    * `--repo` - Specify Ecto repo module (auto-detected if not provided)
    * `--router-path` - Specify custom path to router.ex file
    * `--prefix` - Specify PostgreSQL schema prefix (defaults to "public")
    * `--create-schema` - Create schema if using custom prefix (default: true for non-public prefixes)
    * `--theme-enabled` - Enable modern daisyUI 5 + Tailwind CSS 4 theme system with 35+ themes

    ## Auto-detection

    The installer will automatically:
    - Detect Ecto repo from `:ecto_repos` config or common naming patterns (MyApp.Repo)
    - Find main router using Phoenix conventions (MyAppWeb.Router)
    - Configure Swoosh.Adapters.Local for development in config/dev.exs
    - Provide production mailer setup instructions

    ## Note about warnings

    You may see a compiler warning about "unused import PhoenixKitWeb.Integration".
    This is normal behavior for Elixir macros and can be safely ignored.
    The `phoenix_kit_routes()` macro is properly used and will expand correctly.
    """

    @shortdoc "Install PhoenixKit authentication system into a Phoenix application"

    use Igniter.Mix.Task

    alias PhoenixKit.Install.{
      DemoFiles,
      LayoutConfig,
      MailerConfig,
      MigrationStrategy,
      RepoDetection,
      RouterIntegration
    }

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_kit,
        example: "mix phoenix_kit.install --repo MyApp.Repo --prefix auth",
        positional: [],
        schema: [
          router_path: :string,
          repo: :string,
          prefix: :string,
          create_schema: :boolean,
          theme_enabled: :boolean
        ],
        aliases: [
          r: :router_path,
          repo: :repo,
          p: :prefix
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options

      igniter
      |> RepoDetection.add_phoenix_kit_configuration(opts[:repo])
      |> MailerConfig.add_mailer_configuration()
      |> LayoutConfig.add_layout_integration_configuration()
      |> add_theme_configuration(Keyword.get(opts, :theme_enabled, true))
      |> DemoFiles.copy_test_demo_files()
      |> RouterIntegration.add_router_integration(opts[:router_path])
      |> MigrationStrategy.create_phoenix_kit_migration_only(opts)
      |> add_completion_notice()
    end

    # Override run/1 to handle post-igniter interactive migration
    def run(argv) do
      # Store options in process dictionary for later use
      opts =
        OptionParser.parse(argv,
          switches: [
            router_path: :string,
            repo: :string,
            prefix: :string,
            create_schema: :boolean,
            theme_enabled: :boolean
          ],
          aliases: [
            r: :router_path,
            repo: :repo,
            p: :prefix
          ]
        )

      Process.put(:phoenix_kit_install_opts, elem(opts, 1))

      # Run standard igniter process
      result = super(argv)

      # After igniter is done, handle interactive migration
      MigrationStrategy.handle_interactive_migration_after_config(elem(opts, 1))

      result
    end

    # Add modern daisyUI 5 + Tailwind CSS 4 theme configuration
    defp add_theme_configuration(igniter, theme_enabled) when theme_enabled do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :phoenix_kit,
        [theme_enabled: true, theme: %{
          theme: "auto",
          primary_color: "oklch(55% 0.3 240)", 
          storage: :local_storage,
          themes: [:light, :dark, :synthwave, :dracula, :nord]
        }],
        updater: fn zipper ->
          {:ok, zipper}
        end
      )
      |> create_tailwind_css4_example()
      |> Igniter.add_notice("""
      
      🎨 Modern Theme System Enabled!
      
      IMPORTANT: PhoenixKit now requires Tailwind CSS 4 + daisyUI 5
      
      📁 Example configuration created: assets/phoenix_kit_app_css_example.css
      
      Copy content to your app.css:
      ```bash
      cp assets/phoenix_kit_app_css_example.css assets/css/app.css
      ```
      
      Or manually add to your app.css:
      ```css
      @import "tailwindcss";
      @source "./lib/**/*.{ex,heex,js}";
      @source "./deps/phoenix_kit/**/*.{ex,heex}";
      @plugin "daisyui" { themes: light --default, dark --prefersdark, synthwave; };
      ```
      """)
    end
    
    defp add_theme_configuration(igniter, _), do: igniter

    # Create Tailwind CSS 4 example file for easy integration
    defp create_tailwind_css4_example(igniter) do
      example_content = """
      /**
       * PhoenixKit + Tailwind CSS 4 + daisyUI 5 Integration Example
       * 
       * Copy this content to your assets/css/app.css file to enable
       * the modern PhoenixKit theme system with 35+ daisyUI themes.
       * 
       * Requirements: Tailwind CSS 4 + daisyUI 5
       */

      /* Import Tailwind CSS 4 */
      @import "tailwindcss";

      /* Content sources for Tailwind to scan */
      @source "./lib/**/*.{ex,heex,js}";
      @source "./assets/**/*.js";
      @source "./deps/phoenix_kit/**/*.{ex,heex}";

      /* daisyUI 5 plugin with theme selection */
      @plugin "daisyui" {
        themes: 
          light --default,
          dark --prefersdark,
          synthwave,
          dracula,
          nord,
          corporate,
          luxury,
          forest;
      };

      /* Additional custom styles (optional) */
      @layer components {
        .phoenix-kit-theme-example {
          @apply bg-primary text-primary-content p-4 rounded-lg;
        }
      }
      """
      
      Igniter.create_new_file(igniter, "assets/phoenix_kit_app_css_example.css", example_content)
    end

    # Add completion notice with essential next steps
    defp add_completion_notice(igniter) do
      notice = """

      🎉 PhoenixKit installation complete!

      Next steps:
        1. Run: mix ecto.migrate
        2. Update app.css for Tailwind CSS 4 + daisyUI 5 (see theme notice above)
        3. Start server: mix phx.server
        4. Visit /phoenix_kit/register
        5. Test theme system: /phoenix_kit/daisy-test
        6. Test demo pages: /test-current-user, /test-redirect-if-auth, /test-ensure-auth

      📚 Documentation:
        - Theme setup: /deps/phoenix_kit/priv/static/examples/
        - Migration guide: /deps/phoenix_kit/priv/static/examples/DAISYUI_5_MIGRATION_GUIDE.md

      💡 Layout changes require: mix deps.compile phoenix_kit --force
      """

      Igniter.add_notice(igniter, notice)
    end
  end

  # Fallback module for when Igniter is not available
else
  defmodule Mix.Tasks.PhoenixKit.Install do
    @moduledoc """
    PhoenixKit installation task.

    This task requires the Igniter library to be available. Please add it to your mix.exs:

        {:igniter, "~> 0.6.27"}

    Then run: mix deps.get
    """

    @shortdoc "Install PhoenixKit authentication system (requires Igniter)"

    use Mix.Task

    def run(_args) do
      Mix.shell().error("""

      ❌ PhoenixKit installation requires the Igniter library.

      Please add Igniter to your mix.exs dependencies:

          def deps do
            [
              {:igniter, "~> 0.6.27"}
              # ... your other dependencies
            ]
          end

      Then run:
        mix deps.get
        mix phoenix_kit.install

      For more information, visit: https://hex.pm/packages/igniter
      """)
    end
  end
end
