# PhoenixKit - The Phoenix LiveView Starter Kit

Don't reinvent the wheel, create Elixir/Phoenix-powered apps much faster.

## Overview

PhoenixKit is a production-ready authentication library for Phoenix applications, built with Oban-style architecture for seamless integration. It provides complete user authentication with registration, login, email confirmation, password reset, and session management.

### Key Features

- **Igniter installation** - Simplified installation 
- **Authentication** - Registration, login, logout, email confirmation, password reset
- **Role-Based Access Control** - Built-in Owner/Admin/User roles with management interface
- **Layout integration** - Versioned migrations with Oban-style architecture
- **Developer Friendly** - Single command installation with automatic setup

Start building your apps today!

## Installation

PhoenixKit provides multiple installation methods to suit different project needs and developer preferences.

### Semi-Automatic Installation

**Recommended for most projects**

Add both `phoenix_kit` and `igniter` to your project dependencies:

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, "~> 1.0"},
    {:igniter, "~> 0.6.0", only: [:dev]}
  ]
end
```

Then run the PhoenixKit installer:

```bash
mix deps.get
mix phoenix_kit.install
```

This will automatically:
- ✅ Auto-detect your Ecto repository
- ✅ **Validate PostgreSQL compatibility** with adapter detection
- ✅ Generate migration files for authentication tables
- ✅ **Optionally run migrations interactively** for instant setup
- ✅ Add PhoenixKit configuration to `config/config.exs`
- ✅ Configure mailer settings for development
- ✅ **Create production mailer templates** in `config/prod.exs`
- ✅ Add authentication routes to your router
- ✅ Provide detailed setup instructions

**Optional parameters:**

```bash
# Specify custom repository
mix phoenix_kit.install --repo MyApp.Repo

# Use PostgreSQL schema prefix for table isolation
mix phoenix_kit.install --prefix "auth" --create-schema

# Specify custom router file path
mix phoenix_kit.install --router-path lib/my_app_web/router.ex
```

### Igniter Installation

**Single command installation**

For the simplest possible setup, use PhoenixKit's installer:

```bash
mix phoenix_kit.install
```

Optional repository specification:

```bash
mix phoenix_kit.install --repo MyApp.Repo
```

### Manual Installation

**For maximum control**

1. **Add dependency:**

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, "~> 1.0"}
  ]
end
```

2. **Install dependency:**

```bash
mix deps.get
```

3. **Generate migration:**

```bash
mix phoenix_kit.gen.migration add_phoenix_kit_auth_tables
```

4. **Configure PhoenixKit:**

```elixir
# config/config.exs
config :phoenix_kit,
  repo: MyApp.Repo

# Required: Configure mailer for email delivery
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local  # Development
```

5. **Add routes to your router:**

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # Your existing pipelines...

  # Add PhoenixKit authentication routes
  phoenix_kit_routes()  # Available at /phoenix_kit/*
end
```

6. **Run migration:**

```bash
mix ecto.migrate
```

## Quick Verification

After installation, start your Phoenix server:

```bash
mix phx.server
```

Visit these URLs to verify PhoenixKit is working:

- `http://localhost:4000/phoenix_kit/users/register` - User registration
- `http://localhost:4000/phoenix_kit/users/log-in` - User login

## Production Setup

For production environments, configure a proper email adapter:

```elixir
# config/prod.exs
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.your-provider.com",
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  port: 587,
  tls: :always,
  auth: :always
```

## Advanced Configuration

### Custom URL Prefix

You can customize the URL prefix for PhoenixKit routes:

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # Custom prefix examples
  phoenix_kit_routes("/authentication")  # Available at /authentication/*
  phoenix_kit_routes("/users")          # Available at /users/*
