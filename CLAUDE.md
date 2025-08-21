# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MCP Memory Knowledge Base

⚠️ **IMPORTANT**: Always start working with the project by studying data in the MCP memory storage. Use the command:

```
mcp__memory__read_graph
```

This will help understand the current state of the project, implemented and planned components, architectural decisions.

Update data in memory when discovering new components or changes in project architecture. Use:

- `mcp__memory__create_entities` - for adding new modules/components
- `mcp__memory__create_relations` - for relationships between components
- `mcp__memory__add_observations` - for supplementing information about existing components

## Project Overview

This is **PhoenixKit** - a professional authentication library for Phoenix applications with PostgreSQL support and zero-configuration setup. It provides a complete authentication system that can be integrated into any Phoenix application without circular dependencies.

**Key Characteristics:**

- Library-first architecture (no OTP application)
- Zero-configuration setup with auto-detection
- Complete authentication system with Magic Links
- Role-based access control (Owner/Admin/User)
- Built-in admin dashboard and user management
- Theme system with light/dark mode support
- Professional versioned migration system
- Layout integration with parent applications
- Ready for production use

## Development Commands

### Setup and Dependencies

- `mix setup` - Complete project setup (installs deps, sets up database)
- `mix deps.get` - Install Elixir dependencies only

### Database Operations

- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with fresh data
- `mix ecto.setup` - Create database, run migrations, and seed data

### PhoenixKit Installation System

- `mix phoenix_kit.install` - Install PhoenixKit using igniter (for new projects)
- `mix phoenix_kit.update` - Update existing PhoenixKit installation to latest version
- `mix phoenix_kit.update --status` - Check current version and available updates
- `mix phoenix_kit.gen.migration` - Generate custom migration files
- **Professional versioned migrations** - Oban-style migration system with version tracking
- **Prefix support** - Isolate PhoenixKit tables using PostgreSQL schemas
- **Idempotent operations** - Safe to run migrations multiple times
- **Multi-version upgrades** - Automatically handles upgrades across multiple versions

### Theme System Features

- `mix phoenix_kit.install --theme-enabled` - Enable theme system during installation
- **Light/Dark/Auto modes** - Complete theme switching with system preference detection
- **DaisyUI integration** - Professional UI components with theme support
- **CSS Variables** - Dynamic theme switching without page reload
- **Local Storage persistence** - User theme preferences saved automatically
- **Keyboard shortcuts** - Alt+T for quick theme toggling

### Magic Link Authentication

- **Passwordless login** - Secure authentication via email links
- **15-minute expiry** - Configurable token lifetime for security
- **One-time use tokens** - Prevents token reuse attacks
- **Parallel to password auth** - Works alongside traditional authentication
- **Configurable mailer** - Supports all Swoosh adapters

**Recent Installation Enhancements:**
- **PostgreSQL Validation** - Automatic database adapter detection with warnings for non-PostgreSQL setups
- **Production Mailer Templates** - Auto-generated configuration examples for SMTP, SendGrid, Mailgun, Amazon SES
- **Interactive Migration Runner** - Optional automatic migration execution with smart CI detection
- **Enhanced User Experience** - One-command setup from empty project to working authentication

**Installation vs Update:**
- Use `phoenix_kit.install` for new projects (first-time setup)
- Use `phoenix_kit.update` for upgrading existing installations
- Install will redirect to update if PhoenixKit is already installed

### Role-Based Access Control System

- **Three System Roles** - Owner, Admin, User with automatic assignment
- **PostgreSQL Trigger** - First user automatically becomes Owner
- **Admin Dashboard** - Built-in dashboard at `/phoenix_kit/admin/dashboard` for system statistics
- **User Management** - Complete user management interface at `/phoenix_kit/admin/users`
- **Role API** - Comprehensive role management with `PhoenixKit.Users.Roles`
- **Security Features** - Owner protection, audit trail, self-modification prevention
- **Scope Integration** - Role checks via `PhoenixKit.Users.Auth.Scope`

### Testing

- `mix test` - Run all tests (12 tests, no database required)
- ⚠️ Ecto warnings are normal for library - tests focus on API validation

### Code Quality

