# PhoenixKit Installation Guide

Complete installation guide for PhoenixKit authentication library with zero-config setup.

## Quick Installation (Recommended)

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, "~> 0.1.5"}
    # Or for latest from GitHub:
    # {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
  ]
end
```

### 2. Install Dependencies and PhoenixKit

```bash
mix deps.get
mix phoenix_kit.install
```

**The `mix phoenix_kit.install` command automatically:**
- Detects your Ecto repository (`MyApp.Repo`)
- Generates timestamped migration files
- Adds configuration to `config/config.exs`
- Shows next steps for router integration

### 3. Add Routes and Authentication

```elixir
# lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration
  import PhoenixKitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # Add PhoenixKit user fetching
    plug :fetch_current_user
  end

  # Your existing routes...

  # Add PhoenixKit authentication routes
  phoenix_kit_auth_routes("/auth")
end
```

### 4. Run Migration

```bash
mix ecto.migrate
```

### 5. Start Your Application

```bash
mix phx.server
```

🎉 **Done!** Visit `http://localhost:4000/auth/register` to test PhoenixKit.

## Advanced Installation Options

### Custom Repository

If your app has multiple repositories or non-standard naming:

```bash
mix phoenix_kit.install --repo MyApp.CustomRepo
```

### Custom URL Prefix

```elixir
# Use different URL prefix
phoenix_kit_auth_routes("/authentication")
phoenix_kit_auth_routes("/users")
```

### PostgreSQL Schema Isolation

For apps requiring table isolation:

```bash
mix phoenix_kit.install --prefix "auth" --create-schema
```

This creates tables in the `auth` schema instead of `public`.

## Manual Installation

If automatic installation doesn't work:

### 1. Manual Migration Generation

```elixir
# Create migration manually: priv/repo/migrations/TIMESTAMP_add_phoenix_kit_auth_tables.exs
defmodule YourApp.Repo.Migrations.AddPhoenixKitAuthTables do
  use Ecto.Migration

  def up, do: PhoenixKit.Migration.up()
  def down, do: PhoenixKit.Migration.down()
end
```

### 2. Manual Configuration

```elixir
# config/config.exs
config :phoenix_kit, repo: YourApp.Repo
```

## Zero-Config Setup Details

PhoenixKit's auto-setup system (inspired by Oban) automatically:

1. **Repository Detection**: Scans `Mix.Project.config()[:ecto_repos]`
2. **Configuration**: Adds `config :phoenix_kit, repo: YourApp.Repo`
3. **Schema Migrations**: Runs versioned migrations automatically
4. **Error Recovery**: Handles database connection issues gracefully

### How Auto-Setup Works

```elixir
# On first request to PhoenixKit routes:
PhoenixKit.AutoSetup.ensure_setup!()
# 1. Detects repo from configuration or auto-detection
# 2. Validates repo has PostgreSQL adapter
# 3. Runs schema migrations if needed
# 4. Records version in phoenix_kit_schema_versions table
```

## Troubleshooting

### Common Issues

**No repository configured**
```
[error] No repository configured for PhoenixKit
```
**Solution**: Run `mix phoenix_kit.install` or add manual config:
```elixir
config :phoenix_kit, repo: YourApp.Repo
```

**Migration failed**
```
[error] Schema migration to 1.0.0 failed
```
**Solutions**:
- Check database connection and credentials
- Ensure PostgreSQL user has CREATE EXTENSION privileges
- Verify database exists: `mix ecto.create`

**Route not found**
```
ERROR: No route found for GET /auth/register
```
**Solutions**:
- Import `PhoenixKitWeb.Integration` in router
- Add `phoenix_kit_auth_routes("/auth")` to router
- Ensure browser pipeline includes `:fetch_current_user`

**Auto-detection failed**
```
[error] Could not detect parent Phoenix application
```
**Solutions**:
- Use explicit repo: `mix phoenix_kit.install --repo MyApp.Repo`
- Check your app has `:ecto_repos` configured in `mix.exs`

### Debug Mode

Enable detailed logging:

```elixir
# config/dev.exs
config :logger, level: :debug

# Start server and check logs
mix phx.server
```

### Manual Override

Skip auto-setup by configuring explicitly:

```elixir
# config/config.exs
config :phoenix_kit,
  repo: MyApp.Repo,
  # Disable auto-setup
  auto_setup: false
```

## Database Schema Details

### Tables Created

**phoenix_kit** (Users):
```sql
CREATE TABLE phoenix_kit (
  id bigserial PRIMARY KEY,
  email citext NOT NULL UNIQUE,
  hashed_password varchar(255) NOT NULL,
  confirmed_at timestamp,
  inserted_at timestamp NOT NULL DEFAULT NOW(),
  updated_at timestamp NOT NULL DEFAULT NOW()
);
```

**phoenix_kit_tokens** (Authentication tokens):
```sql
CREATE TABLE phoenix_kit_tokens (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES phoenix_kit(id) ON DELETE CASCADE,
  token bytea NOT NULL,
  context varchar(255) NOT NULL,
  sent_to varchar(255),
  inserted_at timestamp NOT NULL DEFAULT NOW()
);
```

**phoenix_kit_schema_versions** (Migration tracking):
```sql
CREATE TABLE phoenix_kit_schema_versions (
  id bigserial PRIMARY KEY,
  version varchar(50) NOT NULL,
  applied_at timestamp NOT NULL DEFAULT NOW(),
  inserted_at timestamp NOT NULL DEFAULT NOW()
);
```

### Schema Prefixes

When using `--prefix auth`:

```bash
mix phoenix_kit.install --prefix "auth" --create-schema
```

Tables are created as:
- `auth.phoenix_kit`
- `auth.phoenix_kit_tokens` 
- `auth.phoenix_kit_schema_versions`

## Integration Examples

### With Guardian

```elixir
# Use PhoenixKit for registration/login, Guardian for sessions
phoenix_kit_auth_routes("/auth")

# In your Guardian implementation
def subject_for_token(%PhoenixKit.Accounts.User{} = user, _claims) do
  {:ok, to_string(user.id)}
end
```

### With LiveView

```elixir
# In your LiveView
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  
  on_mount {PhoenixKitWeb.UserAuth, :ensure_authenticated}
  
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok, assign(socket, user: current_user)}
  end
end
```

### With API Authentication

```elixir
# Use PhoenixKit for web auth, separate API tokens
pipeline :api_authenticated do
  plug :accepts, ["json"]
  plug MyApp.APIAuth  # Your API auth
end

pipeline :browser_authenticated do
  pipe_through :browser
  plug :require_authenticated_user  # PhoenixKit auth
end
```

## Environment Configuration

### Development
```elixir
# config/dev.exs
config :phoenix_kit, repo: MyApp.Repo

# Optional: Custom development settings
config :phoenix_kit,
  repo: MyApp.Repo,
  auto_setup: true,  # Enable auto-setup (default)
  prefix: "public"   # Default schema
```

### Production
```elixir
# config/prod.exs  
config :phoenix_kit, repo: MyApp.Repo

# Production-specific settings
config :phoenix_kit,
  repo: MyApp.Repo,
  auto_setup: false,  # Disable auto-setup in production
  mailer: MyApp.Mailer
```

### Testing
```elixir
# config/test.exs
config :phoenix_kit, repo: MyApp.Repo

# Test-specific configuration
config :phoenix_kit,
  repo: MyApp.Repo,
  # Use test database
  auto_setup: true
```