end
```

**⚠️ Note:** We don't recommend using `/auth` as the prefix to avoid conflicts with common authentication patterns.

### PostgreSQL Schema Isolation

For better table organization, you can use PostgreSQL schemas:

```bash
# Install with schema prefix - creates tables in 'auth' schema
mix phoenix_kit.install --prefix "auth" --create-schema
```

This creates tables as:

- `auth.phoenix_kit_users`
- `auth.phoenix_kit_users_tokens`

### Custom Repository

Specify a different Ecto repository:

```bash
# Use custom repository
mix phoenix_kit.install --repo MyApp.CustomRepo
```

### Multiple Ecto Repositories

If you have multiple repos, PhoenixKit will auto-detect the first one, or specify explicitly:

```elixir
# config/config.exs
config :phoenix_kit, repo: MyApp.CustomRepo
```

## Configuration

PhoenixKit uses your application's repository:

```elixir
# config/config.exs (automatically added by installer)
config :phoenix_kit, repo: YourApp.Repo
```

### Advanced Configuration

```elixir
config :phoenix_kit,
  repo: YourApp.Repo,
  # Optional: Custom mailer for sending emails
  mailer: YourApp.Mailer

# Layout Integration - Use your app's layouts instead of PhoenixKit's
config :phoenix_kit,
  layout: {YourAppWeb.Layouts, :app},        # Use your app's main layout
  root_layout: {YourAppWeb.Layouts, :root},  # Optional: custom root layout
  page_title_prefix: "Auth"                  # Optional: prefix for page titles

# Layout examples:
# Minimal - only app layout:
# config :phoenix_kit, layout: {YourAppWeb.Layouts, :app}
#
# Complete integration with your app's design:
# config :phoenix_kit,
#   layout: {YourAppWeb.Layouts, :app},
#   root_layout: {YourAppWeb.Layouts, :root},
#   page_title_prefix: "Authentication"

### ⚠️ Important: Recompilation Required

When you modify layout configuration, you **must** recompile PhoenixKit:

```bash
mix deps.compile phoenix_kit --force
```

**Why?** Elixir configuration is compiled at build-time. Changes to `config/config.exs` won't take effect until PhoenixKit is recompiled.

**When to recompile:**
- After adding layout configuration
- After changing `layout` or `root_layout` values  
- After modifying `page_title_prefix`
- When layout integration stops working after config changes

## Phoenix 1.8+ Compatibility

PhoenixKit is fully compatible with Phoenix 1.8+ and supports both layout integration approaches:

### Current Implementation (Works with all Phoenix versions)
- ✅ **Automatic layout detection** - PhoenixKit.LayoutConfig detects your layouts at runtime
- ✅ **Function component integration** - Works seamlessly with Phoenix 1.8 `<Layouts.app>` components
- ✅ **Fallback system** - Uses PhoenixKit defaults if parent layouts aren't configured
- ✅ **Runtime validation** - Validates parent layout modules with helpful warnings

### Phoenix 1.8 Features Supported
- 🚀 **Function Components** - All LiveView templates use `<Layouts.app flash={@flash}>` pattern
- 🔧 **Component Integration** - Supports modern Phoenix component architecture
- 📱 **Responsive Design** - Works with Phoenix 1.8's updated layout system
- 🎨 **Flash Messages** - Integrates with Phoenix 1.8's flash component system

### Layout Integration Process

When you configure layout integration, PhoenixKit automatically:

1. **Detects Parent Layouts** - Validates your app's layout modules exist
2. **Applies Configuration** - Uses your layouts for all PhoenixKit pages
3. **Handles Flash Messages** - Integrates flash messages through your layout
4. **Provides Fallbacks** - Uses PhoenixKit layouts if parent layouts unavailable

### Migration from Phoenix 1.7 to 1.8

If you're upgrading your Phoenix app from 1.7 to 1.8, PhoenixKit will automatically:
- Continue working with existing configuration
- Support new Phoenix 1.8 layout patterns
- Maintain backward compatibility with Phoenix 1.7 layouts