- `mix quality` - Run all quality checks (format, credo, dialyzer, test)
- `mix format` - Format code according to .formatter.exs
- `mix credo --strict` - Static code analysis
- `mix dialyzer` - Type checking (requires PLT setup)

### ⚠️ IMPORTANT: Pre-commit Checklist

**ALWAYS run before git commit:**

```bash
mix format
git add -A  # Add formatted files
git commit -m "your message"
```

This ensures consistent code formatting across the project.

### 📝 Commit Message Rules

**ALWAYS start commit messages with action verbs:**

- `Add` - for new features, files, or functionality
- `Update` - for modifications to existing code or features
- `Merge` - for merge commits or combining changes
- `Fix` - for bug fixes
- `Remove` - for deletions

**Important commit message restrictions:**

- ❌ **NEVER mention Claude or AI assistance** in commit messages
- ❌ Avoid phrases like "Generated with Claude", "AI-assisted", etc.
- ✅ Focus on **what** was changed and **why**

**Examples:**

- ✅ `Add role system for user authorization management`
- ✅ `Update rollback logic to handle single version migrations`
- ✅ `Fix merge conflict markers in installation file`
- ❌ `Enhanced migration system` (no action verb)
- ❌ `migration fixes` (not descriptive enough)
- ❌ `Add new feature with Claude assistance` (mentions AI)

### 🏷️ Version Management Protocol

**MANDATORY steps for version updates (follows Elixir best practices):**

#### 1. Version Update Requirements

When creating a new version release:

```bash
# Current version locations to update:
# - mix.exs (@version constant)
# - CHANGELOG.md (new version entry)
# - README.md (if version mentioned in examples)
```

#### 2. Version Number Schema

- **Format**: `MAJOR.MINOR.PATCH` (Semantic Versioning)
- **MAJOR**: Breaking changes, backward incompatibility
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

**Examples:**
- `1.0.0` → `1.0.1` (patch: bug fixes)
- `1.0.1` → `1.1.0` (minor: new features)
- `1.x.x` → `2.0.0` (major: breaking changes)

#### 3. Update Process Checklist

**Step 1: Update mix.exs**
```elixir
# In mix.exs, update @version constant
@version "1.0.1"  # Increment from current version
```

**Step 2: Update CHANGELOG.md**
```markdown
## [Unreleased]

## [1.0.1] - 2025-08-20

### Added
- Description of new features

### Changed  
- Description of modifications

### Fixed
- Description of bug fixes

### Removed
- Description of deletions
```

**Step 3: Update README.md (if needed)**
```markdown
# Update any version references in examples
{:phoenix_kit, "~> 1.0"}
```

**Step 4: Commit Version Changes**
```bash
git add mix.exs CHANGELOG.md README.md
git commit -m "Update version to 1.0.1 with comprehensive changelog

Version Changes:
- Bump version from 1.0.0 to 1.0.1 in mix.exs
- Add comprehensive CHANGELOG.md entry for v1.0.1 release
- Update documentation with new version references

Release includes: [brief description of main changes]"
```

#### 4. Version Validation

**Before committing version changes:**
- ✅ Mix compiles without errors: `mix compile`
- ✅ Tests pass: `mix test`
- ✅ Code formatted: `mix format`
- ✅ CHANGELOG.md includes current date
- ✅ Version number incremented correctly
- ✅ No references to old version in docs

#### 5. Release Documentation

**CHANGELOG.md must include:**
- Release date in format: `YYYY-MM-DD`
- Categorized changes: Added, Changed, Fixed, Removed
- Security section if CVEs addressed
- Clear descriptions of breaking changes

**Example CHANGELOG.md entry:**
```markdown
## [1.0.1] - 2025-08-20

### Added
- New PhoenixKit Scope system for structured authentication
- Enhanced on_mount callbacks for better LiveView integration

### Changed
- Improved documentation with comprehensive examples
- Enhanced router integration patterns

### Fixed
- Password validation consistency between client and server
- Layout integration edge cases

### Security
- Fixed CVE-XXXX-XXXX: Description if applicable
```

**⚠️ Critical Notes:**
- **NEVER ship without updating CHANGELOG.md**
- **ALWAYS validate version number increments**  
- **NEVER reference old version in new documentation**
- **ALWAYS test compilation after version changes**

