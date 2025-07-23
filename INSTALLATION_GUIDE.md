# PhoenixKit Installation Guide

## Git Dependency Installation

When installing PhoenixKit as a git dependency, follow these steps to properly set up the database migrations.

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
  ]
end
```

### 2. Install Dependencies

```bash
mix deps.get
```

### 3. Install Migrations

PhoenixKit provides a mix task to copy migrations to your application:

```bash
mix phoenix_kit.install
```

This will:
- Copy the authentication migration files to your `priv/repo/migrations/` directory
- Generate proper timestamps for the migrations
- Provide setup instructions

### 4. Configure Repository

Add PhoenixKit configuration to use your application's repository:

```elixir
# config/config.exs
config :phoenix_kit,
  repo: YourApp.Repo
```

### 5. Add Routes

Import PhoenixKit routes in your router:

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration

  # ... your existing pipelines ...

  # Add PhoenixKit authentication routes (default /phoenix_kit prefix)
  phoenix_kit_auth_routes()
end
```

### 6. Run Migration

```bash
mix ecto.migrate
```

### 7. Start Your Application

```bash
mix phx.server
```

Now you can access the authentication forms at:
- `http://localhost:4000/phoenix_kit/register`
- `http://localhost:4000/phoenix_kit/log_in`

## Manual Migration Installation

If the mix task doesn't work, you can manually copy the migration:

1. Find the migration file in `deps/phoenix_kit/priv/repo/migrations/`
2. Copy `*_create_phoenix_kit_auth_tables.exs` to your `priv/repo/migrations/`
3. Rename it with a new timestamp: `20240101120000_create_phoenix_kit_auth_tables.exs`
4. Run `mix ecto.migrate`

## Troubleshooting

### Migration Not Found
- Ensure PhoenixKit is properly added to dependencies
- Run `mix deps.get` to fetch the dependency
- Check that `deps/phoenix_kit/priv/repo/migrations/` contains the migration files

### Repo Configuration Error
- Make sure you've configured `:phoenix_kit` to use your app's repo
- Verify your repo is properly configured in `config/config.exs`

### Route Errors
- Ensure you've imported `PhoenixKitWeb.Integration` in your router
- Check that your browser pipeline includes session and CSRF protection

## Database Tables

PhoenixKit creates these tables:
- `phoenix_kit` - User accounts with email and hashed password
- `phoenix_kit_tokens` - Authentication tokens for sessions and confirmations

## Custom Configuration

You can customize the table prefix by modifying the migration before running it, or use a different configuration for different environments.