**No changes required** to your PhoenixKit configuration when upgrading Phoenix!
```

## Authentication Routes

PhoenixKit provides these LiveView routes under your chosen prefix:

### Public Authentication Routes
- `GET /phoenix_kit/users/register` - User registration form (LiveView)
- `GET /phoenix_kit/users/log-in` - Login form (LiveView)
- `POST /phoenix_kit/users/log-in` - User login
- `DELETE /phoenix_kit/users/log-out` - User logout
- `GET /phoenix_kit/users/log-out` - User logout (direct URL access)
- `GET /phoenix_kit/users/magic-link` - Magic link login page
- `GET /phoenix_kit/users/magic-link/:token` - Magic link verification
- `GET /phoenix_kit/users/reset-password` - Password reset request (LiveView)
- `GET /phoenix_kit/users/reset-password/:token` - Password reset form (LiveView)
- `GET /phoenix_kit/users/confirm/:token` - Account confirmation (LiveView)
- `GET /phoenix_kit/users/confirm` - Resend confirmation (LiveView)

### Authenticated User Routes
- `GET /phoenix_kit/users/settings` - User settings (LiveView, requires login)
- `GET /phoenix_kit/users/settings/confirm_email/:token` - Email confirmation

### Admin Routes (Owner/Admin access required)
- `GET /phoenix_kit/admin/dashboard` - Admin dashboard with system statistics
- `GET /phoenix_kit/admin/users` - User management interface with role controls

## Database Schema

PhoenixKit creates these tables:

### `phoenix_kit_users` (Users)

- `id` - Primary key (bigserial)
- `email` - Email address (citext, unique)
- `hashed_password` - Bcrypt hashed password
- `first_name` - User's first name (optional)
- `last_name` - User's last name (optional)
- `is_active` - User status (boolean, default: true)
- `confirmed_at` - Email confirmation timestamp
- `inserted_at`, `updated_at` - Timestamps

### `phoenix_kit_users_tokens` (Authentication Tokens)

- `id` - Primary key (bigserial)
- `user_id` - Foreign key to phoenix_kit_users
- `token` - Secure token (bytea)
- `context` - Token type (session, email, reset)
- `sent_to` - Email address for email tokens
- `inserted_at` - Creation timestamp

### `phoenix_kit_user_roles` (Roles)

- `id` - Primary key (bigserial)
- `name` - Role name (text, unique)
- `description` - Role description (text)
- `is_system_role` - System role flag (boolean)
- `inserted_at` - Creation timestamp

### `phoenix_kit_user_role_assignments` (Role Assignments)

- `id` - Primary key (bigserial)
- `user_id` - Foreign key to phoenix_kit_users
- `role_id` - Foreign key to phoenix_kit_user_roles
- `assigned_by` - User who assigned the role (optional)
- `assigned_at` - Assignment timestamp
- `is_active` - Assignment status (boolean)
- `inserted_at` - Creation timestamp

### `phoenix_kit_schema_versions` (Migration Tracking)

- Professional versioning system tracks schema changes
- Enables safe upgrades and rollbacks
- Current version: V01

## Requirements & Configuration

### Database Requirements

PhoenixKit requires **PostgreSQL** as the database adapter:

```elixir
# config/config.exs (your repository configuration)
config :your_app, YourApp.Repo,
  adapter: Ecto.Adapters.Postgres,  # Required
  # ... your database settings
```

**Supported databases:**
- ✅ PostgreSQL (required)
- ❌ MySQL, SQLite, other databases not supported

If you're using a different database, PhoenixKit migration will fail with clear error messages.

### Email Configuration

PhoenixKit requires email configuration for user registration and password reset:

#### Development Setup (Automatic)
```elixir
# config/dev.exs (automatically added by installer)
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local  # Emails shown at /dev/mailbox
```

#### Production Setup (Automatic Templates)
The installer automatically creates production mailer templates in `config/prod.exs` as comments. Simply uncomment and configure your preferred adapter:

```elixir
# Example: SMTP Configuration
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.gmail.com",
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  port: 587,
  auth: :always,
  tls: :always

# Example: SendGrid
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY")

# Example: Mailgun  
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")
```

💡 **Auto-Generated**: These examples are automatically added to your `config/prod.exs` during installation.

**⚠️ Important**: Without proper mailer configuration, user registration and password reset will fail.

## API Usage

### Getting Current User

```elixir
# In your controller or LiveView
phoenix_kit_current_user = conn.assigns[:phoenix_kit_current_user]
```

### User Operations

```elixir
# Get user by email
user = PhoenixKit.Users.Auth.get_user_by_email("user@example.com")