### Documentation

- `mix docs` - Generate documentation with ExDoc

### Publishing

- `mix hex.build` - Build package for Hex.pm
- `mix hex.publish` - Publish to Hex.pm (requires auth)

### Version Management

- **Current Version**: 1.0.0 (in mix.exs)
- **Version Strategy**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Migration Version**: V01 (includes basic authentication with role system)
- **Database Versioning**: Professional system with version tracking in table comments

### 🚀 Pre-Release Checklist

**MANDATORY steps before any release or version bump:**

1. **Code Quality Checks:**

   ```bash
   mix format              # Format all code
   mix compile             # Ensure clean compilation (no warnings/errors)
   mix quality             # Run all quality checks (credo + dialyzer)
   ```

2. **Version Updates:**

   - Update version number in `mix.exs`
   - Update `CHANGELOG.md` with changes

3. **Final Verification:**
   - All tests pass: `mix test`
   - No compilation warnings
   - No critical Credo issues
   - Dialyzer analysis complete

**❌ Never release if:**

- Compilation produces warnings or errors
- Quality checks fail
- Tests are failing

## Architecture

### Authentication Structure

- **PhoenixKit.Users.Auth** - Main authentication context with public interface
- **PhoenixKit.Users.Auth.User** - User schema with validations, authentication, and role helpers
- **PhoenixKit.Users.Auth.UserToken** - Token management for email confirmation and password reset
- **PhoenixKit.Users.MagicLink** - Magic link authentication system
- **PhoenixKit.Users.Auth.Scope** - Authentication scope management with role integration

### Role System Architecture

- **PhoenixKit.Users.Role** - Role schema with system role protection
- **PhoenixKit.Users.RoleAssignment** - Many-to-many role assignments with audit trail
- **PhoenixKit.Users.Roles** - Role management API and business logic
- **PhoenixKitWeb.Live.DashboardLive** - Admin dashboard with system statistics
- **PhoenixKitWeb.Live.UsersLive** - User management interface with role controls
- **PostgreSQL Trigger** - Automatic Owner role assignment to first user

### Migration Architecture

- **PhoenixKit.Migrations.Postgres** - PostgreSQL-specific migrator with Oban-style versioning
- **PhoenixKit.Migrations.Postgres.V01** - Version 1: Basic authentication tables with role system
- **Mix.Tasks.PhoenixKit.Install** - Igniter-based installation for new projects
- **Mix.Tasks.PhoenixKit.Update** - Versioned updates for existing installations
- **Mix.Tasks.PhoenixKit.Gen.Migration** - Custom migration generator

### Key Design Principles

- **No Circular Dependencies** - Optional Phoenix deps prevent import cycles
- **Library-First** - No OTP application, can be used as dependency
- **Professional Testing** - DataCase pattern with database sandbox
- **Production Ready** - Complete authentication system with security best practices

### Database Integration

- **PostgreSQL** - Primary database with Ecto integration
- **Repository Pattern** - Auto-detection or explicit configuration
- **Migration Support** - V01 migration with authentication and role tables
- **Role System Tables** - phoenix_kit_user_roles, phoenix_kit_user_role_assignments
- **Database Triggers** - Automatic Owner role assignment to first user
- **Test Database** - Separate test database with sandbox

### Professional Features

- **Hex Publishing** - Complete package.exs configuration
- **Documentation** - ExDoc ready with comprehensive docs
- **Quality Tools** - Credo, Dialyzer, code formatting configured
- **Testing Framework** - Complete test suite with fixtures

## PhoenixKit Integration

### Setup Steps

1. **Install PhoenixKit**: Run `mix phoenix_kit.install --repo YourApp.Repo`
2. **Configure Layout**: Optionally set custom layouts in `config/config.exs`
3. **Add Routes**: Use `phoenix_kit_routes()` macro in your router
4. **Configure Mailer**: Set up email delivery in `config/config.exs`
5. **Run Migrations**: Database tables created automatically
6. **Theme Support**: Optionally enable with `--theme-enabled` flag

### Integration Pattern

