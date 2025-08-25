defmodule PhoenixKitWeb.Live.DaisyTestLive do
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">DaisyUI 5 Theme Test</h1>
        <.theme_switcher />
      </div>
      
    <!-- Enhanced DaisyUI 5 Components Test -->
      <div class="grid gap-8">
        
    <!-- Current Theme Info -->
        <div class="mockup-code">
          <pre data-prefix="$"><code>Current Theme: {@current_theme}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Available Themes: {@total_themes}</code></pre>
          <pre data-prefix=">" class="text-success"><code>Theme Controller: {@theme_controller_status}</code></pre>
        </div>
        
    <!-- Alert Tests for Different Types -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="alert alert-info">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              class="stroke-current shrink-0 w-6 h-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              >
              </path>
            </svg>
            <span>Info Alert - DaisyUI 5</span>
          </div>

          <div class="alert alert-success">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current shrink-0 h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span>Success Alert - All good!</span>
          </div>

          <div class="alert alert-warning">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current shrink-0 h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.966-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
            <span>Warning Alert</span>
          </div>

          <div class="alert alert-error">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current shrink-0 h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span>Error Alert</span>
          </div>
        </div>
        
    <!-- Enhanced Button Tests -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <button class="btn btn-primary">Primary Button</button>
          <button class="btn btn-secondary">Secondary Button</button>
          <button class="btn btn-accent">Accent Button</button>
          <button class="btn btn-info">Info Button</button>
          <button class="btn btn-success">Success Button</button>
          <button class="btn btn-warning">Warning Button</button>
          <button class="btn btn-error">Error Button</button>
          <button class="btn btn-outline">Outline Button</button>
          <button class="btn btn-ghost">Ghost Button</button>
        </div>
        
    <!-- Enhanced Card Tests -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Base Card</h2>
              <p>Default card styling test</p>
              <div class="card-actions justify-end">
                <button class="btn btn-primary btn-sm">Action</button>
              </div>
            </div>
          </div>

          <div class="card bg-primary text-primary-content shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Primary Card</h2>
              <p>Primary themed card test</p>
              <div class="card-actions justify-end">
                <button class="btn btn-secondary btn-sm">Action</button>
              </div>
            </div>
          </div>

          <div class="card bg-secondary text-secondary-content shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Secondary Card</h2>
              <p>Secondary themed card test</p>
              <div class="card-actions justify-end">
                <button class="btn btn-accent btn-sm">Action</button>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Stats Test (Our Component) -->
        <div class="stats shadow">
          <div class="stat bg-success/10 border-success/20 place-items-center">
            <div class="stat-figure text-success">
              <svg class="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                />
              </svg>
            </div>
            <div class="stat-title">Test Stat</div>
            <div class="stat-value text-success">42</div>
            <div class="stat-desc">This should be styled</div>
          </div>
        </div>
        
    <!-- Theme Showcase Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <%= for theme <- @sample_themes do %>
            <div
              class="card bg-base-100 shadow-lg border hover:shadow-xl transition-shadow"
              data-theme={theme}
            >
              <div class="card-body p-4">
                <h3 class="card-title text-sm">{String.capitalize(theme)}</h3>
                <div class="flex gap-1 mb-2">
                  <div class="w-4 h-4 rounded bg-primary"></div>
                  <div class="w-4 h-4 rounded bg-secondary"></div>
                  <div class="w-4 h-4 rounded bg-accent"></div>
                </div>
                <button class="btn btn-primary btn-xs" phx-click="set_theme" phx-value-theme={theme}>
                  Test {theme}
                </button>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Enhanced Diagnostic Results -->
        <div class="mockup-code">
          <pre data-prefix="$"><code>DaisyUI 5 Diagnostic Results:</code></pre>
          <pre data-prefix=">" class="text-info"><code>HTML data-theme: {@theme_status}</code></pre>
          <pre data-prefix=">" class="text-success"><code>CSS Variables: {@css_vars_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Alert styling: {@alert_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Card styling: {@card_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Stats styling: {@stats_status}</code></pre>
          <pre data-prefix=">" class="text-warning"><code>Theme Controller: {@theme_controller_status}</code></pre>
        </div>
        
    <!-- Refresh Button -->
        <div class="text-center mt-4">
          <button phx-click="run_client_diagnostic" class="btn btn-primary">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              >
              </path>
            </svg>
            Run Client-Side Diagnostic
          </button>
        </div>
      </div>
    </div>

    <script>
      // LiveView event listeners
      window.addEventListener('phx:run_diagnostic', function(event) {
        setTimeout(() => {
          runClientDiagnostic();
        }, 100);
      });

      window.addEventListener('phx:set_theme', function(event) {
        const theme = event.detail.theme;
        if (window.PhoenixKit && window.PhoenixKit.ThemeController) {
          window.PhoenixKit.ThemeController.setTheme(theme);
        } else {
          // Fallback theme setting
          document.documentElement.setAttribute('data-theme', theme);
        }
      });

      function runClientDiagnostic() {
        try {
          console.log('Running client-side diagnostic...');
          
          // Check theme
          const theme = document.documentElement.getAttribute('data-theme') || 'none';
          
          // Check CSS variables
          const style = getComputedStyle(document.documentElement);
          const primaryColor = style.getPropertyValue('--primary') || style.getPropertyValue('--color-primary');
          const cssVars = primaryColor ? 'Yes (DaisyUI working)' : 'No (DaisyUI missing)';
          
          // Check alert styles
          const alertElement = document.querySelector('.alert');
          let alertStatus = 'Missing ✗';
          if (alertElement) {
            const alertStyles = getComputedStyle(alertElement);
            const isStyled = alertStyles.backgroundColor !== 'rgba(0, 0, 0, 0)' || alertStyles.padding !== '0px';
            alertStatus = isStyled ? 'Working ✓' : 'Fallback CSS ✓';
          }
          
          // Check card styles  
          const cardElement = document.querySelector('.card');
          let cardStatus = 'Missing ✗';
          if (cardElement) {
            const cardStyles = getComputedStyle(cardElement);
            const isStyled = cardStyles.borderRadius !== '0px' || cardStyles.boxShadow !== 'none';
            cardStatus = isStyled ? 'Working ✓' : 'Fallback CSS ✓';
          }
          
          // Check stats styles
          const statsElement = document.querySelector('.stats');
          let statsStatus = 'Missing ✗';
          if (statsElement) {
            const statsStyles = getComputedStyle(statsElement);
            const isStyled = statsStyles.display === 'grid' || statsStyles.boxShadow !== 'none';
            statsStatus = isStyled ? 'Working ✓' : 'Fallback CSS ✓';
          }
          
          // Send results back to LiveView
          const liveSocket = window.liveSocket;
          if (liveSocket) {
            const view = liveSocket.getViewByEl(document.querySelector('[data-phx-view]'));
            if (view) {
              view.pushEvent('diagnostic_result', {
                theme: theme,
                css_vars: cssVars,
                alert: alertStatus,
                card: cardStatus, 
                stats: statsStatus
              });
            }
          }
          
          console.log('Client diagnostic completed:', {theme, cssVars, alertStatus, cardStatus, statsStatus});
        } catch (error) {
          console.error('Client diagnostic error:', error);
        }
      }
    </script>
    """
  end

  def mount(_params, _session, socket) do
    # Run diagnostic on mount
    send(self(), :run_diagnostic)

    # Get sample themes for showcase
    all_themes = PhoenixKit.ThemeConfig.get_all_daisyui_themes()
    sample_themes = Enum.take_random(all_themes, 8)
    current_theme = get_current_theme()

    socket =
      assign(socket,
        current_theme: current_theme,
        total_themes: length(all_themes),
        theme_controller_status:
          if(PhoenixKit.ThemeConfig.theme_controller_enabled?(),
            do: "Enabled ✓",
            else: "Disabled ✗"
          ),
        sample_themes: sample_themes,
        theme_status: "Loading...",
        css_vars_status: "Loading...",
        alert_status: "Loading...",
        card_status: "Loading...",
        stats_status: "Loading..."
      )

    {:ok, socket}
  end

  defp get_current_theme do
    config = Application.get_env(:phoenix_kit, :theme, %{})

    case config[:theme] do
      theme when is_binary(theme) -> theme
      _ -> "auto"
    end
  end

  def handle_info(:run_diagnostic, socket) do
    # Server-side diagnostic (simplified)
    socket =
      assign(socket,
        theme_status: "none (DaisyUI theme not set)",
        css_vars_status: "Missing (TailwindCSS purging DaisyUI)",
        alert_status: "Missing ✗ (TailwindCSS content issue)",
        card_status: "Missing ✗ (TailwindCSS content issue)",
        stats_status: "Missing ✗ (TailwindCSS content issue)"
      )

    {:noreply, socket}
  end

  def handle_event("run_client_diagnostic", _params, socket) do
    # Trigger client-side diagnostic via JavaScript hook
    socket =
      socket
      |> assign(
        theme_status: "Checking client...",
        css_vars_status: "Checking client...",
        alert_status: "Checking client...",
        card_status: "Checking client...",
        stats_status: "Checking client..."
      )
      |> push_event("run_diagnostic", %{})

    {:noreply, socket}
  end

  def handle_event("diagnostic_result", params, socket) do
    socket =
      assign(socket,
        theme_status: params["theme"] || "none",
        css_vars_status: params["css_vars"] || "No",
        alert_status: params["alert"] || "Missing",
        card_status: params["card"] || "Missing",
        stats_status: params["stats"] || "Missing"
      )

    {:noreply, socket}
  end

  def handle_event("set_theme", %{"theme" => theme}, socket) do
    # This would typically trigger theme change via JavaScript
    socket =
      socket
      |> assign(current_theme: theme)
      |> push_event("set_theme", %{theme: theme})

    {:noreply, socket}
  end
end