# Register new user
{:ok, user} = PhoenixKit.Users.Auth.register_user(%{
  email: "user@example.com",
  password: "secure_password"
})

# Authenticate user
{:ok, user} = PhoenixKit.Users.Auth.get_user_by_email_and_password(
  "user@example.com",
  "password"
)
```

### Authentication Helpers

```elixir
# In your controllers
import PhoenixKitWeb.Users.Auth

# Require authentication
plug :phoenix_kit_require_authenticated_user

# Redirect if already logged in
plug :phoenix_kit_redirect_if_user_is_authenticated
```

## PhoenixKit Scope System

PhoenixKit introduces an advanced **Scope System** for better authentication state management in your application layouts and LiveViews. This system provides structured access to authentication data with improved encapsulation and type safety.

### What is the Scope System?

The Scope system encapsulates user authentication state in a structured way, providing:

- **Better Encapsulation**: Authentication state wrapped in a dedicated struct
- **Type Safety**: Explicit functions for checking authentication status
- **Future-Ready**: Prepared for extensions like roles and permissions
- **Backward Compatibility**: Works alongside existing `phoenix_kit_current_user`

### Basic Usage

Add PhoenixKit scope to your LiveView sessions:

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # Your existing pipelines...

  # Add PhoenixKit authentication routes
  phoenix_kit_routes()

  # Your app routes with scope integration
  scope "/", YourAppWeb do
    pipe_through :browser

    # Public routes with optional authentication info
    live_session :public,
      layout: {YourAppWeb.Layouts, :app},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_scope}] do
      live "/", PageLive
      live "/about", AboutLive
    end

    # Protected routes requiring authentication
    live_session :authenticated,
      layout: {YourAppWeb.Layouts, :app},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_authenticated_scope}] do
      live "/dashboard", DashboardLive
      live "/profile", ProfileLive
    end
  end
end
```

### Using Scope in Layouts

Access authentication data in your layout templates:

```heex
<!-- lib/your_app_web/components/layouts/app.html.heex -->
<header>
  <div class="user-info">
    <%= if PhoenixKit.Users.Auth.Scope.authenticated?(@phoenix_kit_current_scope) do %>
      <div class="user-menu">
        Welcome, {PhoenixKit.Users.Auth.Scope.user_email(@phoenix_kit_current_scope)}!
        <.link href="/phoenix_kit/users/settings">Settings</.link>
        <.link href="/phoenix_kit/users/log-out" method="delete">Logout</.link>
      </div>
    <% else %>
      <div class="auth-links">
        <.link href="/phoenix_kit/users/log-in">Login</.link>
        <.link href="/phoenix_kit/users/register">Sign Up</.link>
      </div>
    <% end %>
  </div>
</header>
```

### Available Scope Functions

```elixir
# Check if user is authenticated
PhoenixKit.Users.Auth.Scope.authenticated?(@phoenix_kit_current_scope)
# => true | false

# Check if user is anonymous (not authenticated)
PhoenixKit.Users.Auth.Scope.anonymous?(@phoenix_kit_current_scope)
# => true | false

# Get user email (safe - returns nil if not authenticated)
PhoenixKit.Users.Auth.Scope.user_email(@phoenix_kit_current_scope)
# => "user@example.com" | nil

# Get user ID (safe - returns nil if not authenticated)
PhoenixKit.Users.Auth.Scope.user_id(@phoenix_kit_current_scope)
# => 123 | nil

# Get user struct (for advanced usage)
PhoenixKit.Users.Auth.Scope.user(@phoenix_kit_current_scope)
# => %PhoenixKit.Users.Auth.User{} | nil
```

### Available on_mount Callbacks

PhoenixKit provides multiple authentication levels:

#### Scope-Based Callbacks (Recommended for New Projects)

```elixir
# Mount scope - always accessible, provides authentication context
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_scope}]

# Require authentication via scope - redirects to login if not authenticated
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_authenticated_scope}]

# Redirect if authenticated - useful for login/register pages
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_redirect_if_authenticated_scope}]
```