```elixir
# In your Phoenix app's config/config.exs
config :phoenix_kit,
  repo: MyApp.Repo

# Configure PhoenixKit Mailer for email delivery
config :phoenix_kit, PhoenixKit.Mailer, adapter: Swoosh.Adapters.Local

# Configure Layout Integration (optional - defaults to PhoenixKit layouts)
config :phoenix_kit,
  layout: {MyAppWeb.Layouts, :app},        # Use your app's layout
  root_layout: {MyAppWeb.Layouts, :root},  # Optional: custom root layout
  page_title_prefix: "Auth"                # Optional: page title prefix

# Configure Theme System (optional)
config :phoenix_kit,
  theme_enabled: true,
  theme: %{
    mode: :auto,                    # :light, :dark, :auto
    primary_color: "#3b82f6",      # Primary brand color
    storage: :local_storage         # :local_storage, :session, :cookie
  }

# In your Phoenix app's mix.exs
def deps do
  [
    {:phoenix_kit, "~> 1.0"}
  ]
end
```

## File Structure

### Core Authentication Files

- `lib/phoenix_kit.ex` - Main API module and public interface
- `lib/phoenix_kit/users/auth.ex` - Authentication context (main business logic)
- `lib/phoenix_kit/users/auth/user.ex` - User schema with authentication and role helpers
- `lib/phoenix_kit/users/auth/user_token.ex` - Token management system
- `lib/phoenix_kit/users/magic_link.ex` - Magic link authentication
- `lib/phoenix_kit/theme_config.ex` - Theme system configuration

### Role System Files

- `lib/phoenix_kit/users/role.ex` - Role schema with validation and system role protection
- `lib/phoenix_kit/users/role_assignment.ex` - Role assignment schema with audit trail
- `lib/phoenix_kit/users/roles.ex` - Role management API and business logic

### Web Integration Files

- `lib/phoenix_kit_web/integration.ex` - Router integration macro with admin routes
- `lib/phoenix_kit_web/users/auth.ex` - Web authentication plugs and role-based helpers
- `lib/phoenix_kit_web/users/login_live.ex` - Login LiveView component
- `lib/phoenix_kit_web/users/registration_live.ex` - Registration LiveView component
- `lib/phoenix_kit_web/users/settings_live.ex` - User settings LiveView component

### Admin Interface Files

- `lib/phoenix_kit_web/live/dashboard_live.ex` - Admin dashboard LiveView
- `lib/phoenix_kit_web/live/dashboard_live.html.heex` - Dashboard template
- `lib/phoenix_kit_web/live/users_live.ex` - User management LiveView
- `lib/phoenix_kit_web/live/users_live.html.heex` - User management template
- `lib/phoenix_kit_web/users/magic_link_live.ex` - Magic link request page
- `lib/phoenix_kit_web/users/magic_link_controller.ex` - Magic link verification
- `lib/phoenix_kit_web/components/core_components.ex` - UI components with theme support

### Theme Assets

- `priv/static/assets/phoenix_kit_theme.css` - Theme system styles
- `priv/static/assets/phoenix_kit_theme.js` - Theme switching JavaScript

### Database Files

- `lib/phoenix_kit/migrations/postgres.ex` - Main migration controller
- `lib/phoenix_kit/migrations/postgres/v01.ex` - V01: Basic auth tables with role system
- `config/config.exs` - Library configuration

### Testing Files

- `test/test_helper.exs` - Test configuration
- `test/phoenix_kit_test.exs` - Main API tests
- `test/phoenix_kit/users_test.exs` - Authentication system tests

### Configuration Files

- `.formatter.exs` - Code formatting rules
- `.credo.exs` - Static analysis configuration
- `.gitignore` - Git ignore patterns
- `mix.exs` - Project and package configuration

### Documentation

- `README.md` - Comprehensive usage documentation
- `CHANGELOG.md` - Version history and changes
- `LICENSE` - MIT license file

## Development Workflow

PhoenixKit supports a complete professional development workflow:

1. **Development** - Local development with PostgreSQL
2. **Testing** - Comprehensive test suite with database integration
3. **Quality** - Static analysis and type checking
4. **Documentation** - Generated docs with usage examples
5. **Publishing** - Ready for Hex.pm with proper versioning
