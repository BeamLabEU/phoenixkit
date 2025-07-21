# PhoenixKit Testing Guide

Guide for testing PhoenixKit as a module in Phoenix applications.

## 🧪 Manual Testing

### Creating Test Project

```bash
# Create new Phoenix project
mix phx.new test_phoenix_kit --no-live --no-dashboard --no-mailer
cd test_phoenix_kit

# Add PhoenixKit to mix.exs
```

In `mix.exs` add dependency:

```elixir
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"},
    # ... other dependencies
  ]
end
```

### Step-by-Step Testing

1. **Install dependencies:**
   ```bash
   mix deps.get
   ```

2. **Compile project:**
   ```bash
   mix compile
   ```

3. **Check Mix tasks availability:**
   ```bash
   mix help | grep phoenix_kit
   ```
   
   Should show:
   ```
   mix phoenix_kit.gen.migration # Generates PhoenixKit database migrations
   mix phoenix_kit.gen.routes    # Generates PhoenixKit authentication routes in your router
   mix phoenix_kit.install       # Installs PhoenixKit authentication library into your Phoenix application
   ```

4. **Generate migrations:**
   ```bash
   mix phoenix_kit.gen.migration
   ```
   
   Check:
   ```bash
   ls priv/repo/migrations/*phoenix_kit*
   ```

5. **Create DB and run migrations:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

6. **Test router (dry-run):**
   ```bash
   mix phoenix_kit.gen.routes --dry-run
   ```

7. **Generate router configuration:**
   ```bash
   mix phoenix_kit.gen.routes --force
   ```
   
   Check:
   ```bash
   grep -A 10 -B 5 "BeamLab.PhoenixKitWeb" lib/test_phoenix_kit_web/router.ex
   ```

8. **Full installation:**
   ```bash
   mix phoenix_kit.install --force
   ```

9. **Final compilation:**
   ```bash
   mix compile
   ```

10. **Start server:**
    ```bash
    mix phx.server
    ```

### Browser Testing

1. Open http://localhost:4000
2. Navigate to http://localhost:4000/auth/register
3. Register a user
4. Try login at http://localhost:4000/auth/log-in
5. Check settings at http://localhost:4000/auth/settings

## 🔧 Troubleshooting

### Problem: Mix tasks not found

**Cause:** PhoenixKit not compiled or not loaded.

**Solution:**
```bash
mix deps.compile phoenix_kit --force
mix compile
```

### Problem: Router errors

**Cause:** Conflict with existing routes.

**Solution:**
```bash
# See what will be changed
mix phoenix_kit.gen.routes --dry-run

# Force update
mix phoenix_kit.gen.routes --force
```

### Problem: Migration errors

**Cause:** Migrations already exist.

**Solution:**
```bash
# Check existing migrations
ls priv/repo/migrations/

# Remove conflicting ones (careful!)
rm priv/repo/migrations/*phoenix_kit*

# Generate again
mix phoenix_kit.gen.migration
```

### Problem: Compilation fails

**Cause:** Missing dependencies or conflicts.

**Solution:**
```bash
# Clean and rebuild
mix deps.clean --all
mix deps.get
mix compile
```

## 📋 Testing Checklist

- [ ] Test Phoenix project created
- [ ] PhoenixKit added to dependencies
- [ ] `mix deps.get` successful
- [ ] `mix compile` without errors
- [ ] Mix tasks `phoenix_kit.*` available
- [ ] Migrations generate
- [ ] Database creates and migrates
- [ ] Router configures
- [ ] Project compiles after changes
- [ ] Server starts
- [ ] Registration page works
- [ ] Login page works
- [ ] Settings page works

## 🚀 Quick Test

For rapid verification of main functionality:

```bash
# Create project
mix phx.new quick_test --no-live --no-dashboard --no-mailer
cd quick_test

# Add to mix.exs:
# {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}

# Install
mix deps.get
mix compile

# Check tasks
mix help | grep phoenix_kit

# Install PhoenixKit
mix phoenix_kit.install
mix ecto.create
mix ecto.migrate

# Run
mix phx.server
# Open http://localhost:4000/auth/register
```

## 📞 Help

If you encounter problems:

1. Make sure you're using Phoenix 1.8+
2. Verify all dependencies are installed
3. Check error logs
4. Create a GitHub issue with details

### Diagnostic Logs

```bash
# Check versions
mix --version
mix phx.server --version

# Check dependencies
mix deps.tree

# Check compilation
mix compile --verbose

# Check routes
mix phx.routes
```