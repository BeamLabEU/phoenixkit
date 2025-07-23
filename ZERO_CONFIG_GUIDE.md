# PhoenixKit Zero-Config Installation

PhoenixKit is designed for **zero-configuration** setup. Just add the dependency and use it!

## 🚀 Super Simple Installation

### 1. Add Dependency

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}
  ]
end
```

### 2. Install & Add Routes

```bash
mix deps.get
```

```elixir
# lib/your_app_web/router.ex  
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import PhoenixKitWeb.Integration  # ← Add this line

  # ... your existing pipelines ...

  phoenix_kit_auth_routes()  # ← Add this line (uses /phoenix_kit prefix)
end
```

### 3. That's it! 🎉

Start your server and visit:
- `http://localhost:4000/phoenix_kit/register`
- `http://localhost:4000/phoenix_kit/log_in`

## ✨ What Happens Automatically

When you first access PhoenixKit routes, it **automatically**:

1. **🔍 Detects your app's Ecto.Repo** - No manual configuration needed
2. **📊 Creates database tables** - `phoenix_kit`, `phoenix_kit_tokens`, `phoenix_kit_schema_versions`
3. **⚙️ Configures itself** - Uses your existing database connection
4. **🎯 Ready to use** - Authentication works immediately
5. **📋 Tracks schema version** - For safe upgrades when you update PhoenixKit

## 🛠️ Zero-Config Features

- **Auto Repo Detection** - Finds `YourApp.Repo` automatically
- **Auto Table Creation** - Creates auth tables on first use  
- **Auto Database Setup** - Uses your existing PostgreSQL connection
- **Auto Configuration** - No config files to edit
- **Auto Migration** - No `mix ecto.migrate` needed

## 📋 Requirements

PhoenixKit automatically works with:
- ✅ Phoenix Framework
- ✅ Ecto with PostgreSQL
- ✅ Standard Phoenix project structure

## 🔧 Advanced Usage (Optional)

If you need custom prefix or configuration:

```elixir
# Custom route prefix
phoenix_kit_auth_routes("/auth")  # uses /auth instead of /phoenix_kit

# Custom config (optional)
config :phoenix_kit,
  repo: MyApp.CustomRepo,
  table_prefix: "users"  # custom table names
```

## 🐛 Troubleshooting

If auto-setup fails, check:

1. **Database Connection** - Ensure your Phoenix app can connect to PostgreSQL
2. **Ecto Repository** - Make sure you have a working `YourApp.Repo`
3. **Database Permissions** - PostgreSQL user needs CREATE TABLE permissions

### Manual Setup

If automatic setup fails, you can set up tables manually:

```bash
# In your Phoenix application directory
mix phoenix_kit.setup
```

Or with a specific repository:

```bash
mix phoenix_kit.setup --repo MyApp.Repo
```

### Common Issues

**"Table does not exist" errors:**
- Run `mix phoenix_kit.setup` to create tables manually
- Check PostgreSQL logs for permission errors
- Ensure `citext` extension is available: `CREATE EXTENSION IF NOT EXISTS citext;`

**Repository not detected:**
- Make sure your app follows Phoenix naming conventions (`MyApp.Repo`)
- Specify repository manually in config: `config :phoenix_kit, repo: MyApp.Repo`

**Database connection refused:**
- Verify PostgreSQL is running
- Check database configuration in your Phoenix app
- Test with `mix ecto.create` or `mix ecto.migrate`

## 🎯 Migration from Manual Setup

If you previously installed PhoenixKit manually:

1. Remove old config from `config/config.exs` 
2. Remove manual migrations
3. Just use `phoenix_kit_auth_routes()` - it will auto-configure!

## 🔄 Safe Library Updates

PhoenixKit automatically handles schema migrations when you update to newer versions:

### Update Process
```elixir
# 1. Update version in mix.exs
{:phoenix_kit, "~> 2.0"}

# 2. Get dependencies  
mix deps.get

# 3. Restart server - migration happens automatically!
mix phx.server
```

### Manual Migration Control (Production)
```bash
# Check what migration is needed
mix phoenix_kit.migrate --status

# Apply migration manually  
mix phoenix_kit.migrate
```

**✅ Your user data is always preserved during updates!**

For detailed information, see [SCHEMA_VERSIONING.md](SCHEMA_VERSIONING.md)

---

**That's the power of zero-config!** 🚀

No migrations to run, no config to edit, no manual setup steps.
Just add the routes and start authenticating users!