# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BeamLab PhoenixKit is a professional Phoenix Framework authentication library that operates in two modes: as a standalone Phoenix application for development/demo purposes, and as a library dependency for integration into other Phoenix applications. Built with Elixir/Phoenix 1.8, it provides complete user authentication with modern UI components using Tailwind CSS and daisyUI.

## Development Commands

### Setup and Dependencies
- `mix setup` - Complete project setup (installs deps, sets up database, builds assets)
- `mix deps.get` - Install Elixir dependencies only

### Database Operations
- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with fresh data
- `mix ecto.setup` - Create database, run migrations, and seed data

### Development Server (Standalone Mode)
- `mix phx.server` - Start Phoenix server (visit http://localhost:4000)
- `iex -S mix phx.server` - Start server with interactive Elixir shell

### Testing
- `mix test` - Run all tests (automatically sets up test database)
- `mix test --cover` - Run tests with coverage report
- `mix test test/phoenix_kit/accounts_test.exs` - Run specific test file

### Asset Management
- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build CSS and JavaScript assets for development
- `mix assets.deploy` - Build and minify assets for production

### Library Development
- `mix test` - Verify library functionality (always runs in standalone mode for complete testing)
- Git tag format: `v1.0.0` (semantic versioning for library releases)

### Deprecated Installation Commands
**NOTE: As of v1.0.0, these commands are deprecated in favor of zero-configuration router integration:**
- `mix phoenix_kit.install` - DEPRECATED: Use `phoenix_kit()` macro in router instead
- `mix phoenix_kit.gen.migration` - DEPRECATED: Copy migrations manually
- `mix phoenix_kit.gen.routes` - DEPRECATED: Use `phoenix_kit()` macro instead

### Integration Testing
- Scripts: `scripts/test_integration.sh` (comprehensive) and `scripts/quick_test.sh` (basic)
- Manual testing preferred due to Mix tasks loading complexity
- See `TESTING.md` for comprehensive testing procedures

## Architecture

### Dual-Mode System
The project uses a sophisticated dual-mode architecture:

**Standalone Mode** (:standalone)
- Full Phoenix application with web interface  
- Used in `:dev` and `:test` environments
- Includes LiveDashboard, Swoosh mailbox, live reload
- Activated via `phoenix_kit_mode()` function in `mix.exs`

**Library Mode** (:library)
- Core functionality only for integration into other Phoenix apps
- Minimal dependencies, conditional compilation
- Default mode for production use as a dependency
- Excludes web server, dev tools, and optional dependencies

### Mode Detection Logic
Located in both `mix.exs` and `lib/phoenix_kit.ex`:
```elixir
# Always standalone in dev/test, configurable in other environments
def phoenix_kit_mode do
  case {Mix.env(), Application.get_env(:phoenix_kit, :mode)} do
    {:dev, _} -> :standalone
    {:test, _} -> :standalone  
    {_, :standalone} -> :standalone
    {_, :library} -> :library
    {_, nil} -> :library  # Default to library
  end
end
```

### Conditional Compilation
Key modules use conditional compilation to prevent issues in library mode:

- `BeamLab.PhoenixKit.Mailer` - Conditional Swoosh dependency
- `BeamLab.PhoenixKit.Accounts.UserNotifier` - Fallback implementation for library mode
- `BeamLab.PhoenixKitWeb.DevRoutes` - Macro-based conditional dev routes

### Main API Entry Point
`BeamLab.PhoenixKit` module serves as the main library API:
- `version()` - Returns current version
- `mode()` - Returns :standalone or :library  
- `standalone?()`, `library?()` - Mode checking functions
- `register_user/1`, `get_user_by_email/1`, etc. - Delegate functions to Accounts context
- `install/1`, `generate_migrations/1`, `generate_routes/1` - Programmatic installation functions for git dependency usage (legacy)

### Module Structure
- **BeamLab.PhoenixKit** - Main library API and version management
- **BeamLab.PhoenixKit.Accounts** - Complete authentication context
- **BeamLab.PhoenixKit.Accounts.User** - User schema with `phoenix_kit_users` table
- **BeamLab.PhoenixKit.Accounts.UserToken** - Token management for sessions/emails
- **BeamLab.PhoenixKitWeb** - Web layer (conditional for library mode)
- **BeamLab.PhoenixKitWeb.UserAuth** - Authentication plugs and helpers
- **BeamLab.PhoenixKitWeb.Router** - Zero-configuration router integration via `phoenix_kit()` macro
- **BeamLab.PhoenixKitWeb.AuthRouter** - Dedicated authentication routes handler (used internally by forward/4)

### Database Schema
Uses `phoenix_kit_` prefixed tables to avoid conflicts:
- `phoenix_kit_users` - User accounts
- `phoenix_kit_user_tokens` - Session and email tokens

### Dependencies Architecture
Dependencies are categorized:

**CORE** - Always included:
- Phoenix, Ecto, bcrypt_elixir, Tailwind CSS, LiveView

**STANDALONE** - Optional dependencies marked with `optional: true`:
- Bandit (web server), Swoosh (email), LiveDashboard, Telemetry

### Authentication Features
- Magic link authentication (passwordless login)
- Traditional email/password registration and login
- Password reset functionality
- Email confirmation workflows
- Session management with secure tokens
- Built-in security best practices

### UI Components
- Modern Tailwind CSS + daisyUI design system
- Dark/light theme support with system preference detection
- Responsive design patterns
- Reusable form components and layouts

## Integration Usage

This library is designed to be installed as a git dependency:
```elixir
{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
```

### Modern Integration (v1.0.0+) - Zero Configuration

**Recommended**: Use the new zero-configuration approach following Phoenix LiveDashboard pattern:

```elixir
# In your router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user  # PhoenixKit auth
  end

  scope "/" do
    pipe_through :browser
    get "/", PageController, :home
  end

  # PhoenixKit authentication - ONE LINE!
  phoenix_kit()
end
```

This approach:
- Works with git dependencies without Mix tasks
- Uses Phoenix.Router.forward/4 internally to `/phoenix_kit` routes
- Follows Phoenix best practices for modular routing
- Automatically imports authentication plugs

### Legacy Installation (Pre-v1.0.0)

**Deprecated**: The old programmatic installation is still available but deprecated:

#### Programmatic Installation (Works with Git Dependencies)

```elixir
# Complete installation
BeamLab.PhoenixKit.install()

# Or with custom scope prefix (default is "phoenix_kit_users")
BeamLab.PhoenixKit.install(scope_prefix: "auth")

# Individual functions
BeamLab.PhoenixKit.generate_migrations()
BeamLab.PhoenixKit.generate_routes()
BeamLab.PhoenixKit.show_router_example()
```

#### Mix Tasks (If Available)

```bash
# After adding PhoenixKit dependency and running mix deps.get
mix phoenix_kit.install
```

Both methods will:
- Copy database migrations with proper timestamps
- Generate configuration files
- Display router setup instructions
- Show layout integration examples

### Individual Installation Commands

```bash
# Generate only database migrations
mix phoenix_kit.gen.migration

# Generate only router configuration
mix phoenix_kit.gen.routes --scope-prefix auth

# Show what routes would be generated without modifying files
mix phoenix_kit.gen.routes --dry-run
```

### Manual Step-by-Step Integration

1. **Add dependency** to `mix.exs`:
```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"},
    {:bcrypt_elixir, "~> 3.0"},  # If not already present
    {:tailwind, "~> 0.3"}        # If not already present
  ]
end
```

2. **Configure library mode** in `config/config.exs`:
```elixir
config :phoenix_kit, mode: :library

# Optional: Configure mailer for email features
config :phoenix_kit, BeamLab.PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local
```

3. **Add database tables**. Copy migrations from `deps/phoenix_kit/priv/repo/migrations/` or run:
```bash
# Copy PhoenixKit migrations
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/
mix ecto.migrate
```

4. **Configure router** in `lib/your_app_web/router.ex`:
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
    # Add PhoenixKit user authentication
    plug :fetch_current_scope_for_user
  end

  # Your existing routes
  scope "/", YourAppWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # PhoenixKit Authentication routes
  scope "/auth", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/register", UserRegistrationController, :new
    post "/register", UserRegistrationController, :create
    get "/log-in", UserSessionController, :new
    post "/log-in", UserSessionController, :create
    get "/log-in/:token", UserSessionController, :confirm
  end

  scope "/auth", BeamLab.PhoenixKitWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
    delete "/log-out", UserSessionController, :delete
  end
end
```

5. **Update layout** to include authentication state in `lib/your_app_web/components/layouts/app.html.heex`:
```heex
<!-- Navigation with authentication -->
<nav class="navbar bg-base-100">
  <div class="navbar-end">
    <%= if @current_scope do %>
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-ghost">
          <%= @current_scope.user.email %>
        </div>
        <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
          <li><.link navigate={~p"/auth/settings"}>Settings</.link></li>
          <li><.link href={~p"/auth/log-out"} method="delete">Log out</.link></li>
        </ul>
      </div>
    <% else %>
      <.link navigate={~p"/auth/log-in"} class="btn btn-ghost">Log in</.link>
      <.link navigate={~p"/auth/register"} class="btn btn-primary">Sign up</.link>
    <% end %>
  </div>
</nav>
```

6. **Use PhoenixKit API** in your application:
```elixir
# In controllers or contexts
alias BeamLab.PhoenixKit

# User management
{:ok, user} = PhoenixKit.register_user(%{email: "user@example.com"})
user = PhoenixKit.get_user_by_email("user@example.com") 
{:ok, {user, _tokens}} = PhoenixKit.update_user_password(user, %{
  password: "new_password",
  password_confirmation: "new_password"
})

# Check authentication in controllers
def protected_action(conn, _params) do
  if conn.assigns.current_scope do
    user = conn.assigns.current_scope.user
    # User is authenticated
  else
    # Redirect to login
    redirect(conn, to: ~p"/auth/log-in")
  end
end
```

### Authentication Plugs Available

Import `BeamLab.PhoenixKitWeb.UserAuth` to access:
- `fetch_current_scope_for_user` - Loads current user into `@current_scope` assign
- `require_authenticated_user` - Requires user to be logged in
- `redirect_if_user_is_authenticated` - Redirects authenticated users away
- `log_in_user(conn, user, params)` - Programmatically log in user
- `log_out_user(conn)` - Programmatically log out user

### Database Schema Details

The migration creates two tables with `phoenix_kit_` prefix to avoid conflicts:

```elixir
# phoenix_kit_users table
create table(:phoenix_kit_users) do
  add :email, :citext, null: false           # Case-insensitive email
  add :hashed_password, :string              # BCrypt hashed password
  add :confirmed_at, :utc_datetime           # Email confirmation timestamp
  timestamps(type: :utc_datetime)
end

# phoenix_kit_users_tokens table  
create table(:phoenix_kit_users_tokens) do
  add :user_id, references(:phoenix_kit_users, on_delete: :delete_all), null: false
  add :token, :binary, null: false           # Session/email verification tokens
  add :context, :string, null: false         # "session", "confirm", "reset_password"
  add :sent_to, :string                      # Email address for email tokens
  add :authenticated_at, :utc_datetime       # Last authentication time
  timestamps(type: :utc_datetime, updated_at: false)
end
```

### Advanced Integration Examples

```elixir
# config/dev.exs - Development environment
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres",
  password: "postgres", 
  database: "yourapp_dev",
  hostname: "localhost"

# config/test.exs - Test environment
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres",
  password: "postgres",
  database: "yourapp_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Testing helpers
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
```

### Magic Link Authentication

PhoenixKit supports passwordless login via magic links:

```elixir
# Send magic link email
BeamLab.PhoenixKit.Accounts.deliver_login_instructions(
  user, 
  &url(~p"/auth/log-in/#{&1}")
)

# Login via magic link token
{:ok, user} = BeamLab.PhoenixKit.Accounts.login_user_by_magic_link(token)
```

## File Structure Notes

**Core Architecture:**
- `lib/phoenix_kit.ex` - Main API entry point with delegate functions  
- `lib/phoenix_kit/accounts.ex` - Complete authentication context (400+ lines)
- `lib/phoenix_kit/accounts/user.ex` - User schema with validations
- `lib/phoenix_kit/accounts/user_token.ex` - Token management schema

**Web Layer:**
- `lib/phoenix_kit_web/router.ex` - Standalone mode router
- `lib/phoenix_kit_web/router_helpers.ex` - Zero-configuration `phoenix_kit()` macro
- `lib/phoenix_kit_web/auth_router.ex` - Authentication routes for forward/4 delegation
- `lib/phoenix_kit_web/user_auth.ex` - Authentication plugs and session management
- `lib/phoenix_kit_web/controllers/` - Registration, session, settings controllers
- `lib/phoenix_kit_web/components/` - UI components and layouts

**Development & Testing:**
- `scripts/test_integration.sh` - Comprehensive integration testing script
- `scripts/quick_test.sh` - Quick testing script for basic functionality
- `TESTING.md` / `TESTING.ru.md` - Testing guide (English/Russian)
- `UPGRADE.md` / `UPGRADE.ru.md` - Upgrade guide (English/Russian)

**Assets & Configuration:**
- `assets/` - Tailwind CSS and JavaScript assets
- `priv/repo/migrations/` - Database migration templates
- `lib/mix/tasks/` - Deprecated Mix tasks (use router integration instead)

**Key Architectural Notes:**
- Conditional modules handle library vs standalone compilation differences
- Router architecture follows Phoenix LiveDashboard forward/4 pattern
- All routes use `/phoenix_kit/` prefix to avoid conflicts

## Version Management

Uses semantic versioning with Git tags (v1.0.0, v0.2.1, etc.). Version is defined in `mix.exs` and must be kept in sync with git tags and documentation references.

**Major Version Changes:**
- **v1.0.0+**: Zero-configuration with `phoenix_kit()` macro, deprecated installation commands
- **v0.x.x**: Legacy installation requiring `mix phoenix_kit.install` and manual setup

## Key Implementation Patterns

### Router Integration Architecture
The library uses a sophisticated router delegation pattern:

1. **`BeamLab.PhoenixKitWeb.Router`** - Provides the `phoenix_kit()` macro for zero-configuration integration
2. **`BeamLab.PhoenixKitWeb.AuthRouter`** - Handles actual authentication routes via Phoenix.Router.forward/4
3. **Route Prefix**: All authentication routes are prefixed with `/phoenix_kit/` to avoid conflicts

This follows the same pattern as Phoenix LiveDashboard for modular, conflict-free routing.

### Conditional Compilation Strategy
The library uses environment-aware conditional compilation:
- Dev/Test: Always runs in `:standalone` mode with full web interface
- Production: Defaults to `:library` mode with minimal dependencies
- Configuration: Can be overridden via `config :phoenix_kit, mode: :library`

### Authentication Flow Architecture
- **Session Management**: Uses Phoenix's built-in session store with secure tokens
- **Password Security**: BCrypt hashing with secure defaults
- **Magic Links**: Tokenized passwordless authentication via email
- **User Scoping**: Uses `@current_scope` assign pattern for authentication state