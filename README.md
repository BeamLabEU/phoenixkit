# BeamLab PhoenixKit

A comprehensive Phoenix Framework authentication library with a modern UI design system built on Tailwind CSS and daisyUI components.

## Features

- 🔐 Complete Phoenix authentication system (login, registration, password reset)
- 🎨 Modern UI components with Tailwind CSS and daisyUI
- 🌓 Dark/Light theme support
- 📱 Responsive design
- 🔧 Dual mode: Standalone application or Library dependency
- 🏷️ Git-based versioning system

## Installation

### As a Git Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## 🚀 Integration Guide

### Automated Installation (Recommended)

**Important**: When using PhoenixKit as a git dependency, Mix tasks may not be available. Use the programmatic installation instead:

#### Option 1: Programmatic Installation (Works with Git Dependencies)

After adding PhoenixKit to your dependencies:

```bash
mix deps.get
```

Then in your IEx console or create a temporary script:

```elixir
# Complete installation (uses actual PhoenixKit routes)
BeamLab.PhoenixKit.install()

# Or with custom scope prefix (default is "phoenix_kit_users") 
BeamLab.PhoenixKit.install(scope_prefix: "auth")

# Individual functions
BeamLab.PhoenixKit.generate_migrations()
BeamLab.PhoenixKit.generate_routes()
BeamLab.PhoenixKit.show_router_example()
```

#### Option 2: Mix Tasks (If Available)

```bash
mix phoenix_kit.install
```

Both methods will:
- ✅ Copy database migrations with proper timestamps
- ✅ Generate configuration in `config/config.exs`
- ✅ Display router setup instructions
- ✅ Show layout integration examples
- ✅ Provide next steps guidance

### Individual Commands

```bash
# Generate only database migrations
mix phoenix_kit.gen.migration

# Generate router configuration
mix phoenix_kit.gen.routes --scope-prefix auth

# Preview router changes without modifying files
mix phoenix_kit.gen.routes --dry-run

# Help for any command
mix help phoenix_kit.install
```

### Manual Step-by-Step Installation

### Step 1: Installation

Add PhoenixKit to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"},
    # Add these if not already present
    {:bcrypt_elixir, "~> 3.0"},
    {:tailwind, "~> 0.3"},
  ]
end
```

Install dependencies:
```bash
mix deps.get
```

### Step 2: Configuration

Configure PhoenixKit in `config/config.exs`:

```elixir
# Basic library mode configuration
config :phoenix_kit, 
  mode: :library,
  library_mode: true

# Database configuration for PhoenixKit tables
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres",
  password: "postgres", 
  database: "your_app_dev",
  hostname: "localhost",
  pool_size: 10

# Configure mailer (optional - for email features)
config :phoenix_kit, BeamLab.PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local

# Add to your app's configuration
config :your_app, :phoenix_kit_integration, true
```

### Step 3: Database Setup

Create and run PhoenixKit migrations:

```bash
# Generate migration to add PhoenixKit tables
mix ecto.gen.migration add_phoenix_kit_tables

# Copy PhoenixKit migrations to your project
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/

# Run migrations
mix ecto.migrate
```

Or manually add PhoenixKit tables to your existing schema:

```elixir
# In your migration file
defmodule YourApp.Repo.Migrations.AddPhoenixKitTables do
  use Ecto.Migration

  def change do
    # Phoenix Kit Users table
    create table(:phoenix_kit_users) do
      add :email, :string, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :authenticated_at, :utc_datetime

      timestamps()
    end

    create unique_index(:phoenix_kit_users, [:email])

    # Phoenix Kit User Tokens table
    create table(:phoenix_kit_user_tokens) do
      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:phoenix_kit_user_tokens, [:user_id])
    create unique_index(:phoenix_kit_user_tokens, [:context, :token])
  end
end
```

### Step 4: Router Integration

Add PhoenixKit routes to your `router.ex`:

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  
  # Import PhoenixKit authentication functions
  import BeamLab.PhoenixKitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # Add PhoenixKit user fetching
    plug :fetch_current_scope_for_user
  end

  # Your existing routes
  scope "/", YourAppWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # PhoenixKit Authentication routes (actual routes)
  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/phoenix_kit_users/register", UserRegistrationController, :new
    post "/phoenix_kit_users/register", UserRegistrationController, :create
  end

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/phoenix_kit_users/settings", UserSettingsController, :edit
    put "/phoenix_kit_users/settings", UserSettingsController, :update
    get "/phoenix_kit_users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", BeamLab.PhoenixKitWeb do
    pipe_through [:browser]

    get "/phoenix_kit_users/log-in", UserSessionController, :new
    get "/phoenix_kit_users/log-in/:token", UserSessionController, :confirm
    post "/phoenix_kit_users/log-in", UserSessionController, :create
    delete "/phoenix_kit_users/log-out", UserSessionController, :delete
  end
end
```

### Step 5: Layout Integration

Update your application layout to support PhoenixKit styles and components:

