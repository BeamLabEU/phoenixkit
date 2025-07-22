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

3. **Check zero-configuration setup:**
   ```elixir
   # Verify PhoenixKit is available
   iex -S mix
   BeamLab.PhoenixKit.version()
   ```
   
   Should return:
   ```
   "1.0.0"
   ```

4. **Add database tables:**
   ```bash
   # Generate migration file
   mix ecto.gen.migration add_phoenix_kit_auth_tables
   ```
   
   Copy migration content from `deps/phoenix_kit/priv/repo/migrations/` or add the tables manually. Check:
   ```bash
   ls priv/repo/migrations/*phoenix_kit*
   ```

5. **Create DB and run migrations:**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

6. **Configure router (zero-configuration):**
   Edit `lib/test_phoenix_kit_web/router.ex`:
   ```elixir
   defmodule TestPhoenixKitWeb.Router do
     use TestPhoenixKitWeb, :router
     import BeamLab.PhoenixKitWeb.Router  # ← Add this import

     pipeline :browser do
       plug :accepts, ["html"]
       plug :fetch_session
       plug :fetch_live_flash
       plug :put_root_layout, html: {TestPhoenixKitWeb.Layouts, :root}
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
   
   Verify setup:
   ```bash
   grep -A 5 "phoenix_kit()" lib/test_phoenix_kit_web/router.ex
   ```

7. **Final compilation:**
   ```bash
   mix compile
   ```

8. **Start server:**
    ```bash
    mix phx.server
    ```

### Browser Testing

1. Open http://localhost:4000
2. Navigate to http://localhost:4000/phoenix_kit/register
3. Register a user
4. Try login at http://localhost:4000/phoenix_kit/log-in
5. Check settings at http://localhost:4000/phoenix_kit/settings

## 🔧 Troubleshooting

### Problem: PhoenixKit modules not found

**Cause:** PhoenixKit not compiled or not loaded.

**Solution:**
```bash
mix deps.compile phoenix_kit --force
mix compile

# Verify availability:
iex -S mix
BeamLab.PhoenixKit.version()
```

### Problem: Router errors

**Cause:** Missing imports or incorrect configuration.

**Solution:**
Ensure your router has the correct setup:
```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  import BeamLab.PhoenixKitWeb.Router  # ← Must have this

  pipeline :browser do
    # ... other plugs ...
    plug :fetch_current_scope_for_user  # ← Must have this
  end

  # Must have this macro call
  phoenix_kit()
end
```

### Problem: Migration errors

**Cause:** Migrations already exist or missing tables.

**Solution:**
```bash
# Check existing migrations
ls priv/repo/migrations/

# If you have old ones, remove them (careful!)
rm priv/repo/migrations/*phoenix_kit*

# Copy correct migration from deps:
cp deps/phoenix_kit/priv/repo/migrations/* priv/repo/migrations/

# Or create manually:
mix ecto.gen.migration add_phoenix_kit_auth_tables
# Then add the migration content from README.md
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
- [ ] PhoenixKit modules accessible (`BeamLab.PhoenixKit.version()`)
- [ ] Database migration created and applied
- [ ] Router configured with zero-config approach
- [ ] `phoenix_kit()` macro added to routes
- [ ] Project compiles after router changes
- [ ] Server starts
- [ ] Registration page works (/phoenix_kit/register)
- [ ] Login page works (/phoenix_kit/log-in)
- [ ] Settings page works (/phoenix_kit/settings)

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

# Create database
mix ecto.create

# Add database migration
mix ecto.gen.migration add_phoenix_kit_auth_tables
# Copy migration content from deps/phoenix_kit/priv/repo/migrations/
# Or add tables manually as shown in README.md

# Run migration
mix ecto.migrate

# Update router.ex with zero-config setup:
# import BeamLab.PhoenixKitWeb.Router
# Add plug :fetch_current_scope_for_user to browser pipeline  
# Add phoenix_kit() macro

# Run
mix phx.server
# Open http://localhost:4000/phoenix_kit/register
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
elixir --version

# Check dependencies
mix deps.tree

# Check PhoenixKit availability
iex -S mix
BeamLab.PhoenixKit.version()

# Check compilation
mix compile --verbose

# Check routes (should see /phoenix_kit/* routes)
mix phx.routes
```