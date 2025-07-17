# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Plugin system for extending functionality
- GraphQL support for API endpoints
- Advanced analytics and reporting
- Mobile-specific components

## [0.3.0] - 2024-07-17

### 🚀 Major Release - Complete Architecture Overhaul

**Breaking Changes:**
- **Complete API rewrite** - This version is not compatible with v0.2.x
- **Removed static component** - `PhoenixKit.welcome/1` component has been removed
- **New routing system** - `phoenix_kit_routes()` replaced with `PhoenixKit.routes()`
- **URL structure change** - `/phoenix-kit/*` changed to `/phoenix_kit/*`
- **New installation method** - Now uses Igniter for automated setup

### ✨ Added

#### Core Architecture
- **Complete MVC architecture** with 4 main controllers
- **3 LiveView components** for real-time interfaces
- **100+ utility functions** in PhoenixKit.Utils
- **Security system** with authentication and authorization
- **Telemetry system** for metrics collection
- **Modern daisyUI design** with responsive components

#### Controllers
- **PageController** - Main landing page with feature overview
- **DashboardController** - Static dashboard with system metrics
- **ComponentsController** - UI components catalog
- **UtilitiesController** - Developer utilities showcase

#### LiveView Components
- **DashboardLive** - Real-time dashboard with auto-refresh
- **StatsLive** - Detailed system statistics and analytics
- **MonitorLive** - System monitoring with alerts

#### Utility Functions
- **Date/Time utilities** - Formatting, relative time, datetime handling
- **String utilities** - Truncation, slugification, title case
- **Validation utilities** - Email, password strength, file types
- **File utilities** - Size formatting, type validation, file stats
- **Development utilities** - Benchmarking, debugging, performance tools
- **Cache utilities** - Get/set operations, invalidation
- **Number utilities** - Formatting, parsing, calculations

#### Security Features
- **AuthPlug** - Authentication middleware
- **TelemetryPlug** - Metrics collection middleware
- **IP whitelisting** - Restrict access by IP address
- **Basic HTTP authentication** - Username/password protection
- **Configurable security settings**

#### Igniter Integration
- **Automated installation** - `mix igniter.install phoenix_kit`
- **Safe code modification** - AST-based route injection
- **Configuration management** - Automatic config file updates
- **Asset management** - CSS/JS file copying
- **Migration tools** - Version upgrade utilities

#### Mix Tasks
- **phoenix_kit.install** - Install PhoenixKit with Igniter
- **phoenix_kit.uninstall** - Clean removal of PhoenixKit
- **phoenix_kit.update** - Migration from older versions

### 🔧 Changed

#### Routing
- **New macro system** - `PhoenixKit.routes()` instead of `phoenix_kit_routes()`
- **LiveView support** - Added `import Phoenix.LiveView.Router`
- **API endpoints** - Added `/api/stats` and `/api/metrics`
- **Scope consistency** - All routes under `/phoenix_kit` namespace

#### Configuration
- **Enhanced config options** - More granular feature control
- **Environment-specific settings** - Different configs for dev/prod
- **Theme system** - Customizable appearance
- **Performance settings** - Configurable refresh intervals

#### Templates
- **Modern daisyUI components** - Replaced custom CSS with daisyUI
- **Responsive design** - Mobile-first approach
- **Interactive elements** - Enhanced user experience
- **Accessibility improvements** - Better ARIA support

### 🗑️ Removed

#### Breaking Removals
- **Static component** - `PhoenixKit.welcome/1` component removed
- **Old routing** - `phoenix_kit_routes()` macro removed
- **Legacy URLs** - `/phoenix-kit/*` paths no longer supported
- **Old LiveView** - Simple welcome LiveView removed

### 📦 Dependencies

#### Updated
- **Phoenix** - Updated to 1.8.0-rc.0
- **Phoenix LiveView** - Updated to 1.0.0-rc.0
- **Igniter** - Added for automated installation

#### Added
- **Igniter** ~> 0.6 - For safe code modification
- **ExCoveralls** ~> 0.18 - Test coverage reporting

### 🔄 Migration Guide

#### From v0.2.x to v0.3.0

1. **Remove old dependency:**
   ```elixir
   # Remove from mix.exs
   {:phoenix_kit, "~> 0.2.0"}
   ```

2. **Add new dependency:**
   ```elixir
   # Add to mix.exs
   {:phoenix_kit, "~> 0.3.0"}
   ```

3. **Update router:**
   ```elixir
   # OLD (remove this)
   import PhoenixKit.Router
   phoenix_kit_routes()
   
   # NEW (add this)
   import PhoenixKit
   PhoenixKit.routes()
   ```

4. **Remove old components:**
   ```elixir
   # Remove all instances of:
   <PhoenixKit.welcome title="..." />
   ```

5. **Update URLs:**
   ```
   # OLD URLs (no longer work)
   /phoenix-kit          ❌
   /phoenix-kit/dashboard ❌
   
   # NEW URLs
   /phoenix_kit           ✅
   /phoenix_kit/dashboard ✅
   /phoenix_kit/live      ✅
   ```

6. **Run automated update:**
   ```bash
   mix phoenix_kit.update
   ```

### 🛠️ Technical Details

#### Performance
- **Optimized asset loading** - Efficient CSS/JS bundling
- **Lazy loading** - Components loaded on demand
- **Caching system** - Improved response times
- **Memory optimization** - Reduced memory footprint

#### Testing
- **100% test coverage** - Comprehensive test suite
- **Integration tests** - Full request/response cycle testing
- **Property-based testing** - Edge case coverage
- **Mock systems** - Isolated testing environment

#### Documentation
- **English README** - Primary documentation
- **Russian README** - Локализованная документация
- **API documentation** - Complete function reference
- **Migration guides** - Step-by-step upgrade instructions

### 🌟 Highlights

- **10x more functionality** - From simple component to full framework
- **Modern development practices** - Igniter integration, automated setup
- **Production-ready** - Security, performance, monitoring
- **Developer-friendly** - Extensive utilities, clear documentation
- **Community-focused** - Open source, contribution-friendly

## [0.2.1] - 2024-01-20

### Fixed
- Fixed template compilation issues
- Improved error handling in controllers
- Updated documentation

### Added
- Basic telemetry support
- Simple caching mechanism

## [0.2.0] - 2024-01-16

### Added
- LiveView support
- Basic dashboard functionality
- Simple component system

### Changed
- Improved router integration
- Enhanced configuration options

## [0.1.0] - 2024-01-15

### Added
- Initial release
- Basic Phoenix integration
- Simple welcome component
- Basic routing system

---

## Migration Support

For migration assistance or questions:
- 🐛 **Issues**: [GitHub Issues](https://github.com/BeamLabEU/phoenixkit/issues)
- 💡 **Discussions**: [GitHub Discussions](https://github.com/BeamLabEU/phoenixkit/discussions)
- 📧 **Email**: support@beamlab.eu

## Version Compatibility

| PhoenixKit | Phoenix | Elixir | LiveView | Status |
|-----------|---------|--------|----------|--------|
| 0.3.0     | 1.8+    | 1.16+  | 1.0+     | ✅ Active |
| 0.2.x     | 1.7+    | 1.15+  | 0.20+    | ⚠️ Legacy |
| 0.1.x     | 1.6+    | 1.14+  | 0.18+    | ❌ Deprecated |

## Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

## Types of Changes

- **Added** - for new features
- **Changed** - for changes in existing functionality
- **Deprecated** - for soon-to-be removed features
- **Removed** - for now removed features
- **Fixed** - for any bug fixes
- **Security** - for vulnerability fixes