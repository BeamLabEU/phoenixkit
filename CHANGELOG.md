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