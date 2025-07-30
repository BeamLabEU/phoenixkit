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

## Quick Start

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
    # Or when published to Hex:
    # {:phoenix_kit, "~> 0.1.5"}
  ]
end
```

### 2. Install PhoenixKit

PhoenixKit provides **three installation methods** for different use cases:

#### 🔥 **Professional Igniter Installation** (Recommended)

For the most seamless installation experience, use our Igniter-powered installer with **advanced automation**:

```elixir
# Add to your mix.exs dependencies
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"},
    {:igniter, "~> 0.6.0", only: [:dev]}  # Required for professional installer
  ]
end
```

```bash
mix deps.get
mix phoenix_kit.install.pro
```

**✨ What the Professional Installer Does:**

**🔧 Core Setup:**
- 🤖 **Auto-detects your Ecto repository** - no manual repo specification needed
- 📝 **Automatically modifies config/config.exs** - adds PhoenixKit configuration
- 🧪 **Automatically configures config/test.exs** - sets up test-specific settings  
- 📄 **Updates .formatter.exs** - adds PhoenixKit to import_deps for proper formatting
- 🗄️ **Creates database migration** - using Ecto-native `Igniter.Libs.Ecto.gen_migration`
- 📧 **Configures mailer** - sets up Swoosh adapter for emails

**🚀 NEW: Advanced Automation Features:**
- 🔍 **Comprehensive Conflict Detection** - analyzes dependencies, configuration, and code for conflicts
- 🛡️ **Automatic Conflict Resolution** - resolves common conflicts automatically
- 🎯 **Intelligent Router Integration** - automatically adds routes and imports to your router.ex
- 🎨 **Layout Integration System** - seamlessly integrates with your existing layouts
- ✨ **Layout Enhancement** - improves your layouts with PhoenixKit-specific features
- 🛠️ **Fallback Configuration** - creates robust fallback systems for layouts
- ⚙️ **Professional error handling** - actionable error messages with solution steps

**Advanced Options:**
```bash
# Fully automated setup with routes (RECOMMENDED)
mix phoenix_kit.install.pro --add-routes

# Custom PostgreSQL schema prefix
mix phoenix_kit.install.pro --prefix "auth"

# Specific repository  
mix phoenix_kit.install.pro --repo MyApp.CustomRepo

# Custom layout integration
mix phoenix_kit.install.pro --layout "MyAppWeb.Layouts.auth"

# Enhanced layout integration with automatic improvements
mix phoenix_kit.install.pro --enhance-layouts

# Disable automatic router modification (manual setup required)
mix phoenix_kit.install.pro --no-add-routes

# Disable conflict auto-resolution (for advanced users)
mix phoenix_kit.install.pro --no-auto-resolve-conflicts
```

#### 🛠️ **Traditional Installation**

If you prefer the traditional approach or don't want Igniter:

```bash
mix deps.get
mix phoenix_kit.install --repo MyApp.Repo
```

**Note:** The `--repo` parameter is **required** for traditional installation.

#### 🎯 **Basic Igniter Installation**

For users already familiar with the basic Igniter approach:

```bash
mix phoenix_kit.install.igniter --repo MyApp.Repo
```

### 📊 **Installation Comparison**

| Feature | Traditional | Basic Igniter | **Professional Igniter** |
|---------|-------------|---------------|--------------------------|
| Repository Detection | Manual `--repo` required | Manual `--repo` required | ✅ **Automatic detection** |
| Configuration | Manual setup required | Shows notices | ✅ **Automatic modification** |
| Test Configuration | Manual setup | Not included | ✅ **Automatic test.exs setup** |
| Formatter Integration | Manual | Not included | ✅ **Automatic .formatter.exs** |
| Migration Creation | Manual file creation | Basic file creation | ✅ **Ecto-native generation** |
| **Router Integration** | ❌ **Manual import/routes** | ❌ **Manual import/routes** | ✅ **Automatic AST modification** |
| **Conflict Detection** | ❌ **No analysis** | ❌ **No analysis** | ✅ **Comprehensive analysis** |
| **Layout Integration** | ❌ **No integration** | ❌ **No integration** | ✅ **Automatic enhancement** |
| **Fallback Systems** | ❌ **Manual setup** | ❌ **Manual setup** | ✅ **Automatic configuration** |
| Error Handling | Basic Mix errors | Basic notices | ✅ **Professional guidance** |
| User Experience | Multiple manual steps | Some automation | ✅ **Fully automated** |

**🎯 Recommendation:** Use `mix phoenix_kit.install.pro --add-routes` for the ultimate zero-config experience!

### 3. Run Migration & Final Setup

```bash
# Run database migration
mix ecto.migrate
```

#### Manual Configuration (if not using Professional Installer)

If you used traditional installation, add to your `config/config.exs`:

```elixir
# Required: Configure PhoenixKit repository
config :phoenix_kit,
  repo: MyApp.Repo

