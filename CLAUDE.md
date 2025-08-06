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

This is **Phoenix Module Template** - a professional library-first template for creating Phoenix modules with PostgreSQL support. It's designed as a reusable foundation that avoids circular dependencies and follows Phoenix best practices.

**Key Characteristics:**

- Library-first architecture (no OTP application)
- Optional Phoenix dependencies to prevent circular imports
- Professional testing framework with database integration
- Ready for Hex.pm publishing
- Template structure for easy customization

## Development Commands

### Setup and Dependencies

- `mix setup` - Complete project setup (installs deps, sets up database)
- `mix deps.get` - Install Elixir dependencies only

### Database Operations

- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with fresh data
- `mix ecto.setup` - Create database, run migrations, and seed data

### PhoenixKit Migration System

- `mix phx.kit.install.igniter` - Install PhoenixKit using igniter (recommended)
- `mix phx.kit.migrate --status` - ⚠️ Check migration status (requires configured repo)
- **Professional versioned migrations** - Oban-style migration system with version tracking
- **Prefix support** - Isolate PhoenixKit tables using PostgreSQL schemas
- **Idempotent operations** - Safe to run migrations multiple times

**Note:** `phx.kit.migrate --status` requires a configured repository to work.

### Testing

- `mix test` - Run all tests with database sandbox
- `mix test --cover` - Run tests with coverage report

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

- ✅ `Add phoenix_kit_ai table for configuration management`
- ✅ `Update rollback logic to handle single version migrations`
- ✅ `Fix merge conflict markers in installation file`
- ❌ `Enhanced migration system` (no action verb)
- ❌ `migration fixes` (not descriptive enough)
- ❌ `Add new feature with Claude assistance` (mentions AI)

### Documentation

- `mix docs` - Generate documentation with ExDoc

### Publishing

- `mix hex.build` - Build package for Hex.pm
- `mix hex.publish` - Publish to Hex.pm (requires auth)

### Version Management

- **Current Version**: 0.1.3 (in mix.exs)
- **Version Strategy**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Migration Version**: V01 (current auth tables)
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

### Library Structure

- **PhoenixModuleTemplate** - Main API module with public interface
- **PhoenixModuleTemplate.Context** - Business logic following Phoenix Context pattern
- **PhoenixModuleTemplate.Schema.Example** - Ecto schema with validations
- **PhoenixModuleTemplate.Repo** - Database repository configuration

### Migration Architecture

- **PhoenixKit.Migration** - Main migration interface with behaviour
- **PhoenixKit.Migrations.Postgres** - PostgreSQL-specific migrator
- **PhoenixKit.Migrations.Postgres.V01** - Version 1 auth tables migration
- **Mix.Tasks.PhoenixKit.Install.Igniter** - Igniter-based installation task
- **Versioned system** - Oban-style architecture for professional database management

### Key Design Principles

- **No Circular Dependencies** - Optional Phoenix deps prevent import cycles
- **Library-First** - No OTP application, can be used as dependency
- **Professional Testing** - DataCase pattern with database sandbox
- **Template Ready** - Easy to customize and rebrand

### Database Integration

- **PostgreSQL** - Primary database with Ecto integration
- **Repository Pattern** - Auto-detection or explicit configuration
- **Migration Support** - Included migration for examples table
- **Test Database** - Separate test database with sandbox

### Professional Features

- **Hex Publishing** - Complete package.exs configuration
- **Documentation** - ExDoc ready with comprehensive docs
- **Quality Tools** - Credo, Dialyzer, code formatting configured
- **Testing Framework** - Complete test suite with fixtures

## Usage as Template

### Customization Steps

1. **Rename Module**: Replace `PhoenixModuleTemplate` → `YourModuleName`
2. **Update Package**: Modify `mix.exs` with your package details
3. **Customize Schema**: Adapt `lib/phoenix_module_template/schema/example.ex`
4. **Implement Logic**: Update `lib/phoenix_module_template/context.ex`
5. **Update Tests**: Modify test files for your domain
6. **Documentation**: Replace README.md with your content

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

# In your Phoenix app's mix.exs
def deps do
  [
    {:phoenix_kit, "~> 0.1.0"}
  ]
end
```

## File Structure

### Core Library Files

- `lib/phoenix_module_template.ex` - Main API module
- `lib/phoenix_module_template/context.ex` - Business logic context
- `lib/phoenix_module_template/schema/example.ex` - Ecto schema
- `lib/phoenix_module_template/repo.ex` - Repository configuration

### Database Files

- `priv/repo/migrations/` - Database migration files
- `config/dev.exs` - Development database configuration
- `config/test.exs` - Test database configuration

### Testing Files

- `test/support/data_case.ex` - Database testing utilities
- `test/phoenix_module_template/` - Test modules
- `test/test_helper.exs` - Test configuration

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

This template supports a complete professional development workflow:

1. **Development** - Local development with PostgreSQL
2. **Testing** - Comprehensive test suite with database integration
3. **Quality** - Static analysis and type checking
4. **Documentation** - Generated docs with usage examples
5. **Publishing** - Ready for Hex.pm with proper versioning
