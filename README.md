# Phoenix Module Template

> A professional template for developing Phoenix modules with PostgreSQL support

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_module_template.svg)](https://hex.pm/packages/phoenix_module_template)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/phoenix_module_template)
[![License](https://img.shields.io/hexpm/l/phoenix_module_template.svg)](LICENSE)

## Overview

Phoenix Module Template provides a solid foundation for creating reusable Phoenix modules with PostgreSQL integration. This template follows Phoenix best practices and includes everything you need to build, test, and publish a professional Phoenix module.

### Features

- 🚀 **Library-First Architecture** - No circular dependencies when used as a dependency
- 🗄️ **PostgreSQL Integration** - Built-in Ecto support with migrations and schemas
- 🧪 **Professional Testing** - Complete test suite with database integration
- 📚 **Documentation Ready** - ExDoc configuration and comprehensive docs
- 📦 **Hex Publishing** - Ready for Hex.pm with proper package configuration
- 🛠️ **Development Tools** - Credo, Dialyzer, and code formatting configured

## Installation

Add `phoenix_module_template` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_module_template, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Setup

Configure the module to use your application's repository:

```elixir
# config/config.exs
config :phoenix_module_template,
  repo: MyApp.Repo
```

### API Usage

```elixir
# Create an example
{:ok, example} = PhoenixModuleTemplate.create_example(%{
  name: "My Example",
  description: "A sample example"
})

# List all examples
examples = PhoenixModuleTemplate.list_examples()

# Get a specific example
example = PhoenixModuleTemplate.get_example(1)

# Update an example
{:ok, updated_example} = PhoenixModuleTemplate.update_example(example, %{
  name: "Updated Name"
})

# Delete an example
{:ok, _} = PhoenixModuleTemplate.delete_example(example)
```

### Advanced Features

#### Search Examples

```elixir
# Search by name or description
results = PhoenixModuleTemplate.Context.search_examples("search term")
```

#### Pagination

```elixir
# Get paginated results
%{examples: examples, total_count: count} = 
  PhoenixModuleTemplate.Context.list_examples_paginated(page: 1, per_page: 10)
```

## Database Setup

### Migration

The module includes a migration for the examples table. Copy it to your application:

```bash
cp deps/phoenix_module_template/priv/repo/migrations/*.exs priv/repo/migrations/
mix ecto.migrate
```

### Schema

The module uses the `phoenix_module_template_examples` table with the following structure:

- `id` - Primary key
- `name` - String (required, unique)
- `description` - Text (optional)
- `active` - Boolean (default: true)
- `metadata` - JSONB (optional)
- `inserted_at` - Timestamp
- `updated_at` - Timestamp

## Development

### Setup

```bash
mix setup
```

### Running Tests

```bash
mix test
```

### Code Quality

```bash
# Run all quality checks
mix quality

# Format code
mix format

# Static analysis
mix credo --strict
mix dialyzer
```

### Documentation

```bash
mix docs
```

## Using This Template

This repository serves as a template for creating your own Phoenix modules. Here's how to adapt it:

### 1. Rename the Module

Replace all instances of:
- `PhoenixModuleTemplate` → `YourModuleName`
- `phoenix_module_template` → `your_module_name`
- Update table names and prefixes accordingly

### 2. Customize the Schema

Modify `lib/phoenix_module_template/schema/example.ex` to match your domain:
- Change field names and types
- Add validations and constraints
- Update migration accordingly

### 3. Implement Your Business Logic

Update `lib/phoenix_module_template/context.ex` with your specific:
- CRUD operations
- Business rules
- Query logic

### 4. Update Configuration

Modify:
- `mix.exs` - Update package info, dependencies
- `README.md` - Replace with your module's documentation
- `config/*.exs` - Adjust for your needs

## Configuration Options

```elixir
config :phoenix_module_template,
  # Required: Your application's Ecto repository
  repo: MyApp.Repo,
  
  # Optional: Custom settings for your module
  custom_setting: "value"
```

## Testing Strategy

The template includes comprehensive testing patterns:

- **Unit Tests** - For business logic and schemas
- **Integration Tests** - For database operations  
- **Property Tests** - For data validation
- **Fixtures** - For test data generation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run quality checks: `mix quality`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

---

Built with ❤️ for the Phoenix community