```heex
<!-- In your app.html.heex or root.html.heex -->
<!DOCTYPE html>
<html lang="en" data-theme="system">
  <head>
    <!-- Your existing head content -->
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    
    <!-- PhoenixKit styles (includes Tailwind + daisyUI) -->
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    
    <!-- Theme support script -->
    <script>
      const setTheme = (theme) => {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
      };
      
      const theme = localStorage.getItem('theme') || 
                   (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
      setTheme(theme);
    </script>
  </head>
  
  <body>
    <!-- Navigation with authentication -->
    <nav class="navbar bg-base-100">
      <div class="navbar-start">
        <.link navigate={~p"/"} class="btn btn-ghost text-xl">YourApp</.link>
      </div>
      <div class="navbar-end">
        <%= if @current_scope do %>
          <div class="dropdown dropdown-end">
            <div tabindex="0" role="button" class="btn btn-ghost">
              <%= @current_scope.user.email %>
            </div>
            <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
              <li><.link navigate={~p"/phoenix_kit_users/settings"}>Settings</.link></li>
              <li>
                <.link href={~p"/phoenix_kit_users/log-out"} method="delete">
                  Log out
                </.link>
              </li>
            </ul>
          </div>
        <% else %>
          <.link navigate={~p"/phoenix_kit_users/log-in"} class="btn btn-ghost">Log in</.link>
          <.link navigate={~p"/phoenix_kit_users/register"} class="btn btn-primary">Sign up</.link>
        <% end %>
      </div>
    </nav>

    <!-- Flash messages -->
    <main>
      <.flash_group flash={@flash} />
      <%= @inner_content %>
    </main>
    
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
  </body>
</html>
```

### Step 6: Using PhoenixKit API

```elixir
# In your controllers or contexts
defmodule YourAppWeb.SomeController do
  use YourAppWeb, :controller
  
  # User management
  def create_user(conn, params) do
    case BeamLab.PhoenixKit.register_user(params["user"]) do
      {:ok, user} -> 
        # Handle success
        redirect(conn, to: ~p"/dashboard")
      {:error, changeset} ->
        # Handle error
        render(conn, :new, changeset: changeset)
    end
  end
  
  # Check authentication
  def protected_action(conn, _params) do
    if conn.assigns.current_scope do
      # User is authenticated
      user = conn.assigns.current_scope.user
      render(conn, :show, user: user)
    else
      # Redirect to login
      redirect(conn, to: ~p"/phoenix_kit_users/log-in")
    end
  end
end

# In your contexts
defmodule YourApp.SomeContext do
  
  def get_user_profile(email) do
    BeamLab.PhoenixKit.get_user_by_email(email)
  end
  
  def update_user_password(user, attrs) do
    BeamLab.PhoenixKit.update_user_password(user, attrs)
  end
end
```

### Step 7: UI Components Usage

Use PhoenixKit UI components in your templates:

```heex
<!-- Using PhoenixKit form components -->
<.form :let={f} for={@changeset} action={~p"/some/action"}>
  <.input 
    field={f[:email]} 
    type="email" 
    label="Email" 
    required 
  />
  <.input 
    field={f[:password]} 
    type="password" 
    label="Password" 
    required 
  />
  <.button class="btn btn-primary w-full">
    Submit
  </.button>
</.form>

<!-- Using theme toggle -->
<div class="flex items-center gap-4">
  <BeamLab.PhoenixKitWeb.Layouts.theme_toggle />
</div>

<!-- Using flash messages -->
<BeamLab.PhoenixKitWeb.Layouts.flash_group flash={@flash} />
```

## 🔧 Advanced Configuration

### Custom Email Templates

Override email templates by creating your own notifier:

```elixir
defmodule YourApp.UserNotifier do
  # Delegate to PhoenixKit or implement custom logic
  defdelegate deliver_login_instructions(user, url), 
    to: BeamLab.PhoenixKit.Accounts.UserNotifier
    
  # Custom implementation
  def deliver_welcome_email(user) do
    # Your custom email logic
  end
end
```

### Custom Authentication Pipelines

Create custom authentication pipelines:

```elixir
defmodule YourAppWeb.CustomAuth do
  import BeamLab.PhoenixKitWeb.UserAuth
  
  def require_admin(conn, _opts) do
    if conn.assigns.current_scope && 
       conn.assigns.current_scope.user.role == :admin do
      conn
    else
      conn
      |> put_flash(:error, "Access denied")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
```

## 🚨 Troubleshooting

### Common Issues

1. **Migration conflicts**: Ensure PhoenixKit table names don't conflict with existing tables
2. **CSS not loading**: Verify Tailwind configuration includes PhoenixKit paths
3. **Authentication not working**: Check router pipeline order and scope configuration
4. **Theme not switching**: Ensure theme toggle JavaScript is loaded

### Environment Configuration

For different environments:

