# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Nothing yet

## [0.2.6] - 2025-07-31

### Fixed
- Repository cleanup: removed test projects and debug files
- Removed unnecessary test applications and validation scripts
- Cleaned up temporary config files and layout backups

### Removed
- Test projects: temp_app, test_auto_setup, test_app
- Debug scripts: fix_warnings.exs, fix_all_warnings.exs
- Test scripts: test_pro_installer.exs, test_router_integration.exs
- Validation scripts and temporary files
- test_live.ex file from production code

## [0.2.0] - 2025-07-30

### Added
- Professional Igniter-powered installation system with AST modification
- Intelligent router integration with automatic route injection
- Advanced layout integration system with enhancement capabilities
- Comprehensive conflict detection and resolution system
- Layout enhancement features with fallback configuration
- Multi-layer dependency, configuration, and code analysis
- Professional error handling with actionable guidance

### Changed
- Enhanced installation experience with zero-config automation
- Improved migration system with comprehensive validation
- Updated documentation for new professional installation features

## [0.1.10] - 2025-07-29

### Changed
- Incremented version for release management
- Updated version consistency across project files

## [0.1.7] - 2025-07-28

### Fixed
- **CRITICAL**: Fixed "could not find migration runner process" error in auto-setup system
- Migration system now correctly handles runtime context without requiring Ecto migration runner
- Table versioning system properly assigns metadata to phoenix_kit_users table
- Resolved all compilation warnings for unused variables
- Updated troubleshooting documentation for migration errors

### Changed
- Improved migration system architecture with separate runtime and migration contexts
- Enhanced error handling in auto-setup with better fallback mechanisms

### Removed
- Deprecated `schema_migrations.ex` file (replaced with metadata-based versioning)

## [0.1.0] - 2025-01-01

### Added
- Initial release of PhoenixKit authentication library
- Library-first architecture with no OTP application
- PostgreSQL integration with Ecto and schema prefixes
- Professional code organization following Phoenix conventions
- Comprehensive test suite with database integration
- Complete authentication system with LiveView pages
- User management with registration, login, password reset
- Email confirmation and notification system
- Professional documentation and README
- Development tools configuration (Credo, Dialyzer, ExDoc)
- Hex.pm package configuration
- MIT License

### Features
- **Authentication Context** - `PhoenixKit.Accounts` for user management
- **User Management** - Registration, login, password reset, email confirmation
- **LiveView Pages** - All authentication pages use Phoenix LiveView
- **Database Migration** - Versioned migration system with rollback support
- **Test Suite** - Unit and integration tests with DataCase
- **Configuration** - Environment-specific configs for dev/test/prod
- **Zero-Config Setup** - Automatic repository detection and configuration

### Documentation
- Comprehensive README with usage examples
- API documentation with ExDoc
- Installation and setup instructions
- Authentication workflow guide
- Contributing guidelines

### Development Tools
- Code formatting with `mix format`
- Static analysis with Credo
- Type checking with Dialyzer
- Test coverage with ExCoveralls
- Documentation generation with ExDoc
- Quality checks with `mix quality` alias

[Unreleased]: https://github.com/BeamLabEU/phoenixkit/compare/v0.2.6...HEAD
[0.2.6]: https://github.com/BeamLabEU/phoenixkit/compare/v0.2.0...v0.2.6
[0.2.0]: https://github.com/BeamLabEU/phoenixkit/compare/v0.1.10...v0.2.0
[0.1.10]: https://github.com/BeamLabEU/phoenixkit/compare/v0.1.7...v0.1.10
[0.1.7]: https://github.com/BeamLabEU/phoenixkit/compare/v0.1.0...v0.1.7
[0.1.0]: https://github.com/BeamLabEU/phoenixkit/releases/tag/v0.1.0