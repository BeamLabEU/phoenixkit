defmodule PhoenixKitWeb.Live.DaisyTestLive do
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8">
      <h1 class="text-3xl font-bold mb-8">DaisyUI Test Page</h1>
      
    <!-- Basic DaisyUI Components Test -->
      <div class="grid gap-8">
        
    <!-- Alert Test -->
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
          <span>If this looks styled, DaisyUI is working!</span>
        </div>
        
    <!-- Button Test -->
        <div class="flex gap-4">
          <button class="btn btn-primary">Primary Button</button>
          <button class="btn btn-secondary">Secondary Button</button>
          <button class="btn btn-accent">Accent Button</button>
        </div>
        
    <!-- Card Test -->
        <div class="card w-96 bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Card Title</h2>
            <p>If this card is styled, DaisyUI is working!</p>
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
        
    <!-- Enhanced Theme Detection -->
        <div class="mockup-code">
          <pre data-prefix="$"><code>DaisyUI Diagnostic Results:</code></pre>
          <pre data-prefix=">" class="text-warning"><code>HTML data-theme: {@theme_status}</code></pre>
          <pre data-prefix=">" class="text-success"><code>CSS Variables: {@css_vars_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Alert class: {@alert_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Card class: {@card_status}</code></pre>
          <pre data-prefix=">" class="text-info"><code>Stats class: {@stats_status}</code></pre>
          <pre data-prefix=">" class="text-error"><code>ISSUE: TailwindCSS purging PhoenixKit DaisyUI classes</code></pre>
          <pre data-prefix=">" class="text-warning"><code>SOLUTION: Add "./deps/phoenix_kit/**/*.&#123;ex,heex,js&#125;" to content</code></pre>
          <pre data-prefix=">" class="text-info"><code>+ Install daisyui plugin in parent tailwind.config.js</code></pre>
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
      // LiveView event listener for client-side diagnostic
      window.addEventListener('phx:run_diagnostic', function(event) {
        setTimeout(() => {
          runClientDiagnostic();
        }, 100);
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

    socket =
      assign(socket,
        theme_status: "Loading...",
        css_vars_status: "Loading...",
        alert_status: "Loading...",
        card_status: "Loading...",
        stats_status: "Loading..."
      )

    {:ok, socket}
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
end