# Required: Configure PhoenixKit Mailer for email delivery  
config :phoenix_kit, PhoenixKit.Mailer, adapter: Swoosh.Adapters.Local
```

**⚠️ Note:** The Professional Installer handles all configuration automatically!

#### Production Mailer Configuration

For production environments, configure a real email adapter:
```elixir
# Production example with SMTP
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "smtp.gmail.com",
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD")
```

### 4. Add Routes

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # Your existing pipelines...
  pipeline :browser do
    # ... your existing plugs ...
  end

  # Add PhoenixKit authentication routes - they work independently!
  phoenix_kit_auth_routes()  # Default prefix: /phoenix_kit
end
```

### 5. Run Migration

```bash
mix ecto.migrate
```

### 6. Start Your App

```bash
mix phx.server
```

Visit `http://localhost:4000/phoenix_kit/register` to see PhoenixKit in action!

## Advanced Installation

### Custom Repository

```bash
mix phoenix_kit.install --repo MyApp.CustomRepo
```

### Custom URL Prefix

```elixir
# In your router - NOT recommended to use /auth prefix
phoenix_kit_auth_routes("/authentication")
phoenix_kit_auth_routes("/users")
```

**Note:** We don't recommend using `/auth` as the prefix.

## Advanced Configuration Options

### 🚀 **Professional Installer Advanced Features**

The Professional Igniter installer includes cutting-edge automation features:

#### 🔍 **Comprehensive Conflict Detection**
Automatically analyzes your project for potential conflicts:
- **Dependency Analysis** - scans 60+ packages for authentication library conflicts
- **Configuration Analysis** - detects existing auth configurations (Pow, Guardian, etc.)
- **Code Analysis** - finds existing user schemas and authentication functions
- **Migration Strategy** - generates personalized migration recommendations

```bash
# Example output during installation:
# 🔍 Conflict Detection Complete
# - Total conflicts: 2
# - Critical conflicts: 0  
# - Overall risk: low
# - Safe to proceed: true
```

#### 🎯 **Intelligent Router Integration**
Automatically modifies your `router.ex` using AST manipulation:
- **Import Injection** - adds `import PhoenixKitWeb.Integration` automatically
- **Route Injection** - places `phoenix_kit_auth_routes()` in optimal location
- **Conflict Resolution** - handles existing route conflicts intelligently
- **Validation** - ensures successful integration with comprehensive checks

```elixir
# BEFORE (manual):
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  # Your existing routes...
end

# AFTER (automatic with --add-routes):
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import PhoenixKitWeb.Integration  # ← Added automatically

  # Your existing routes...
  
  # PhoenixKit Authentication Routes (auto-generated)
  phoenix_kit_auth_routes()  # ← Added automatically
end
```

#### 🎨 **Advanced Layout Integration System**
Seamlessly integrates with your existing Phoenix layouts:
- **Layout Detection** - automatically finds your app's layout files
- **Compatibility Analysis** - assesses integration complexity
- **Layout Enhancement** - improves layouts with PhoenixKit features
- **Fallback Configuration** - creates robust fallback systems

```bash
# Example with enhanced layout integration:
mix phoenix_kit.install.pro --enhance-layouts

# Output:
# 🎨 Layout Integration Complete!
# - Strategy: enhance_existing_layouts
# - Enhanced files: 2
# - Applied enhancements: 4
# - Fallbacks created: true
```

#### 🛠️ **Automatic Fallback Configuration**
Creates robust fallback systems for maximum reliability:
- **Fallback Layouts** - automatic creation when needed
- **Configuration Validation** - ensures layouts exist and are accessible
- **Graceful Degradation** - handles missing layouts elegantly
- **Production Safety** - prevents layout-related crashes

### 🗄️ **PostgreSQL Schema Prefix** 

PhoenixKit supports database schema isolation for multi-tenant applications:

```bash
# Professional Installer (Recommended)
mix phoenix_kit.install.pro --prefix "auth" 

# Traditional approach
mix phoenix_kit.install --repo MyApp.Repo --prefix "auth" --create-schema
```

This creates authentication tables in a separate PostgreSQL schema:
- Tables: `auth.users`, `auth.users_tokens` 
- Benefits: Isolation, security, multi-tenant support
- Automatic schema creation if it doesn't exist

### 🎨 **Layout Integration**

Integrate PhoenixKit with your application's design:

```bash
# Professional Installer with custom layout
mix phoenix_kit.install.pro --layout "MyAppWeb.Layouts.auth"
```

Or configure manually in `config/config.exs`:
```elixir
config :phoenix_kit,
  layout: {MyAppWeb.Layouts, :app},        # Use your app's main layout
  root_layout: {MyAppWeb.Layouts, :root},  # Optional: custom root layout  
  page_title_prefix: "Auth"                # Optional: page title prefix
```

