defmodule PhoenixKit.UtilitiesHTML do
  use Phoenix.Component
  import Phoenix.HTML

  @moduledoc """
  HTML components and templates for the PhoenixKit utilities page.
  """

  # Templates are defined as functions below

  @doc """
  Renders the utilities showcase page.
  """
  def index(assigns) do
    ~H"""
    <div class="utilities-container">
      <!-- Header -->
      <div class="page-header">
        <h1>{@title}</h1>
        <p class="page-subtitle">{@subtitle}</p>
      </div>
      
    <!-- Category Navigation -->
      <div class="category-nav">
        <%= for category <- @categories do %>
          <.category_tab category={category} />
        <% end %>
      </div>
      
    <!-- Utilities Content -->
      <div class="utilities-content">
        <%= for utility <- @utilities do %>
          <.utility_section utility={utility} />
        <% end %>
      </div>
      
    <!-- Usage Examples -->
      <div class="usage-examples">
        <h2>Complete Usage Example</h2>
        <pre><code class="language-elixir">
          # In your Phoenix application
          defmodule MyAppWeb.SomeController do
            use MyAppWeb, :controller
            import PhoenixKit.Utils

            def index(conn, params) do
              # Format dates
              formatted_date = format_date(~D[2024-01-15])
              
              # Validate email
              case validate_email(params["email"]) do
                true -> 
                  # Process valid email
                  conn |> put_flash(:info, "Email is valid!")
                false -> 
                  # Handle invalid email
                  conn |> put_flash(:error, "Invalid email format")
              end
              
              # Use cache helpers
              user_id = 123  # Example user ID
              user_data = cache_get_or_set("user:123", 3600, fn ->
                expensive_user_lookup(user_id)
              end)
              
              render(conn, :index, data: user_data)
            end
          end
        </code></pre>
      </div>
    </div>

    <script>
      // Category navigation
      document.querySelectorAll('.category-tab').forEach(tab => {
        tab.addEventListener('click', (e) => {
          const categoryName = e.target.dataset.category;
          
          // Update active tab
          document.querySelectorAll('.category-tab').forEach(t => t.classList.remove('active'));
          e.target.classList.add('active');
          
          // Show/hide utility sections
          document.querySelectorAll('.utility-section').forEach(section => {
            if (section.dataset.category === categoryName || categoryName === 'all') {
              section.style.display = 'block';
            } else {
              section.style.display = 'none';
            }
          });
        });
      });

      // Function copying
      function copyFunction(functionSignature) {
        navigator.clipboard.writeText(functionSignature)
          .then(() => {
            // Show feedback
            const button = event.target;
            const originalText = button.textContent;
            button.textContent = '✓ Copied!';
            setTimeout(() => button.textContent = originalText, 2000);
          });
      }
    </script>
    """
  end

  @doc """
  Renders a category tab.
  """
  def category_tab(assigns) do
    ~H"""
    <button class="category-tab" data-category={@category.name}>
      <span class="category-icon">{@category.icon}</span>
      <span class="category-label">{@category.label}</span>
      <small class="category-description">{@category.description}</small>
    </button>
    """
  end

  @doc """
  Renders a utility section.
  """
  def utility_section(assigns) do
    ~H"""
    <div class="utility-section" data-category={@utility.category}>
      <div class="utility-header">
        <h3>{@utility.name}</h3>
        <p>{@utility.description}</p>
      </div>

      <div class="functions-list">
        <%= for function <- @utility.functions do %>
          <.function_item function={function} />
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a function item.
  """
  def function_item(assigns) do
    ~H"""
    <div class="function-item">
      <div class="function-header">
        <h4 class="function-name">{@function.name}</h4>
        <code class="function-signature">{@function.signature}</code>
        <button
          class="btn btn-xs btn-copy"
          onclick={"copyFunction('#{@function.signature}')"}
          title="Copy function signature"
        >
          📋
        </button>
      </div>

      <p class="function-description">{@function.description}</p>

      <div class="function-example">
        <strong>Example:</strong>
        <pre><code class="language-elixir"><%= @function.example %></code></pre>
      </div>
    </div>
    """
  end
end