```elixir
# config/dev.exs
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres",
  password: "postgres",
  database: "yourapp_dev",
  hostname: "localhost"

# config/test.exs  
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres", 
  password: "postgres",
  database: "yourapp_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# config/prod.exs
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

## Development

### Standalone Mode

Clone and run as a standalone Phoenix application:

```bash
git clone https://github.com/BeamLabEU/phoenixkit.git
cd phoenixkit
mix setup
mix phx.server
```

Visit `http://localhost:4000` to see the application.

### Available Commands

- `mix setup` - Complete project setup
- `mix deps.get` - Install dependencies
- `mix ecto.setup` - Setup database
- `mix phx.server` - Start development server
- `mix test` - Run tests

## Architecture

PhoenixKit supports two modes:

### Standalone Mode
- Full Phoenix application with web interface
- Development and demo purposes
- All dependencies included

### Library Mode  
- Core functionality only
- Minimal dependencies
- Suitable for integration into existing projects

## Components

### Authentication System
- User registration and login
- Password reset functionality
- Magic link authentication
- Session management

### UI Components
- Modern Tailwind CSS styling
- daisyUI component system
- Dark/light theme toggle
- Responsive design patterns

## 📚 API Reference

### Core Functions

```elixir
# Library information
BeamLab.PhoenixKit.version()     # => "1.0.0"
BeamLab.PhoenixKit.mode()        # => :library | :standalone
BeamLab.PhoenixKit.library?()    # => true | false

# User management (direct API)
{:ok, user} = BeamLab.PhoenixKit.register_user(%{email: "user@example.com"})
user = BeamLab.PhoenixKit.get_user_by_email("user@example.com")
{:ok, {user, _tokens}} = BeamLab.PhoenixKit.update_user_password(user, %{
  password: "new_password", 
  password_confirmation: "new_password"
})
```

### Authentication Context

Access the full Accounts context for advanced usage:

```elixir
alias BeamLab.PhoenixKit.Accounts

# User queries
Accounts.get_user!(123)
Accounts.get_user_by_email_and_password("user@example.com", "password")

# Magic link authentication  
Accounts.deliver_login_instructions(user, &url(~p"/phoenix_kit_users/log-in/#{&1}"))
{:ok, user} = Accounts.login_user_by_magic_link(token)

# Session management
token = Accounts.generate_user_session_token(user)
{user, inserted_at} = Accounts.get_user_by_session_token(token)
Accounts.delete_user_session_token(token)

# Email changes
changeset = Accounts.change_user_email(user, %{email: "new@example.com"})
{:ok, user} = Accounts.update_user_email(user, token)
```

## 🧪 Testing Integration

PhoenixKit includes comprehensive tests. To test your integration:

```bash
# Run PhoenixKit tests
mix test

# Run with coverage
mix test --cover

# Test specific functionality
mix test test/phoenix_kit/accounts_test.exs
```

### Testing in Your App

```elixir
# In your test helpers
defmodule YourApp.PhoenixKitHelpers do
  def create_user(attrs \\ %{}) do
    attrs = 
      %{email: "user#{System.unique_integer()}@example.com"}
      |> Map.merge(attrs)
    
    {:ok, user} = BeamLab.PhoenixKit.register_user(attrs)
    user
  end
  
  def log_in_user(conn, user) do
    token = BeamLab.PhoenixKit.Accounts.generate_user_session_token(user)
    
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end

# In your tests
test "protected page requires authentication", %{conn: conn} do
  conn = get(conn, ~p"/protected")
  assert redirected_to(conn) == ~p"/phoenix_kit_users/log-in"
end

test "authenticated user can access protected page", %{conn: conn} do
  user = create_user()
  conn = log_in_user(conn, user)
  
  conn = get(conn, ~p"/protected") 
  assert html_response(conn, 200) =~ "Welcome"
end
```

## 🧪 Testing PhoenixKit as Module

For developers and contributors who want to test PhoenixKit integration:

### Quick Manual Test

```bash
# Create test Phoenix project
mix phx.new test_app --no-live --no-dashboard
cd test_app

# Add to mix.exs dependencies:
{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}

# Install and test
mix deps.get
mix compile
mix phoenix_kit.install
mix ecto.create
mix ecto.migrate
mix phx.server
```

Open http://localhost:4000/auth/register to test registration.

### Comprehensive Testing

See [TESTING.md](TESTING.md) for detailed testing instructions, troubleshooting, and step-by-step verification process.

## 📈 Upgrading

See [UPGRADE.md](UPGRADE.md) for detailed upgrade instructions from previous versions.

## Versioning

This project uses semantic versioning with Git tags:

- `v1.0.0` - Stable release with library mode support
- `v0.2.1` - Library mode compatibility fixes
- `v0.1.0` - Initial release
- Tags follow the format `vMAJOR.MINOR.PATCH`

To use a specific version:

```elixir
{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
```

## License

Copyright (c) 2024 BeamLab

This project is licensed under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `mix test`
5. Submit a pull request

## Support

For issues and questions:
- GitHub Issues: https://github.com/BeamLabEU/phoenixkit/issues
- Documentation: https://hexdocs.pm/phoenix_kit/

---

Built with ❤️ by [BeamLab](https://github.com/BeamLabEU)