#### Traditional User-Based Callbacks (Backward Compatibility)

```elixir
# Mount user - provides @phoenix_kit_current_user
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_user}]

# Require authentication - redirects if not authenticated
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_authenticated}]

# Redirect if authenticated
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_redirect_if_user_is_authenticated}]
```

### Migration from Traditional Approach

If you're already using `@phoenix_kit_current_user`, you can gradually migrate:

#### Step 1: Current Implementation
```elixir
# Your current working setup
live_session :default,
  layout: {YourAppWeb.Layouts, :app},
  on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_user}] do
  # ... your routes
end
```

#### Step 2: Upgrade to Scope (Backward Compatible)
```elixir
# Upgrade to scope - adds both user and scope assigns
live_session :default,
  layout: {YourAppWeb.Layouts, :app},
  on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_scope}] do
  # ... same routes, now you have access to both:
  # @phoenix_kit_current_user (continues working)
  # @phoenix_kit_current_scope (new, better structure)
end
```

#### Step 3: Update Layout Templates
```heex
<!-- Traditional approach (continues to work) -->
<%= if @phoenix_kit_current_user do %>
  <span>Welcome, {@phoenix_kit_current_user.email}!</span>
<% end %>

<!-- New scope approach (better structure) -->
<%= if PhoenixKit.Users.Auth.Scope.authenticated?(@phoenix_kit_current_scope) do %>
  <span>Welcome, {PhoenixKit.Users.Auth.Scope.user_email(@phoenix_kit_current_scope)}!</span>
<% end %>
```

### Benefits of Scope System

#### Traditional User Access
```elixir
# Direct user access - less structured
<%= if @phoenix_kit_current_user do %>
  <p>User: {@phoenix_kit_current_user.email}</p>
<% end %>
```

#### Scope-Based Access (Recommended)
```elixir
# Structured access with explicit authentication checking
<%= if PhoenixKit.Users.Auth.Scope.authenticated?(@phoenix_kit_current_scope) do %>
  <p>User: {PhoenixKit.Users.Auth.Scope.user_email(@phoenix_kit_current_scope)}</p>
<% end %>
```

**Advantages:**
- **Explicit Authentication State**: Clear `authenticated?/1` function
- **Safe Property Access**: Functions return `nil` for unauthenticated users
- **Better Encapsulation**: Authentication logic contained in dedicated module
- **Future Extensions**: Ready for roles, permissions, and additional context
- **Type Safety**: Proper struct with documented functions

### When to Use Which Approach

**Use `@phoenix_kit_current_user` when:**
- Migrating from existing Phoenix auth patterns
- You need simple, direct access to user properties
- Your app has basic authentication requirements

**Use `@phoenix_kit_current_scope` when:**
- Building new applications from scratch
- You want better code structure and type safety
- You plan to add roles or permissions later
- You prefer explicit authentication state checking

### Complete Router Example

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Add PhoenixKit authentication routes
  phoenix_kit_routes()

  scope "/", YourAppWeb do
    pipe_through :browser

    # Public routes with authentication context
    live_session :public,
      layout: {YourAppWeb.Layouts, :app},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_mount_current_scope}] do
      live "/", PageLive
      live "/about", AboutLive
      live "/pricing", PricingLive
    end

    # Protected routes
    live_session :authenticated,
      layout: {YourAppWeb.Layouts, :app},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_authenticated_scope}] do
      live "/dashboard", DashboardLive
      live "/profile", ProfileLive
    end

    # Routes that redirect authenticated users away
    live_session :redirect_if_authenticated,
      layout: {YourAppWeb.Layouts, :app},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_redirect_if_authenticated_scope}] do
      live "/welcome", WelcomeLive
    end
  end
