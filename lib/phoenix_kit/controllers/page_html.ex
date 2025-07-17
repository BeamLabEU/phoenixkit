defmodule PhoenixKit.PageHTML do
  use Phoenix.Component

  @moduledoc """
  HTML components and templates for the PhoenixKit main page.
  """

  # Templates are defined as functions below

  @doc """
  Renders the main PhoenixKit landing page.
  """
  def index(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <!-- Hero Section -->
      <div class="hero min-h-screen bg-base-200">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="text-5xl font-bold">{@title}</h1>
            <p class="py-6">{@subtitle}</p>

            <div class="stats shadow mb-8">
              <div class="stat">
                <div class="stat-title">Version</div>
                <div class="stat-value text-primary">{@stats.version}</div>
              </div>
              <div class="stat">
                <div class="stat-title">Status</div>
                <div class="stat-value text-success">{@stats.status}</div>
              </div>
            </div>

            <div class="space-x-4">
              <.link href="/phoenix_kit/dashboard" class="btn btn-primary">
                View Dashboard
              </.link>
              <.link href="/phoenix_kit/components" class="btn btn-secondary">
                Browse Components
              </.link>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Features Section -->
      <div class="py-16 bg-base-100">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12">Available Features</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for feature <- @features do %>
              <.feature_card feature={feature} />
            <% end %>
          </div>
        </div>
      </div>
      
    <!-- Quick Start Section -->
      <div class="py-16 bg-base-200">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold text-center mb-12">Quick Start</h2>
          <div class="max-w-4xl mx-auto">
            <p class="text-center mb-8 text-lg">
              Add PhoenixKit to your Phoenix application in 3 simple steps:
            </p>

            <div class="steps steps-vertical lg:steps-horizontal">
              <div class="step step-primary">
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <h3 class="card-title">Add to dependencies</h3>
                    <div class="mockup-code">
                      <pre><code class="language-elixir">&#123;:phoenix_kit, github: "BeamLabEU/phoenixkit"&#125;</code></pre>
                    </div>
                  </div>
                </div>
              </div>

              <div class="step step-primary">
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <h3 class="card-title">Add routes</h3>
                    <div class="mockup-code">
                      <pre><code class="language-elixir">import PhoenixKit
                      PhoenixKit.routes()</code></pre>
                    </div>
                  </div>
                </div>
              </div>

              <div class="step step-primary">
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <h3 class="card-title">Run installation</h3>
                    <div class="mockup-code">
                      <pre><code class="language-bash">mix phoenix_kit.install</code></pre>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a feature card component.
  """
  def feature_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <div class="text-4xl mb-4">{@feature.icon}</div>
        <h3 class="card-title">{@feature.title}</h3>
        <p class="text-base-content/70">{@feature.description}</p>
        <div class="card-actions justify-end">
          <.link href={@feature.link} class="btn btn-primary">
            Learn More →
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
