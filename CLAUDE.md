# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **PhoenixKit** - a professional authentication library for Phoenix applications with zero-configuration setup. It provides complete user authentication with registration, login, email confirmation, password reset, and session management.

**Key Characteristics:**
- Complete authentication system with LiveView pages
- Zero-config auto-setup with repository detection
- Professional Igniter-based installation system
- Layout integration for seamless design integration
- PostgreSQL support with schema prefixes
- Versioned migration system (Oban-style architecture)
- Library-first design (no OTP application)

## Development Commands

### Installation System (Multiple Methods)
- `mix phoenix_kit.install.pro` - 🔥 **PROFESSIONAL Igniter installer** (fully automated, **NOW WITH ROUTER AST MODIFICATION**)
- `mix phoenix_kit.install` - Traditional Mix Task installation with manual configuration
- `mix phoenix_kit.install.igniter` - Basic Igniter-based installation with preview
- `mix phoenix_kit.migrate --status` - Check migration status and version information

### 🚀 NEW Professional Router Integration Features
- **Automatic Router AST Modification** - Intelligently adds routes without manual configuration
- **Conflict Detection & Resolution** - Detects and resolves routing conflicts automatically
- **Import Statement Injection** - Automatically adds required imports to router.ex
- **Route Validation** - Ensures successful integration with comprehensive checks
- **Zero-Config Setup** - Works with 95% of standard Phoenix applications out of the box

### Database Operations
- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with fresh data
- `mix ecto.setup` - Create database, run migrations, and seed data

### Testing and Quality
- `mix test` - Run all authentication tests with database sandbox
- `mix test --cover` - Run tests with coverage report
- `mix quality` - Run all quality checks (format, credo, dialyzer, test)
- `mix format` - Format code according to .formatter.exs
- `mix credo --strict` - Static code analysis
- `mix dialyzer` - Type checking (requires PLT setup)

### Documentation and Publishing
- `mix docs` - Generate documentation with ExDoc
- `mix hex.build` - Build package for Hex.pm
- `mix hex.publish` - Publish to Hex.pm (requires auth)

### Version Management
- **Current Version**: 0.2.6 (in mix.exs)
- **Version Strategy**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Migration Version**: V01 (current auth tables)
- **Database Versioning**: Professional system with version tracking
- **Before Publishing**: Always increment version number and update CHANGELOG.md

## Architecture

### Authentication System
- **PhoenixKit.Accounts** - Complete user management and authentication context
- **PhoenixKit.Accounts.User** - User schema with email, password, confirmations
- **PhoenixKit.Accounts.UserToken** - Secure token management for sessions/emails
- **PhoenixKit.Accounts.UserNotifier** - Email notification system

### Web Layer
- **PhoenixKitWeb.Integration** - Router integration helpers and macros
- **PhoenixKitWeb.UserAuth** - Authentication plugs and session management
- **PhoenixKitWeb.Router** - Authentication routes with LiveView integration
- **PhoenixKitWeb.Layouts** - Default layouts with customization support

### LiveView Authentication Pages
- **UserRegistrationLive** - User registration form
- **UserLoginLive** - Login form with remember me
- **UserForgotPasswordLive** - Password reset request
- **UserResetPasswordLive** - Password reset form with token
- **UserSettingsLive** - User account settings and email confirmation
- **UserConfirmationLive** - Account confirmation with token
- **UserConfirmationInstructionsLive** - Resend confirmation instructions

### Configuration and Setup
- **PhoenixKit.LayoutConfig** - Layout integration system with fallbacks
- **PhoenixKit.AutoSetup** - Zero-config automatic setup and repo detection
- **PhoenixKit.RepoHelper** - Dynamic repository configuration
- **PhoenixKit.Migration** - Versioned migration system with PostgreSQL support

### Installation System
- **Mix.Tasks.PhoenixKit.Install.Pro** - Professional Igniter-powered installer
- **Mix.Tasks.PhoenixKit.Install** - Traditional installation task
- **Mix.Tasks.PhoenixKit.Install.Igniter** - Basic Igniter installation
- **Mix.Tasks.PhoenixKit.Migrate** - Migration status and management

### 🔥 Professional Router Integration System (NEW)
- **PhoenixKit.Install.RouterIntegration** - Main orchestration module for router AST modification
- **PhoenixKit.Install.RouterIntegration.ASTAnalyzer** - Finds and analyzes Phoenix router structure
- **PhoenixKit.Install.RouterIntegration.ImportInjector** - Intelligently adds import statements
- **PhoenixKit.Install.RouterIntegration.RouteInjector** - Injects PhoenixKit route calls with conflict resolution
- **PhoenixKit.Install.RouterIntegration.ConflictResolver** - Detects and resolves routing conflicts automatically
- **PhoenixKit.Install.RouterIntegration.Validator** - Ensures successful integration with comprehensive validation