end
```

This gives you a complete authentication system with structured access to user data in your layouts and LiveViews.

## Role-Based Access Control (RBAC)

PhoenixKit includes a comprehensive role-based access control system with three built-in system roles and a flexible API for role management.

### System Roles

PhoenixKit provides three predefined system roles:

- **Owner** - System owner with full access (automatically assigned to first user)
- **Admin** - Administrator with elevated privileges 
- **User** - Standard user with basic access (default for new users)

### Automatic Role Assignment

The first user registered in the system is automatically assigned the **Owner** role via Elixir application logic. All subsequent users receive the **User** role by default.

### Role Management API

#### Check User Roles

```elixir
# Check if user has a specific role
user = PhoenixKit.Users.Auth.get_user_by_email("user@example.com")
PhoenixKit.Users.Roles.user_has_role?(user, "Admin")
# => true | false

# Get all user roles
PhoenixKit.Users.Roles.get_user_roles(user)
# => ["Admin", "User"]

# Check specific role types
PhoenixKit.Users.Auth.User.is_owner?(user)    # => true | false
PhoenixKit.Users.Auth.User.is_admin?(user)    # => true | false (includes Owner)
```

#### Assign and Remove Roles

```elixir
# Promote user to admin
{:ok, assignment} = PhoenixKit.Users.Roles.promote_to_admin(user)

# Remove admin role (demote to regular user)
{:ok, assignment} = PhoenixKit.Users.Roles.demote_to_user(user)

# Assign specific role
{:ok, assignment} = PhoenixKit.Users.Roles.assign_role(user, "Admin", assigned_by_user)

# Remove specific role
{:ok, assignment} = PhoenixKit.Users.Roles.remove_role(user, "Admin")
```

#### User Management

```elixir
# Get users with specific role
admin_users = PhoenixKit.Users.Roles.users_with_role("Admin")

# Count users with role
admin_count = PhoenixKit.Users.Roles.count_users_with_role("Admin")

# Get role statistics for dashboard
stats = PhoenixKit.Users.Roles.get_role_stats()
# => %{total_users: 10, owner_count: 1, admin_count: 2, user_count: 7}

# Update user profile information
{:ok, user} = PhoenixKit.Users.Auth.update_user_profile(user, %{
  first_name: "John",
  last_name: "Doe"
})

# Update user active status
{:ok, user} = PhoenixKit.Users.Auth.update_user_status(user, %{is_active: false})
```

### Role-Based Authentication Hooks

PhoenixKit provides on_mount callbacks for role-based access control:

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # Add PhoenixKit authentication routes (includes admin routes)
  phoenix_kit_routes()

  scope "/", YourAppWeb do
    pipe_through :browser

    # Admin-only routes
    live_session :admin_only,
      layout: {YourAppWeb.Layouts, :admin},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_admin}] do
      live "/admin", AdminDashboardLive
      live "/admin/reports", AdminReportsLive
    end

    # Owner-only routes
    live_session :owner_only,
      layout: {YourAppWeb.Layouts, :admin},
      on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_owner}] do
      live "/system", SystemManagementLive
      live "/system/config", SystemConfigLive
    end
  end
end
```

### Available Role-Based Callbacks

#### Admin Access Control
```elixir
# Require admin or owner access
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_admin}]

# Require owner access only
on_mount: [{PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_owner}]
```

#### Controller Plugs
```elixir
# In your controllers
defmodule YourAppWeb.AdminController do
  use YourAppWeb, :controller
  import PhoenixKitWeb.Users.Auth

  # Require admin access for all actions
  plug :fetch_phoenix_kit_current_scope
  plug :require_admin

  # Or require owner access
  plug :require_owner

  # Or require specific role
  plug :require_role, "Manager"
end
```

### Role-Based Templates

Use roles in your templates with the Scope system:

