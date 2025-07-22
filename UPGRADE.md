# PhoenixKit Upgrade Guide

Guide for upgrading PhoenixKit to the latest versions in existing projects.

## 🚀 Upgrading to v1.0.0+ (Automated Installation)

### Step 1: Update dependency

In `mix.exs` update the version:

```elixir
def deps do
  [
    # Old version:
    # {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v0.x.x"}
    
    # New version:
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
  ]
end
```

### Step 2: Update dependencies

```bash
mix deps.update phoenix_kit
mix deps.get
```

### Step 3: Zero-Configuration Setup

With v1.0.0+, PhoenixKit uses zero-configuration approach:

```elixir
# In lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Add this import

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user  # ← Add PhoenixKit auth
  end

  scope "/" do
    pipe_through :browser
    get "/", PageController, :home
  end

  # PhoenixKit authentication - ONE LINE!
  phoenix_kit()  # ← That's it!
end
```

### Step 4: Add Database Tables

```bash
# Generate migration file
mix ecto.gen.migration add_phoenix_kit_auth_tables
```

Copy the migration content from `deps/phoenix_kit/priv/repo/migrations/` or add this:

```elixir
defmodule YourApp.Repo.Migrations.AddPhoenixKitAuthTables do
  use Ecto.Migration

  def change do
    create table(:phoenix_kit_users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:phoenix_kit_users, [:email])

    create table(:phoenix_kit_users_tokens) do
      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:phoenix_kit_users_tokens, [:user_id])
    create unique_index(:phoenix_kit_users_tokens, [:context, :token])
  end
end
```

Then run:
```bash
mix ecto.migrate
```

### Step 5: Testing

```bash
# Check compilation
mix compile

# Run tests
mix test

# Start server
mix phx.server
```

## 🛠️ Troubleshooting Upgrade Issues

### Problem: Router conflicts

**Symptom:** Compilation errors in router.ex

**Solution:**
Ensure you have the correct import and plugin setup:
```elixir
# In lib/your_app_web/router.ex
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Must have this import

  pipeline :browser do
    # ... other plugs ...
    plug :fetch_current_scope_for_user  # ← Must have this plug
  end

  # Must have this macro call
  phoenix_kit()
end
```

### Problem: Migrations already exist

**Symptom:** Errors about duplicate migrations

**Solution:**
```bash
# Check existing migrations
ls priv/repo/migrations/ | grep phoenix_kit

# If you have old PhoenixKit migrations, remove them (careful!)
rm priv/repo/migrations/*phoenix_kit*

# Copy the correct migration from deps
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/

# Or manually create with the migration content above
mix ecto.gen.migration add_phoenix_kit_auth_tables
```

### Problem: Configuration conflicts

**Symptom:** Duplicate configuration in config.exs

**Solution:**
Ensure you have library mode configured:
```elixir
# config/config.exs
config :phoenix_kit, mode: :library
```

Remove any old PhoenixKit configuration lines. The zero-config approach needs minimal configuration.

## 📋 Upgrade Checklist

- [ ] Updated dependency in mix.exs to v1.0.0+
- [ ] Ran `mix deps.update phoenix_kit`
- [ ] Added `import BeamLab.PhoenixKitWeb.Router` to router
- [ ] Added `plug :fetch_current_scope_for_user` to browser pipeline
- [ ] Added `phoenix_kit()` macro to routes
- [ ] Created and ran database migrations
- [ ] Tested compilation
- [ ] Tested server startup  
- [ ] Verified authentication routes work (/phoenix_kit/register, /phoenix_kit/log-in)

## 🆘 Rolling Back to Previous Version

If something went wrong:

1. **Rollback dependency:**
   ```elixir
   {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v0.x.x"}
   ```

2. **Rollback migrations:**
   ```bash
   mix ecto.rollback --step 1
   ```

3. **Restore files from git:**
   ```bash
   git restore lib/your_app_web/router.ex
   git restore config/config.exs
   ```

## 📞 Support

For upgrade problems:

1. Check [GitHub Issues](https://github.com/BeamLabEU/phoenixkit/issues)
2. Create a new issue with problem details
3. Include output from `mix compile` and verify your router setup matches the zero-config pattern above