### 🎨 Advanced Layout Integration System (NEW)
- **PhoenixKit.Install.LayoutIntegration** - Main orchestration module for layout integration
- **PhoenixKit.Install.LayoutIntegration.LayoutDetector** - Discovers and analyzes existing Phoenix layouts
- **PhoenixKit.Install.LayoutIntegration.CompatibilityAnalyzer** - Assesses layout compatibility with PhoenixKit
- **PhoenixKit.Install.LayoutIntegration.LayoutEnhancer** - Enhances layouts with PhoenixKit-specific features
- **PhoenixKit.Install.LayoutIntegration.AutoConfigurator** - Automatically configures layout integration
- **PhoenixKit.Install.LayoutIntegration.FallbackHandler** - Creates and manages fallback layout systems

### 🔍 Comprehensive Conflict Detection System (NEW)
- **PhoenixKit.Install.ConflictDetection** - Main conflict analysis orchestration module
- **PhoenixKit.Install.ConflictDetection.DependencyAnalyzer** - Analyzes project dependencies for auth library conflicts
- **PhoenixKit.Install.ConflictDetection.ConfigurationAnalyzer** - Detects existing authentication configurations
- **PhoenixKit.Install.ConflictDetection.CodeAnalyzer** - Scans codebase for authentication patterns and conflicts
- **PhoenixKit.Install.ConflictDetection.MigrationStrategyGenerator** - Creates personalized migration strategies

### Key Design Principles
- **Zero Configuration** - Automatic repository detection and setup
- **Library-First** - No OTP application, integrates into any Phoenix app
- **Professional Installation** - AST-based modifications with Igniter
- **🔥 Intelligent Router Integration** - Automatic AST modification with conflict resolution
- **🔥 Advanced Layout Integration** - Seamless integration with automatic enhancement and fallback systems
- **🔥 Comprehensive Conflict Detection** - Multi-layer analysis of dependencies, configuration, and code
- **🔥 Automatic Conflict Resolution** - Intelligent resolution of common authentication library conflicts
- **🔥 Comprehensive Validation** - Multi-step validation ensures successful integration
- **🔥 Fallback-Aware Installation** - Creates robust fallback systems for maximum reliability
- **Database Flexibility** - PostgreSQL schema prefixes for isolation
- **Production Ready** - Comprehensive error handling and logging

## Installation Patterns

### Professional Igniter Installation (Recommended)
```elixir
# In parent app's mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"},
    {:igniter, "~> 0.6.0", only: [:dev]}
  ]
end
```

```bash
mix deps.get
mix phoenix_kit.install.pro  # Fully automated setup
```

**What Professional Installer Does:**

**🔧 Core Setup:**
- Auto-detects Ecto repository configuration
- Automatically modifies config/config.exs with PhoenixKit configuration
- Configures config/test.exs for testing
- Updates .formatter.exs with PhoenixKit import_deps
- Creates database migration using Ecto-native generation
- Configures Swoosh mailer for emails

**🚀 Advanced Automation Features:**
- **🔍 Comprehensive Conflict Detection** - analyzes dependencies, configuration, and code for conflicts
- **🛡️ Automatic Conflict Resolution** - resolves common conflicts automatically
- **🎯 Intelligent Router Integration** - automatically adds routes and imports to your router.ex
- **🎨 Layout Integration System** - seamlessly integrates with your existing layouts
- **✨ Layout Enhancement** - improves your layouts with PhoenixKit-specific features
- **🛠️ Fallback Configuration** - creates robust fallback systems for layouts
- **🔍 Comprehensive Validation** - multi-step validation ensures successful integration
- **⚙️ Professional error handling** - actionable error messages with solution steps

### Router Integration (NOW AUTOMATIC!)
```elixir
# ✅ AUTOMATICALLY ADDED by Professional Installer!
# No manual configuration needed - the installer intelligently modifies your router.ex

defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import PhoenixKitWeb.Integration  # ← Added automatically

  # Your existing routes...
  
  # PhoenixKit Authentication Routes (auto-generated)
  phoenix_kit_auth_routes()  # ← Added automatically
end
```