```heex
<!-- Check for admin access -->
<%= if PhoenixKit.Users.Auth.Scope.is_admin?(@phoenix_kit_current_scope) do %>
  <.link navigate="/phoenix_kit/admin/dashboard" class="btn btn-primary">
    Admin Dashboard
  </.link>
<% end %>

<!-- Check for owner access -->
<%= if PhoenixKit.Users.Auth.Scope.is_owner?(@phoenix_kit_current_scope) do %>
  <.link navigate="/system/config" class="btn btn-warning">
    System Configuration
  </.link>
<% end %>

<!-- Check for specific role -->
<%= if PhoenixKit.Users.Auth.Scope.has_role?(@phoenix_kit_current_scope, "Manager") do %>
  <.link navigate="/reports" class="btn btn-info">
    View Reports
  </.link>
<% end %>

<!-- Display user's full name -->
<%= if full_name = PhoenixKit.Users.Auth.Scope.user_full_name(@phoenix_kit_current_scope) do %>
  <span class="font-medium"><%= full_name %></span>
<% else %>
  <span class="font-medium">
    <%= PhoenixKit.Users.Auth.Scope.user_email(@phoenix_kit_current_scope) %>
  </span>
<% end %>

<!-- Show all user roles -->
<div class="flex gap-2">
  <%= for role <- PhoenixKit.Users.Auth.Scope.user_roles(@phoenix_kit_current_scope) do %>
    <span class="badge badge-primary"><%= role %></span>
  <% end %>
</div>
```

### User Management Interface

PhoenixKit provides built-in admin interfaces accessible to Owner and Admin users:

#### Dashboard (`/phoenix_kit/admin/dashboard`)
- System statistics (total users, role distribution)
- Visual charts showing role breakdown
- Quick navigation to user management
- System information display

#### User Management (`/phoenix_kit/admin/users`)
- Search and filter users by email/name and role
- Paginated user listings
- Role promotion/demotion controls
- User activation/deactivation
- Protected operations (Owners cannot be demoted/deactivated)
- Bulk user statistics

### Security Features

#### Owner Protection
- Owner users cannot be deactivated or demoted
- Only one Owner exists per system (assigned to first user)
- Owner automatically has all admin privileges

#### Self-Protection
- Users cannot modify their own roles or status
- Prevents accidental account lockouts
- Admin interface clearly marks self-actions

#### Audit Trail
- All role assignments track who assigned them (`assigned_by`)
- Assignment timestamps for compliance
- Role assignment history maintained

### Creating Custom Roles

While PhoenixKit comes with three system roles, you can create custom roles:

```elixir
# Create a custom role
{:ok, role} = PhoenixKit.Users.Roles.create_role(%{
  name: "Manager",
  description: "Department manager with team oversight"
})

# Assign custom role to user
{:ok, assignment} = PhoenixKit.Users.Roles.assign_role(user, "Manager")

# Use in templates
<%= if PhoenixKit.Users.Auth.Scope.has_role?(@phoenix_kit_current_scope, "Manager") do %>
  <p>Manager-specific content</p>
<% end %>
```

### Role System Integration

The role system integrates seamlessly with PhoenixKit's Scope system:

```elixir
# In your LiveView
defmodule YourAppWeb.DashboardLive do
  use YourAppWeb, :live_view

  # Admin access required
  on_mount {PhoenixKitWeb.Users.Auth, :phoenix_kit_ensure_admin}

  def mount(_params, _session, socket) do
    scope = socket.assigns.phoenix_kit_current_scope

    # Access role information
    is_owner = PhoenixKit.Users.Auth.Scope.is_owner?(scope)
    user_roles = PhoenixKit.Users.Auth.Scope.user_roles(scope)
    full_name = PhoenixKit.Users.Auth.Scope.user_full_name(scope)

    socket = 
      socket
      |> assign(:is_owner, is_owner)
      |> assign(:user_roles, user_roles)
      |> assign(:user_full_name, full_name)

    {:ok, socket}
  end
end
```

## Architecture

PhoenixKit follows Oban's architecture principles:

- **Library-First**: No OTP application, minimal dependencies
- **Dynamic Repository**: Uses your app's Ecto repo automatically
- **Versioned Migrations**: Professional schema management with rollback support
- **Zero Dependencies**: Works with any Phoenix application
- **Production Ready**: Comprehensive error handling and logging
- **LiveView Native**: All authentication pages use Phoenix LiveView

## Migration System

PhoenixKit uses a professional versioned migration system:

```bash
# Check migration status and version information
mix phoenix_kit.update --status
```

