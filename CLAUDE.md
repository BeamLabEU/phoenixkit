# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

PhoenixKit is an Elixir/Phoenix extension library that provides ready-to-use components, utilities, and tools for rapid development of modern web applications. It's designed as a plugin that integrates seamlessly into existing Phoenix applications.

## Development Commands

### Essential Commands
- `mix deps.get` - Install dependencies
- `mix test` - Run all tests
- `mix test --cover` - Run tests with coverage reporting
- `mix test test/path/to/specific_test.exs` - Run specific test file
- `mix format` - Format code according to .formatter.exs
- `mix credo --strict` - Run code analysis and style checks
- `mix dialyzer` - Run type analysis (static analysis)
- `mix docs` - Generate documentation
- `mix test.coverage` - Generate HTML coverage report (alias for coveralls.html)

### Installation Testing
- `mix igniter.install phoenix_kit` - Install PhoenixKit in a Phoenix project
- `mix phoenix_kit.uninstall` - Uninstall PhoenixKit from a Phoenix project

## Architecture Overview

### Core Structure
- **Main Module**: `PhoenixKit` - Provides routing macro and configuration
- **Controllers**: Handle HTTP requests for different sections (dashboard, components, utilities)
- **LiveView Components**: Real-time dashboard and monitoring interfaces
- **Utilities**: Common helper functions in `PhoenixKit.Utils`
- **Plugs**: Middleware for authentication and telemetry
- **Mix Tasks**: Installation and management tools using Igniter

### Key Components

#### 1. Routing System
- Uses macro `PhoenixKit.routes/0` to inject routes into host applications
- Routes are scoped under `/phoenix_kit` namespace
- Includes both traditional controller routes and LiveView routes

#### 2. Dashboard System
- **Static Dashboard**: `DashboardController` - Traditional Phoenix controller
- **Live Dashboard**: `DashboardLive` - Real-time LiveView with metrics
- **Monitoring**: `MonitorLive` and `StatsLive` - Advanced monitoring interfaces

#### 3. Installation System
- Uses **Igniter** for safe code modification and installation
- `Mix.Tasks.PhoenixKit.Install` handles automatic router modification
- Supports modular installation with options (--no-routes, --no-assets, etc.)

#### 4. Utilities Library
- `PhoenixKit.Utils` provides common helper functions
- Includes date formatting, string manipulation, validation, file handling
- Performance utilities like benchmarking and caching helpers

### Code Patterns

#### LiveView Pattern
- Uses `@refresh_interval` for automatic updates
- Implements real-time metrics collection with history tracking
- Interactive components with client-side state management

#### Controller Pattern
- Follows Phoenix conventions with render/3 and json/2 responses
- Separates concerns with private helper functions
- Uses mock data for demonstration purposes

#### Plugin Architecture
- Uses macros for route injection
- Configuration through Application environment
- Feature toggles via `feature_enabled?/1`

## Code Style and Formatting

### Formatting Rules (from .formatter.exs):
- Line length: 98 characters
- Includes Phoenix.LiveView.HTMLFormatter for .heex files
- Import dependencies: [:phoenix, :phoenix_live_view, :plug]
- Subdirectories: ["priv/*/migrations"]

### Testing Setup
- Uses ExUnit with custom MockPhoenix module
- Test helpers in `test/support/`
- Integration tests in `test/integration/`

## Dependencies

### Core Dependencies
- **Phoenix**: ~> 1.8.0-rc.0 (framework)
- **Phoenix LiveView**: ~> 1.0.0-rc.0 (real-time components)
- **Jason**: ~> 1.4 (JSON handling)
- **Plug**: ~> 1.16 (HTTP middleware)

### Development Dependencies
- **Igniter**: ~> 0.6 (code generation and installation)
- **ExDoc**: ~> 0.32 (documentation generation)
- **Credo**: ~> 1.7 (code analysis)
- **Dialyxir**: ~> 1.4 (type analysis)
- **ExCoveralls**: ~> 0.18 (test coverage)

## Special Notes

### Igniter Integration
- This project heavily uses Igniter for safe code modification
- Installation tasks must use Igniter patterns for router modification
- Configuration changes should use `Igniter.Project.Config.configure/4`

### Mock Data
- Dashboard controllers use mock/random data for demonstration
- Real implementations would integrate with actual application metrics
- Cache functions in Utils are stubs that need real implementations

### Security Considerations
- Includes AuthPlug for protecting dashboard endpoints
- TelemetryPlug for metrics collection
- IP whitelisting capabilities

### Static Assets
- CSS and JavaScript files are bundled with the library
- Assets are installed to `priv/static/phoenix_kit/` during installation
- Custom theming supported through configuration

## Development Workflow

1. **Adding New Features**: Follow Phoenix conventions, add tests, update documentation
2. **Modifying Installation**: Update Mix.Tasks.PhoenixKit.Install with new requirements
3. **Testing**: Run full test suite including integration tests
4. **Documentation**: Update README.md and generate docs with `mix docs`
5. **Code Quality**: Run `mix credo --strict` and `mix dialyzer` before commits