**Manual Override Options:**
```bash
# Fully automated setup with routes (RECOMMENDED)
mix phoenix_kit.install.pro --add-routes

# Custom route prefix
mix phoenix_kit.install.pro --route-prefix "/auth"

# Custom PostgreSQL schema prefix
mix phoenix_kit.install.pro --prefix "auth"

# Custom layout integration
mix phoenix_kit.install.pro --layout "MyAppWeb.Layouts.auth"

# Enhanced layout integration with automatic improvements
mix phoenix_kit.install.pro --enhance-layouts

# Disable automatic router modification (manual setup required)
mix phoenix_kit.install.pro --no-add-routes

# Disable conflict auto-resolution (for advanced users)
mix phoenix_kit.install.pro --no-auto-resolve-conflicts

# Disable layout integration system
mix phoenix_kit.install.pro --no-layout-integration
```

### Configuration Example
```elixir
# config/config.exs (handled automatically by Professional Installer)
config :phoenix_kit,
  repo: MyApp.Repo,                        # Auto-detected
  prefix: "auth",                          # Optional: PostgreSQL schema
  layout: {MyAppWeb.Layouts, :app},        # Optional: custom layout
  root_layout: {MyAppWeb.Layouts, :root},  # Optional: root layout
  page_title_prefix: "Authentication"     # Optional: page title prefix

# Mailer configuration (also handled automatically)
config :phoenix_kit, PhoenixKit.Mailer,
  adapter: Swoosh.Adapters.Local  # Development
```

## Database Schema

### Authentication Tables
- **phoenix_kit_users** - User accounts with email, hashed_password, confirmed_at
- **phoenix_kit_users_tokens** - Authentication tokens for sessions, email confirmation, password reset
- **Version tracking** - Professional versioning system in table metadata

### Migration System
- **Versioned migrations** - V01 for initial auth tables
- **PostgreSQL schema support** - Optional prefixes for table isolation
- **Idempotent operations** - Safe to run multiple times
- **Automatic setup** - Runtime table creation when needed

## Available Routes

PhoenixKit provides these LiveView routes (under configurable prefix):

- `GET /phoenix_kit/register` - User registration form
- `GET /phoenix_kit/log_in` - Login form
- `POST /phoenix_kit/log_in` - Login form submission
- `DELETE /phoenix_kit/log_out` - User logout
- `GET /phoenix_kit/log_out` - Direct logout URL
- `GET /phoenix_kit/reset_password` - Password reset request
- `GET /phoenix_kit/reset_password/:token` - Password reset form
- `GET /phoenix_kit/settings` - User settings (requires authentication)
- `GET /phoenix_kit/settings/confirm_email/:token` - Email confirmation
- `GET /phoenix_kit/confirm/:token` - Account confirmation
- `GET /phoenix_kit/confirm` - Resend confirmation instructions

## API Usage

### Getting Current User
```elixir
# In controllers or LiveViews after authentication
current_user = conn.assigns[:current_user]
```

### User Operations
```elixir
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

# Get user by email
user = PhoenixKit.Accounts.get_user_by_email("user@example.com")
```

### Authentication Helpers
```elixir
# In controllers
import PhoenixKitWeb.UserAuth

# Require authentication
plug :phoenix_kit_require_authenticated_user

# Redirect if already logged in
plug :phoenix_kit_redirect_if_user_is_authenticated
```

## Development Workflow

### Setup for Development
1. **Clone and setup**: `mix deps.get`, `mix ecto.setup`
2. **Database**: PostgreSQL with citext extension
3. **Testing**: `mix test` (uses database sandbox)
4. **Quality**: `mix quality` for comprehensive checks

### Testing Strategy
- **Complete test suite** - Authentication flows, user management, tokens, mailer
- **Database integration** - Uses PhoenixKit.DataCase with sandbox
- **LiveView testing** - Form submissions, navigation, error handling
- **Fixtures** - PhoenixKit.AccountsFixtures for test data

### Code Quality
- **Credo** - Static analysis with strict mode
- **Dialyzer** - Type checking for Elixir
- **ExDoc** - Comprehensive documentation generation
- **ExCoveralls** - Test coverage reporting

## File Structure

### Core Authentication
- `lib/phoenix_kit/accounts.ex` - Main authentication context
- `lib/phoenix_kit/accounts/` - User, UserToken, UserNotifier modules
- `lib/phoenix_kit_web/user_auth.ex` - Authentication plugs and helpers

### Web Interface
- `lib/phoenix_kit_web/live/` - LiveView authentication pages
- `lib/phoenix_kit_web/controllers/` - Session controllers
- `lib/phoenix_kit_web/components/` - Reusable UI components
- `lib/phoenix_kit_web/router.ex` - Authentication routes

