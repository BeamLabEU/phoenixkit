# BeamLab PhoenixKit

A comprehensive Phoenix Framework authentication library with a modern UI design system built on Tailwind CSS and daisyUI components.

## Features

- 🔐 Complete Phoenix authentication system (login, registration, password reset)
- 🎨 Modern UI components with Tailwind CSS and daisyUI
- 🌓 Dark/Light theme support
- 📱 Responsive design
- 🔧 Dual mode: Standalone application or Library dependency
- 🏷️ Git-based versioning system

## Installation

### As a Git Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

### Library Usage

```elixir
# In your application configuration
config :phoenix_kit, mode: :library

# Access the main API
BeamLab.PhoenixKit.version()
BeamLab.PhoenixKit.mode()

# User management functions
BeamLab.PhoenixKit.register_user(%{email: "user@example.com"})
BeamLab.PhoenixKit.get_user_by_email("user@example.com")
```

## Development

### Standalone Mode

Clone and run as a standalone Phoenix application:

```bash
git clone https://github.com/BeamLabEU/phoenixkit.git
cd phoenixkit
mix setup
mix phx.server
```

Visit `http://localhost:4000` to see the application.

### Available Commands

- `mix setup` - Complete project setup
- `mix deps.get` - Install dependencies
- `mix ecto.setup` - Setup database
- `mix phx.server` - Start development server
- `mix test` - Run tests

## Architecture

PhoenixKit supports two modes:

### Standalone Mode
- Full Phoenix application with web interface
- Development and demo purposes
- All dependencies included

### Library Mode  
- Core functionality only
- Minimal dependencies
- Suitable for integration into existing projects

## Components

### Authentication System
- User registration and login
- Password reset functionality
- Magic link authentication
- Session management

### UI Components
- Modern Tailwind CSS styling
- daisyUI component system
- Dark/light theme toggle
- Responsive design patterns

## API Documentation

### Main Module: `BeamLab.PhoenixKit`

```elixir
# Version information
BeamLab.PhoenixKit.version()  # Returns current version

# Mode detection
BeamLab.PhoenixKit.mode()        # :standalone or :library
BeamLab.PhoenixKit.standalone?() # true/false
BeamLab.PhoenixKit.library?()    # true/false

# User management (delegates to Accounts context)
BeamLab.PhoenixKit.register_user(attrs)
BeamLab.PhoenixKit.get_user!(id)
BeamLab.PhoenixKit.get_user_by_email(email)
BeamLab.PhoenixKit.update_user_password(user, attrs)
```

## Configuration

### Library Mode Configuration

```elixir
# config/config.exs
config :phoenix_kit, mode: :library

# Database configuration (if using Ecto features)
config :phoenix_kit, BeamLab.PhoenixKit.Repo,
  username: "postgres",
  password: "postgres",
  database: "your_app_dev",
  hostname: "localhost"
```

## Versioning

This project uses semantic versioning with Git tags:

- `v1.0.0` - Stable release with library mode support
- `v0.2.1` - Library mode compatibility fixes
- `v0.1.0` - Initial release
- Tags follow the format `vMAJOR.MINOR.PATCH`

To use a specific version:

```elixir
{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
```

## License

Copyright (c) 2024 BeamLab

This project is licensed under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `mix test`
5. Submit a pull request

## Support

For issues and questions:
- GitHub Issues: https://github.com/BeamLabEU/phoenixkit/issues
- Documentation: https://hexdocs.pm/phoenix_kit/

---

Built with ❤️ by [BeamLab](https://github.com/BeamLabEU)