### ⚙️ **Complete Configuration Reference**

```elixir
# config/config.exs - Professional Installer handles this automatically
config :phoenix_kit,
  repo: MyApp.Repo,                        # Ecto repository
  prefix: "auth",                          # Optional: PostgreSQL schema
  layout: {MyAppWeb.Layouts, :app},        # Optional: custom layout
  root_layout: {MyAppWeb.Layouts, :root},  # Optional: root layout
  page_title_prefix: "Authentication"     # Optional: title prefix

# Mailer configuration - also handled automatically
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local           # Development
  # adapter: Swoosh.Adapters.SMTP          # Production

# Test-specific configuration (added automatically by Professional Installer)
# config/test.exs
config :phoenix_kit,
  repo: MyApp.Repo,
  prefix: "auth", 
  async: true                              # Enable async testing
```

**💡 Pro Tip:** Use `mix phoenix_kit.install.pro` to handle all configuration automatically!

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
mix phoenix_kit.migrate --status
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

### 🔥 Igniter Installation Issues

**Igniter not available**
```bash
ERROR: The task 'phoenix_kit.install.pro' requires Igniter
```
**Solution:** Add Igniter to your dependencies:
```elixir
# mix.exs
{:igniter, "~> 0.6.0", only: [:dev]}
```
Then run `mix deps.get`

**Repository auto-detection failed**
```bash
ERROR: No Ecto repos found for :my_app
```
**Solution:** Either:
1. Ensure Ecto is configured: `config :my_app, ecto_repos: [MyApp.Repo]`  
2. Use explicit repo: `mix phoenix_kit.install.pro --repo MyApp.Repo`

**Configuration conflicts**
```bash  
NOTICE: Configuration already exists and was merged
```
**Solution:** This is normal! The Professional Installer safely merges configurations. Check your `config/config.exs` for the updated PhoenixKit section.

**Migration generation failed**
```bash
ERROR: Could not generate migration  
```
**Solution:** Ensure you have write permissions to `priv/repo/migrations/` directory.

### 🛠️ Traditional Installation Issues

**No repository configured**
```
ERROR: No repository configured for PhoenixKit
```
Solution: Run `mix phoenix_kit.install --repo MyApp.Repo` or manually add config.

**--repo parameter required**
```
ERROR: --repo is required!
```
Solution: Always specify `--repo` parameter: `mix phoenix_kit.install --repo MyApp.Repo`

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
Solution: Import `PhoenixKitWeb.Integration` and add `phoenix_kit_auth_routes()`.

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

## 🚀 Installation Examples & Best Practices

### Quick Start for New Projects

```bash
# 1. Create new Phoenix project
mix phx.new my_app --no-live
cd my_app

# 2. Add PhoenixKit with Igniter support
# Add to mix.exs dependencies:
{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
{:igniter, "~> 0.6.0", only: [:dev]}

# 3. Install dependencies and run professional installer
mix deps.get
mix phoenix_kit.install.pro

# 4. Run migration and start server
mix ecto.migrate
mix phx.server
```

### Enterprise Setup with Schema Isolation

```bash
# For multi-tenant or enterprise applications
mix phoenix_kit.install.pro --prefix "auth" --layout "MyAppWeb.Layouts.enterprise"
```

This creates:
- Tables: `auth.users`, `auth.users_tokens`
- Custom layout integration
- Automatic test configuration
- Professional error handling

### Migration Path from Traditional to Professional

If you're using the traditional installer, you can upgrade:

```bash
# 1. Add Igniter to your dependencies
# 2. Run the professional installer (safe - merges existing config)
mix phoenix_kit.install.pro

# 3. Review the updated configuration files
# 4. Remove any duplicate manual configuration
```

### Recommended Production Configuration

```elixir
# config/prod.exs
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("SMTP_RELAY"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  port: 587,
  tls: :always,
  auth: :always

# Optional: Custom layout for branded experience
config :phoenix_kit,
  layout: {MyAppWeb.Layouts, :auth},
  page_title_prefix: "Authentication"
```

## 🎯 Why Choose PhoenixKit?

- **🏆 Professional Grade:** Built with Oban-style architecture and modern best practices
- **🚀 Next-Gen Automation:** Advanced Professional Installer with conflict detection, router integration, and layout enhancement  
- **⚡ True Zero Config:** Automatic repository detection, configuration, and router setup
- **🔒 Battle Tested:** Complete authentication flow with email confirmation
- **🎨 Design Flexible:** Intelligent layout integration with automatic enhancement and fallback systems
- **🛡️ Conflict Aware:** Comprehensive analysis and automatic resolution of authentication library conflicts
- **📦 Production Ready:** Used in production Phoenix applications with robust error handling
- **🛠️ Developer Friendly:** Best-in-class error messages, troubleshooting, and professional installation experience

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

---

Built with ❤️ for the Phoenix community