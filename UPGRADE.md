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

### Step 3: Use new installation commands

Automated commands are now available:

```bash
# Check what will be updated (without changing files)
mix phoenix_kit.gen.routes --dry-run

# Update router configuration
mix phoenix_kit.gen.routes --force

# Update migrations (if new ones appeared)
mix phoenix_kit.gen.migration

# Full reinstall (careful!)
mix phoenix_kit.install --force
```

### Step 4: Verify changes

1. **Router configuration** - ensure routes are correctly updated:
   ```elixir
   # Should have:
   import BeamLab.PhoenixKitWeb.UserAuth,
     only: [fetch_current_scope_for_user: 2, redirect_if_user_is_authenticated: 2, require_authenticated_user: 2]
   
   # In browser pipeline:
   plug :fetch_current_scope_for_user
   ```

2. **Configuration** - check `config/config.exs`:
   ```elixir
   config :phoenix_kit, mode: :library
   ```

3. **Migrations** - run new migrations:
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
```bash
# Shows what needs to be fixed
mix phoenix_kit.gen.routes --dry-run

# Automatically fixes
mix phoenix_kit.gen.routes --force
```

### Problem: Migrations already exist

**Symptom:** Errors about duplicate migrations

**Solution:**
```bash
# Check existing migrations
ls priv/repo/migrations/ | grep phoenix_kit

# Remove old PhoenixKit migrations (careful!)
rm priv/repo/migrations/*phoenix_kit*

# Create new ones
mix phoenix_kit.gen.migration
```

### Problem: Configuration conflicts

**Symptom:** Duplicate configuration in config.exs

**Solution:**
```bash
# Remove old PhoenixKit lines from config/config.exs
# Then run:
mix phoenix_kit.install --no-migrations
```

## 📋 Upgrade Checklist

- [ ] Updated dependency in mix.exs
- [ ] Ran `mix deps.update phoenix_kit`
- [ ] Checked router configuration
- [ ] Updated migrations
- [ ] Checked configuration
- [ ] Tested compilation
- [ ] Tested server startup
- [ ] Verified authentication works

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
3. Include output from `mix compile` and `mix phoenix_kit.install --dry-run` commands