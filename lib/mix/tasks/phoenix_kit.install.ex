defmodule Mix.Tasks.PhoenixKit.Install do
  @moduledoc """
  Install PhoenixKit into a Phoenix application.

  This task automatically configures your Phoenix application to use PhoenixKit by:

  1. Adding PhoenixKit routes to your router
  2. Copying static assets to your priv/static directory
  3. Adding configuration to your config files
  4. Installing required dependencies

  ## Usage

      mix igniter.install phoenix_kit

  ## Options

    * `--no-routes` - Skip adding PhoenixKit routes to the router
    * `--no-assets` - Skip copying static assets
    * `--no-config` - Skip adding configuration
    * `--scope` - Custom scope for PhoenixKit routes (default: "/phoenix_kit")

  ## Examples

      # Standard installation
      mix igniter.install phoenix_kit

      # Install without routes
      mix igniter.install phoenix_kit --no-routes

      # Install with custom scope
      mix igniter.install phoenix_kit --scope "/admin/phoenix_kit"

  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :phoenix_kit,
      example: "mix igniter.install phoenix_kit",
      positional: [],
      schema: [
        routes: :boolean,
        assets: :boolean,
        config: :boolean,
        scope: :string
      ],
      defaults: [
        routes: true,
        assets: true,
        config: true,
        scope: "/phoenix_kit"
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter, argv) do
    options = info(argv, nil)

    igniter
    |> add_dependency()
    |> maybe_add_routes(options)
    |> maybe_copy_assets(options)
    |> maybe_add_config(options)
    |> add_router_import()
    |> Igniter.add_notice("PhoenixKit installed successfully!")
    |> Igniter.add_notice(
      "Visit http://localhost:4000#{options.defaults[:scope]} to see PhoenixKit in action"
    )
  end

  defp add_dependency(igniter) do
    Igniter.Project.Deps.add_dependency(igniter, {:phoenix_kit, "~> 0.3.0"})
  end

  defp maybe_add_routes(igniter, %{schema: schema}) do
    if Keyword.get(schema, :routes, true) do
      add_routes(igniter, Keyword.get(schema, :scope, "/phoenix_kit"))
    else
      igniter
    end
  end

  defp add_routes(igniter, scope) do
    code_to_add = """
    # PhoenixKit routes
    scope "#{scope}" do
      pipe_through :browser
      PhoenixKit.routes()
    end
    """

    Igniter.Code.Module.find_and_update_module!(
      igniter,
      [Mix.Project.config()[:app], :router],
      fn zipper ->
        # Find the router module and add the routes
        with {:ok, zipper} <- Igniter.Code.Module.move_to_module_using(zipper, Phoenix.Router),
             {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
          # Add the routes to the end of the router
          Igniter.Code.Common.add_code(zipper, code_to_add)
        else
          _ -> {:error, "Could not find router module"}
        end
      end
    )
  end

  defp add_router_import(igniter) do
    router_module =
      Module.concat([
        Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize(),
        "Web",
        "Router"
      ])

    Igniter.Code.Module.find_and_update_module!(igniter, router_module, fn zipper ->
      # Add import PhoenixKit to the router
      Igniter.Code.Common.add_code(zipper, "import PhoenixKit", :beginning)
    end)
  end

  defp maybe_copy_assets(igniter, %{schema: schema}) do
    if Keyword.get(schema, :assets, true) do
      copy_assets(igniter)
    else
      igniter
    end
  end

  defp copy_assets(igniter) do
    # Copy CSS and JS assets
    css_content = """
    /* PhoenixKit Styles */
    .phoenix-kit-container {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6;
    }

    .phoenix-kit-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 2rem;
      text-align: center;
    }

    .phoenix-kit-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
      margin: 2rem 0;
    }

    .phoenix-kit-stat {
      background: white;
      padding: 1.5rem;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      text-align: center;
    }

    .phoenix-kit-stat h3 {
      margin: 0 0 0.5rem 0;
      color: #333;
    }

    .phoenix-kit-stat p {
      margin: 0;
      font-size: 2rem;
      font-weight: bold;
      color: #667eea;
    }

    .phoenix-kit-nav {
      display: flex;
      gap: 1rem;
      justify-content: center;
      margin: 2rem 0;
    }

    .phoenix-kit-nav a {
      background: #667eea;
      color: white;
      padding: 0.75rem 1.5rem;
      text-decoration: none;
      border-radius: 4px;
      transition: background 0.3s;
    }

    .phoenix-kit-nav a:hover {
      background: #764ba2;
    }

    .phoenix-kit-card {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      margin: 1rem 0;
    }

    .phoenix-kit-footer {
      text-align: center;
      padding: 2rem;
      color: #666;
      border-top: 1px solid #eee;
      margin-top: 3rem;
    }
    """

    js_content = """
    // PhoenixKit JavaScript
    document.addEventListener('DOMContentLoaded', function() {
      // Auto-refresh functionality for live pages
      const refreshInterval = 5000; // 5 seconds
      
      if (window.location.pathname.includes('/phoenix_kit/live')) {
        setInterval(function() {
          if (window.liveSocket && window.liveSocket.isConnected()) {
            // Phoenix LiveView handles auto-refresh
            console.log('PhoenixKit: LiveView auto-refresh active');
          }
        }, refreshInterval);
      }
      
      // Add smooth scrolling to navigation links
      document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
          e.preventDefault();
          document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
          });
        });
      });
      
      // Add loading states to buttons
      document.querySelectorAll('.phoenix-kit-btn').forEach(button => {
        button.addEventListener('click', function() {
          this.classList.add('loading');
          setTimeout(() => {
            this.classList.remove('loading');
          }, 2000);
        });
      });
    });
    """

    igniter
    |> Igniter.create_new_file("priv/static/phoenix_kit/phoenix_kit.css", css_content)
    |> Igniter.create_new_file("priv/static/phoenix_kit/phoenix_kit.js", js_content)
  end

  defp maybe_add_config(igniter, %{schema: schema}) do
    if Keyword.get(schema, :config, true) do
      add_config(igniter)
    else
      igniter
    end
  end

  defp add_config(igniter) do
    config_content = """
    # PhoenixKit Configuration
    config :phoenix_kit, PhoenixKit,
      # Basic settings
      enable_dashboard: true,
      enable_live_view: true,
      auto_refresh_interval: 30_000,
      
      # Security (set to true in production)
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
end
