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

## [0.1.0] - 2024-01-01

### Added
- Initial release of Phoenix Module Template
- Library-first architecture with no circular dependencies
- PostgreSQL integration with Ecto
- Professional code organization following Phoenix conventions
- Comprehensive test suite with database integration
- Example schema with validations and constraints
- Context module with CRUD operations
- Pagination and search functionality
- Professional documentation and README
- Development tools configuration (Credo, Dialyzer, ExDoc)
- Hex.pm package configuration
- MIT License

### Features
- **Main API Module** - `PhoenixModuleTemplate` with version management and configuration
- **Context Module** - `PhoenixModuleTemplate.Context` for business logic
- **Schema Module** - `PhoenixModuleTemplate.Schema.Example` with Ecto schema
- **Repository Module** - `PhoenixModuleTemplate.Repo` for database operations
- **Database Migration** - Create examples table with indexes
- **Test Suite** - Unit and integration tests with DataCase
- **Configuration** - Environment-specific configs for dev/test/prod

### Documentation
- Comprehensive README with usage examples
- API documentation with ExDoc
- Development setup instructions
- Template customization guide
- Contributing guidelines

### Development Tools
- Code formatting with `mix format`
- Static analysis with Credo
- Type checking with Dialyzer
- Test coverage with ExCoveralls
- Documentation generation with ExDoc
- Quality checks with `mix quality` alias

[Unreleased]: https://github.com/your-org/phoenix_module_template/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/phoenix_module_template/releases/tag/v0.1.0