### Configuration and Setup
- `lib/phoenix_kit/layout_config.ex` - Layout integration system
- `lib/phoenix_kit/auto_setup.ex` - Zero-config setup
- `lib/phoenix_kit/migration.ex` - Migration system
- `lib/phoenix_kit/migrations/postgres/v01.ex` - V01 auth tables

### Installation Tasks
- `lib/mix/tasks/phoenix_kit.install.pro.ex` - Professional Igniter installer
- `lib/mix/tasks/phoenix_kit.install.ex` - Traditional installer
- `lib/mix/tasks/phoenix_kit.install.igniter.ex` - Basic Igniter installer
- `lib/mix/tasks/phoenix_kit.migrate.ex` - Migration management

### Professional Installation System
- `lib/phoenix_kit/install/router_integration/` - Router integration modules
  - `ast_analyzer.ex` - Router AST analysis
  - `import_injector.ex` - Import statement injection
  - `route_injector.ex` - Route call injection
  - `conflict_resolver.ex` - Route conflict resolution
  - `validator.ex` - Integration validation
- `lib/phoenix_kit/install/layout_integration/` - Layout integration modules
  - `layout_detector.ex` - Layout discovery and analysis
  - `compatibility_analyzer.ex` - Layout compatibility assessment
  - `layout_enhancer.ex` - Layout enhancement system
  - `auto_configurator.ex` - Automatic configuration
  - `fallback_handler.ex` - Fallback layout management
- `lib/phoenix_kit/install/conflict_detection/` - Conflict detection modules
  - `dependency_analyzer.ex` - Dependency conflict analysis
  - `configuration_analyzer.ex` - Configuration conflict detection
  - `code_analyzer.ex` - Code pattern analysis
  - `migration_strategy_generator.ex` - Migration strategy generation

### Testing
- `test/phoenix_kit/accounts_test.exs` - Authentication context tests
- `test/phoenix_kit_web/live/` - LiveView integration tests
- `test/phoenix_kit_web/controllers/` - Controller tests
- `test/support/` - Test helpers and fixtures

### Professional Installation System Tests
- `test/phoenix_kit/install/router_integration_test.exs` - Router integration system tests
- `test/phoenix_kit/install/layout_integration_test.exs` - Layout integration system tests
- `test/phoenix_kit/install/conflict_detection_test.exs` - Conflict detection system tests
- `test/phoenix_kit/install/professional_installer_integration_test.exs` - End-to-end installer tests
- `test/phoenix_kit/install/basic_integration_test.exs` - Basic integration workflow tests

## Advanced Features

### Layout Integration
- **Automatic fallback** - Uses PhoenixKit layouts by default
- **Custom layouts** - Integrates with parent app layouts
- **Configuration validation** - Smart module detection and fallbacks
- **Page title prefixes** - Configurable branding

### PostgreSQL Schema Prefixes
- **Database isolation** - Tables in separate schemas (e.g., `auth.users`)
- **Multi-tenant support** - Multiple authentication systems per database
- **Automatic schema creation** - Creates schema if it doesn't exist
- **Permission handling** - Graceful handling of schema creation permissions

### Zero-Config Auto-Setup
- **Repository detection** - Automatically finds parent app's Ecto repo
- **Runtime migration** - Creates tables when first accessed
- **Error recovery** - Comprehensive error handling with actionable messages
- **Development friendly** - Detailed logging and troubleshooting guidance

## Professional Features

### Igniter Integration
- **AST-based modifications** - Safely modifies existing files without breaking them
- **Project awareness** - Understands Phoenix project structure
- **Idempotent operations** - Can be run multiple times safely
- **Composable** - Works with other Igniter-based installers

### Production Readiness
- **Comprehensive logging** - Detailed setup and error logging
- **Email configuration** - Supports all Swoosh adapters
- **Security best practices** - CSRF protection, secure sessions, password hashing
- **Performance optimized** - Efficient queries and minimal overhead

### Developer Experience
- **Best-in-class errors** - Actionable error messages with solution steps
- **Multiple installation methods** - Choose complexity level that fits your needs
- **Extensive documentation** - Comprehensive guides and troubleshooting
- **Active maintenance** - Regular updates and improvements

## Usage as Authentication Library

PhoenixKit is designed to be dropped into any Phoenix application with minimal configuration. The Professional Igniter installer makes integration seamless by automatically detecting your setup and configuring everything needed.

### Key Benefits
- **Zero manual configuration** - Professional installer handles everything
- **Design flexibility** - Integrates with your existing layouts and styles
- **Database isolation** - PostgreSQL schema prefixes for clean separation
- **Production ready** - Comprehensive email, session, and security handling
- **Future-proof** - Versioned migration system for easy upgrades

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.