```elixir
# Automatic version tracking
PhoenixKit.SchemaMigrations.get_installed_version(repo)
# => "1.0.0"

# Check if migration needed
PhoenixKit.SchemaMigrations.migration_required?(repo)
# => false

# Migrate to current version
PhoenixKit.SchemaMigrations.migrate_to_current(repo)
# => :ok
```

## Customization

### Custom Views and Templates

Override PhoenixKit templates by creating files in your app:

```
lib/your_app_web/templates/phoenix_kit_web/
├── user_registration/
│   └── new.html.heex
├── user_session/
│   └── new.html.heex
└── layouts/
    └── phoenix_kit.html.heex
```

### Theme System

PhoenixKit includes a comprehensive theme system with light/dark mode support, automatic system preference detection, and DaisyUI integration.

#### Quick Start

Enable the theme system in your configuration:

```elixir
# config/config.exs
config :phoenix_kit, theme_enabled: true
```

Add theme assets to your layout:

```html
<!-- In your app.html.heex or root.html.heex -->
<link rel="stylesheet" href={~p"/assets/phoenix_kit_theme.css"} />
<script defer src={~p"/assets/phoenix_kit_theme.js"}></script>
```

Add the theme switcher to your navigation:

```heex
<!-- Minimal theme switcher -->
<.theme_switcher />

<!-- Theme switcher with label -->
<.theme_switcher show_label={true} />

<!-- Custom styled theme switcher -->
<.theme_switcher class="mr-4" size="large" />
```

#### Full Configuration

Configure all theme system options:

```elixir
# config/config.exs
config :phoenix_kit,
  theme_enabled: true,
  theme: %{
    mode: :auto,                    # :light, :dark, :auto
    primary_color: "#3b82f6",      # Primary brand color
    themes: [:light, :dark],        # Available themes
    storage: :local_storage         # :local_storage, :session, :cookie
  }
```

#### Theme Modes

- **Light Mode**: Forces light theme regardless of system preference
- **Dark Mode**: Forces dark theme regardless of system preference  
- **Auto Mode**: Automatically switches based on system preference (`prefers-color-scheme`)

#### DaisyUI Integration

PhoenixKit automatically integrates with DaisyUI themes:

```css
/* Your CSS can use DaisyUI theme variables */
.custom-element {
  background-color: hsl(var(--base-100));
  color: hsl(var(--base-content));
}
```

#### Programmatic Theme Control

Use the JavaScript API for advanced theme management:

```javascript
// Switch to dark mode
window.PhoenixKitTheme.switch('dark');

// Toggle between light and dark
window.PhoenixKitTheme.toggle();

// Get current theme info
const info = window.PhoenixKitTheme.info();
console.log('Current theme:', info.current);
console.log('Effective theme:', info.effective);
```

#### Layout Integration Examples

**Root Layout Integration:**

```heex
<!DOCTYPE html>
<html lang="en" 
      {PhoenixKit.ThemeConfig.theme_data_attributes()}
      data-theme={PhoenixKit.ThemeConfig.get_theme()}
      style={PhoenixKit.ThemeConfig.modern_css_variables()}>
  <head>
    <!-- Your head content -->
    <!-- daisyUI 5 + Tailwind CSS 4 integration -->
    <link rel="stylesheet" href={~p"/assets/phoenix_kit_daisyui5.css"} />
  </head>
  <body>
    <nav class="navbar">
      <div class="navbar-end">
        <.theme_switcher size="small" />
      </div>
    </nav>
    
    <main>{@inner_content}</main>
    
    <script defer src={~p"/assets/phoenix_kit_theme.js"}></script>
  </body>
</html>
```

**URL not found**

```
ERROR: No route found for GET /phoenix_kit/register
```

Solution: Import `PhoenixKitWeb.Integration` and add `phoenix_kit_routes()`.

### Debug Logging

Enable debug logging to troubleshoot setup:

```elixir
# config/dev.exs
config :logger, level: :debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests: `mix test`
5. Run quality checks: `mix quality`
6. Submit a pull request


## License

This project is licensed under the MIT License.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

---

Built with ❤️ for the Phoenix community

