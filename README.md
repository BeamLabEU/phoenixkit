# PhoenixKit

> Professional authentication library for Phoenix applications with zero-config setup

<!-- [![Hex.pm](https://img.shields.io/hexpm/v/phoenix_kit.svg)](https://hex.pm/packages/phoenix_kit)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/phoenix_kit)
[![License](https://img.shields.io/hexpm/l/phoenix_kit.svg)](LICENSE) -->

## Overview

PhoenixKit is a production-ready authentication library for Phoenix applications, built with Oban-style architecture for seamless integration. It provides complete user authentication with registration, login, email confirmation, password reset, and session management.

### Key Features

- 🚀 **Zero-Config Setup** - Automatic repository detection and configuration
- 🗄️ **Professional Database Management** - Versioned migrations with Oban-style architecture
- 🔐 **Complete Authentication** - Registration, login, logout, email confirmation, password reset
- 🎯 **Library-First Design** - No OTP application, integrates into any Phoenix app
- 📦 **Production Ready** - Comprehensive error handling and logging
- 🛠️ **Developer Friendly** - Single command installation with automatic setup
- 🎨 **LiveView Ready** - All authentication pages use Phoenix LiveView

## Installation

PhoenixKit provides multiple installation methods to suit different project needs and developer preferences.

### Semi-Automatic Installation

**Recommended for most projects**

Add both `phoenix_kit` and `igniter` to your project dependencies:

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"},
    {:igniter, "~> 0.6.0", only: [:dev]}
  ]
end
```

Then run the PhoenixKit installer:

```bash
mix deps.get
mix phx.kit.install.igniter
```

This will automatically:

- ✅ Auto-detect your Ecto repository
- ✅ Generate migration files for authentication tables
- ✅ Add PhoenixKit configuration to `config/config.exs`
- ✅ Configure mailer settings for development
- ✅ Add authentication routes to your router
- ✅ Provide detailed setup instructions

**Optional parameters:**

```bash
# Specify custom repository
mix phx.kit.install.igniter --repo MyApp.Repo

# Use PostgreSQL schema prefix for table isolation
mix phx.kit.install.igniter --prefix "auth" --create-schema

# Specify custom router file path
mix phx.kit.install.igniter --router-path lib/my_app_web/router.ex
```

### Igniter Installation

**Single command installation**

For the simplest possible setup, use Igniter's package installation:

```bash
mix igniter.install phoenix_kit
```

Optional repository specification:

```bash
mix igniter.install phoenix_kit --repo MyApp.Repo
```

### Manual Installation

**For maximum control**

1. **Add dependency:**

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
  ]
end
```

2. **Install dependency:**

```bash
mix deps.get
```

3. **Generate migration:**

```bash
mix phx.kit.gen.migration add_phoenix_kit_auth_tables
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

- `http://localhost:4000/phoenix_kit/register` - User registration
- `http://localhost:4000/phoenix_kit/login` - User login

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
mix phx.kit.install.igniter --prefix "auth" --create-schema
```

This creates tables as:

- `auth.phoenix_kit_users`
- `auth.phoenix_kit_users_tokens`

### Custom Repository

Specify a different Ecto repository:

```bash
# Use custom repository
mix phx.kit.install.igniter --repo MyApp.CustomRepo
```

### Multiple Ecto Repositories

If you have multiple repos, PhoenixKit will auto-detect the first one, or specify explicitly:

```elixir
# config/config.exs
config :phoenix_kit,
  repo: MyApp.AuthRepo  # Use specific repo for auth
```

## Configuration

PhoenixKit uses your application's repository:

```elixir
# config/config.exs (automatically added by igniter installation)
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
```

## Authentication Routes

PhoenixKit provides these LiveView routes under your chosen prefix:

- `GET /phoenix_kit/register` - User registration form (LiveView)
- `GET /phoenix_kit/log_in` - Login form (LiveView)
- `POST /phoenix_kit/log_in` - User login
- `DELETE /phoenix_kit/log_out` - User logout
- `GET /phoenix_kit/log_out` - User logout (direct URL access)
- `GET /phoenix_kit/reset_password` - Password reset request (LiveView)
- `GET /phoenix_kit/reset_password/:token` - Password reset form (LiveView)
- `GET /phoenix_kit/settings` - User settings (LiveView, requires login)
- `GET /phoenix_kit/settings/confirm_email/:token` - Email confirmation
- `GET /phoenix_kit/confirm/:token` - Account confirmation (LiveView)
- `GET /phoenix_kit/confirm` - Resend confirmation (LiveView)

## Database Schema

PhoenixKit creates these tables:

### `phoenix_kit_users` (Users)

- `id` - Primary key (bigserial)
- `email` - Email address (citext, unique)
- `hashed_password` - Bcrypt hashed password
- `confirmed_at` - Email confirmation timestamp
- `inserted_at`, `updated_at` - Timestamps

### `phoenix_kit_users_tokens` (Authentication Tokens)

- `id` - Primary key (bigserial)
- `user_id` - Foreign key to phoenix_kit_users
- `token` - Secure token (bytea)
- `context` - Token type (session, email, reset)
- `sent_to` - Email address for email tokens
- `inserted_at` - Creation timestamp

### `phoenix_kit_schema_versions` (Migration Tracking)

- Professional versioning system tracks schema changes
- Enables safe upgrades and rollbacks
- Current version: 1.0.0

## API Usage

### Getting Current User

```elixir
# In your controller or LiveView
current_user = conn.assigns[:current_user]
```

### User Operations

```elixir
# Get user by email
user = PhoenixKit.Accounts.get_user_by_email("user@example.com")

# Register new user
{:ok, user} = PhoenixKit.Accounts.register_user(%{
  email: "user@example.com",
  password: "secure_password"
})

# Authenticate user
{:ok, user} = PhoenixKit.Accounts.get_user_by_email_and_password(
  "user@example.com",
  "password"
)
```

### Authentication Helpers

```elixir
# In your controllers
import PhoenixKitWeb.UserAuth

# Require authentication
plug :phoenix_kit_require_authenticated_user

# Redirect if already logged in
plug :phoenix_kit_redirect_if_user_is_authenticated
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
mix phx.kit.migrate --status
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

## Troubleshooting

### Common Issues

**No repository configured**

```
ERROR: No repository configured for PhoenixKit
```

Solution: Run `mix phx.kit.install --repo MyApp.Repo` or manually add config.

**--repo parameter required**

```
ERROR: --repo is required!
```

Solution: Always specify `--repo` parameter: `mix phx.kit.install --repo MyApp.Repo`

**Migration errors**

```
ERROR: Schema migration failed
ERROR: could not find migration runner process
```

Solution: Check database connection and permissions. Auto-setup migration system has been improved in v0.1.7+ to handle runtime migration contexts correctly.

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

## Upgrade Guide

### From 0.1.x to 0.2.x

PhoenixKit will automatically detect and run schema migrations. No manual intervention required.

**Important:** Table names have been updated from `phoenix_kit`/`phoenix_kit_tokens` to `phoenix_kit_users`/`phoenix_kit_users_tokens`. Fresh installations will use the new names automatically.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

---

Built with ❤️ for the Phoenix community
