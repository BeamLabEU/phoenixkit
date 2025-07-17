defmodule PhoenixKit.ComponentsHTML do
  use Phoenix.Component
  import Phoenix.HTML

  @moduledoc """
  HTML components and templates for the PhoenixKit components showcase.
  """

  # Templates are defined as functions below

  @doc """
  Renders the components showcase page.
  """
  def index(assigns) do
    ~H"""
    <div class="components-container">
      <!-- Header -->
      <div class="page-header">
        <h1>{@title}</h1>
        <p class="page-subtitle">{@subtitle}</p>
      </div>
      
    <!-- Category Filter -->
      <div class="category-filter">
        <button class="category-btn active" data-category="all">All Components</button>
        <%= for category <- @categories do %>
          <button class="category-btn" data-category={category.name}>
            {category.icon} {category.label}
          </button>
        <% end %>
      </div>
      
    <!-- Components Grid -->
      <div class="components-grid">
        <%= for component <- @components do %>
          <.component_card component={component} />
        <% end %>
      </div>
    </div>

    <script>
      // Category filtering
      document.querySelectorAll('.category-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const category = e.target.dataset.category;
          
          // Update active button
          document.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
          e.target.classList.add('active');
          
          // Filter components
          document.querySelectorAll('.component-card').forEach(card => {
            if (category === 'all' || card.dataset.category === category) {
              card.style.display = 'block';
            } else {
              card.style.display = 'none';
            }
          });
        });
      });
    </script>
    """
  end

  @doc """
  Renders a component card.
  """
  def component_card(assigns) do
    ~H"""
    <div class="component-card" data-category={@component.category}>
      <div class="component-header">
        <h3 class="component-name">{@component.name}</h3>
        <span class="component-category">{@component.category}</span>
      </div>

      <div class="component-description">
        <p>{@component.description}</p>
      </div>

      <div class="component-example">
        <h4>Example Usage:</h4>
        <pre><code class="language-elixir"><%= @component.example %></code></pre>
      </div>

      <div class="component-props">
        <h4>Properties:</h4>
        <div class="props-list">
          <%= for prop <- @component.props do %>
            <.prop_item prop={prop} />
          <% end %>
        </div>
      </div>

      <div class="component-actions">
        <button class="btn btn-sm btn-primary" onclick={"copyToClipboard('#{@component.name}')"}>
          📋 Copy Code
        </button>
        <button class="btn btn-sm btn-secondary" onclick={"showPreview('#{@component.name}')"}>
          👁️ Preview
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a property item.
  """
  def prop_item(assigns) do
    ~H"""
    <div class="prop-item">
      <span class="prop-name">{@prop.name}</span>
      <span class="prop-type">{@prop.type}</span>
      <%= if @prop.required do %>
        <span class="prop-required">required</span>
      <% end %>
      <%= if Map.has_key?(@prop, :options) do %>
        <div class="prop-options">
          Options: {Enum.join(@prop.options, ", ")}
        </div>
      <% end %>
      <%= if Map.has_key?(@prop, :default) do %>
        <div class="prop-default">
          Default: {@prop.default}
        </div>
      <% end %>
    </div>
    """
  end
end
