# PhoenixKit

> Professional authentication library for Phoenix applications with zero-config setup

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_kit.svg)](https://hex.pm/packages/phoenix_kit)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/phoenix_kit)
[![License](https://img.shields.io/hexpm/l/phoenix_kit.svg)](LICENSE)

## Overview

PhoenixKit is a production-ready authentication library for Phoenix applications, built with Oban-style architecture for seamless integration. It provides complete user authentication with registration, login, email confirmation, password reset, and session management.

### Key Features

- 🚀 **Zero-Config Setup** - Automatic repository detection and configuration
- 🗄️ **Professional Database Management** - Versioned migrations with Oban-style architecture  
- 🔐 **Complete Authentication** - Registration, login, logout, email confirmation, password reset
- 🎯 **Library-First Design** - No OTP application, integrates into any Phoenix app
- 📦 **Production Ready** - Comprehensive error handling and logging
- 🛠️ **Developer Friendly** - Single command installation with automatic setup

## Quick Start

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, "~> 0.1.5"}
  ]
end
```

### 2. Install PhoenixKit

```bash
mix deps.get
mix phoenix_kit.install
```

This automatically:
- Detects your Ecto repository
- Generates migration files
- Adds configuration to `config/config.exs`
- Provides next steps

### 3. Add Routes

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration
  import PhoenixKitWeb.UserAuth

  pipeline :browser do
    # ... your existing plugs ...
    plug :fetch_current_user  # Add PhoenixKit user fetching
  end

  # Add PhoenixKit authentication routes
  phoenix_kit_auth_routes("/auth")
end
```

### 4. Run Migration

```bash
mix ecto.migrate
```

### 5. Start Your App

```bash
mix phx.server
```

Visit `http://localhost:4000/auth/register` to see PhoenixKit in action!

## Advanced Installation

### Custom Repository

```bash
mix phoenix_kit.install --repo MyApp.CustomRepo
```

### Custom URL Prefix

```elixir
# In your router
phoenix_kit_auth_routes("/authentication")
```

### PostgreSQL Schema Prefix

```bash
mix phoenix_kit.install --prefix "auth" --create-schema
```

## Configuration

PhoenixKit uses your application's repository automatically:

```elixir
# config/config.exs (automatically added by mix phoenix_kit.install)
config :phoenix_kit, repo: YourApp.Repo
```

### Advanced Configuration

```elixir
config :phoenix_kit,
  repo: YourApp.Repo,
  # Optional: Custom mailer for sending emails
  mailer: YourApp.Mailer
```

## Authentication Routes

PhoenixKit provides these routes under your chosen prefix:

- `GET /register` - User registration form
- `POST /register` - Create new user account  
- `GET /log_in` - Login form
- `POST /log_in` - User login
- `DELETE /log_out` - User logout
- `GET /reset_password` - Password reset request
- `GET /reset_password/:token` - Password reset form
- `GET /settings` - User settings (requires login)
- `GET /confirm/:token` - Email confirmation

## Database Schema

PhoenixKit creates these tables:

### `phoenix_kit` (Users)
- `id` - Primary key (bigserial)
- `email` - Email address (citext, unique)
- `hashed_password` - Bcrypt hashed password
- `confirmed_at` - Email confirmation timestamp
- `inserted_at`, `updated_at` - Timestamps

### `phoenix_kit_tokens` (Authentication Tokens)
- `id` - Primary key (bigserial)
- `user_id` - Foreign key to users
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
plug :require_authenticated_user

# Redirect if already logged in  
plug :redirect_if_user_is_authenticated
```

## Architecture

PhoenixKit follows Oban's architecture principles:

- **Library-First**: No OTP application, minimal dependencies
- **Dynamic Repository**: Uses your app's Ecto repo automatically
- **Versioned Migrations**: Professional schema management with rollback support
- **Zero Dependencies**: Works with any Phoenix application
- **Production Ready**: Comprehensive error handling and logging

## Migration System

PhoenixKit uses a professional versioned migration system:

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

### Custom Styling

PhoenixKit uses semantic HTML classes for easy styling:

```css
.phoenix-kit-form { /* Registration/login forms */ }
.phoenix-kit-button { /* Submit buttons */ }
.phoenix-kit-input { /* Form inputs */ }
.phoenix-kit-error { /* Error messages */ }
```

## Troubleshooting

### Common Issues

**No repository configured**
```
ERROR: No repository configured for PhoenixKit
```
Solution: Run `mix phoenix_kit.install` or manually add config.

**Migration errors**
```
ERROR: Schema migration failed
```
Solution: Check database connection and permissions.

**URL not found**
```
ERROR: No route found for GET /auth/register
```
Solution: Import `PhoenixKitWeb.Integration` and add `phoenix_kit_auth_routes/1`.

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

---

Built with ❤️ for the Phoenix community