# BeamLab PhoenixKit

A modern Phoenix Framework authentication library with a beautiful UI design system built on Tailwind CSS and daisyUI components. **Zero configuration required**.

## Features

- 🚀 **Zero Configuration** - Works out of the box with one line of code
- 🔐 Complete Phoenix authentication system (login, registration, password reset)
- 🎨 Modern UI components with Tailwind CSS and daisyUI
- 🌓 Dark/Light theme support with system preference detection
- 📱 Responsive design
- 🔧 Library mode for seamless integration
- 🏷️ Git-based versioning system

## Quick Start

### 1. Add to Dependencies

```elixir
# mix.exs
def deps do
  [
    {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git", tag: "v1.0.0"}
  ]
end
```

### 2. Install Dependencies

```bash
mix deps.get
```

### 3. Add Routes (ONE LINE!)

```elixir
# lib/your_app_web/router.ex
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

### 4. Add Database Tables

```bash
# Generate migration file
mix ecto.gen.migration add_phoenix_kit_auth_tables

# Copy the migration content from deps/phoenix_kit/priv/repo/migrations/
# Then run:
mix ecto.migrate
```

### 5. Update Layout (Optional but Recommended)

```heex
<!-- In your app layout (app.html.heex) -->
<nav class="navbar bg-base-100">
  <div class="navbar-start">
    <.link navigate={~p"/"} class="btn btn-ghost text-xl">YourApp</.link>
  </div>
  <div class="navbar-end">
    <%= if @current_scope do %>
      <div class="dropdown dropdown-end">
        <div tabindex="0" role="button" class="btn btn-ghost">
          <%= @current_scope.user.email %>
        </div>
        <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
          <li><.link navigate={~p"/phoenix_kit/settings"}>Settings</.link></li>
          <li><.link href={~p"/phoenix_kit/log-out"} method="delete">Log out</.link></li>
        </ul>
      </div>
    <% else %>
      <.link navigate={~p"/phoenix_kit/log-in"} class="btn btn-ghost">Log in</.link>
      <.link navigate={~p"/phoenix_kit/register"} class="btn btn-primary">Sign up</.link>
    <% end %>
  </div>
</nav>
```

## 🎉 That's It!

Your authentication is ready! Available routes:

- `/phoenix_kit/register` - User registration
- `/phoenix_kit/log-in` - User login  
- `/phoenix_kit/log-out` - User logout
- `/phoenix_kit/settings` - User settings

## API Usage

```elixir
# User management
{:ok, user} = BeamLab.PhoenixKit.register_user(%{email: "user@example.com"})
user = BeamLab.PhoenixKit.get_user_by_email("user@example.com") 
{:ok, {user, _tokens}} = BeamLab.PhoenixKit.update_user_password(user, %{
  password: "new_password",
  password_confirmation: "new_password"
})

# In your controllers - authentication is automatic
def protected_action(conn, _params) do
  if conn.assigns.current_scope do
    user = conn.assigns.current_scope.user
    render(conn, :show, user: user)
  else
    redirect(conn, to: ~p"/phoenix_kit/log-in")
  end
end
```

## Advanced Configuration

### Simple Usage

```elixir
# Default usage - no parameters needed
phoenix_kit()
```

### Custom Options

```elixir
phoenix_kit(
  require_confirmation: true,
  session_validity_in_days: 30
)
```

Available options:
- `:require_confirmation` - Require email confirmation (default: false)
- `:session_validity_in_days` - Session validity period (default: 60)

### Database Migration Content

Copy this to your migration file:

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

## Authentication Plugs

Import `BeamLab.PhoenixKitWeb.UserAuth` to access:

- `fetch_current_scope_for_user` - Loads current user into `@current_scope`
- `require_authenticated_user` - Requires user to be logged in  
- `redirect_if_user_is_authenticated` - Redirects authenticated users away
- `log_in_user(conn, user, params)` - Programmatically log in user
- `log_out_user(conn)` - Programmatically log out user

## Magic Link Authentication

PhoenixKit supports passwordless login:

```elixir
# Send magic link email
BeamLab.PhoenixKit.Accounts.deliver_login_instructions(
  user, 
  &url(~p"/phoenix_kit/log-in/#{&1}")
)

# Login via magic link token  
{:ok, user} = BeamLab.PhoenixKit.Accounts.login_user_by_magic_link(token)
```

## Development

### Standalone Mode

Run PhoenixKit as a standalone application for development:

```bash
git clone https://github.com/BeamLabEU/phoenixkit.git
cd phoenixkit
mix setup
mix phx.server
```

Visit `http://localhost:4000` to see the demo application.

### Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Test specific functionality  
mix test test/phoenix_kit/accounts_test.exs
```

## Migration from Old Versions

If you were using the old installation method:

```elixir
# OLD WAY (deprecated)
BeamLab.PhoenixKit.install()  # No longer needed!
phoenix_kit_routes()          # Replace with phoenix_kit()

# NEW WAY (zero configuration)
import BeamLab.PhoenixKitWeb.Router
phoenix_kit()
```

The new approach follows Phoenix LiveDashboard pattern and requires no installation commands.

## Troubleshooting

### Common Issues

1. **Routes not working**: Ensure you imported `BeamLab.PhoenixKitWeb.Router` and added `fetch_current_scope_for_user` to your browser pipeline

2. **Compilation errors**: Make sure all dependencies are installed with `mix deps.get`

3. **Database errors**: Run `mix ecto.migrate` after copying the migration content

4. **Styles not loading**: Ensure your Tailwind configuration includes PhoenixKit paths

## Architecture

PhoenixKit follows Phoenix best practices:

### Library Mode
- Minimal dependencies for integration into existing Phoenix apps
- Uses your app's endpoint and configuration  
- Zero configuration required

### Standalone Mode  
- Full Phoenix application for development and demos
- Includes all dev tools and dependencies
- Used in `:dev` and `:test` environments automatically

## Components

### Authentication System
- User registration with email/password
- Secure login with bcrypt password hashing
- Magic link passwordless authentication
- Password reset functionality
- Session management with secure tokens
- Email confirmation workflows

### UI System
- Modern Tailwind CSS + daisyUI components
- Dark/light theme with system preference detection  
- Responsive design patterns
- Accessible form components
- Beautiful authentication pages

## API Reference

### Core Functions

```elixir
# Library information
BeamLab.PhoenixKit.version()     # => "1.0.0"
BeamLab.PhoenixKit.mode()        # => :library | :standalone
BeamLab.PhoenixKit.library?()    # => true | false

# User management
BeamLab.PhoenixKit.register_user(attrs)
BeamLab.PhoenixKit.get_user_by_email(email)
BeamLab.PhoenixKit.update_user_password(user, attrs)
```

### Full Accounts Context

```elixir
alias BeamLab.PhoenixKit.Accounts

# Advanced user queries
Accounts.get_user!(id)
Accounts.get_user_by_email_and_password(email, password)
Accounts.change_user_registration(user, attrs)

# Session management
token = Accounts.generate_user_session_token(user)  
{user, inserted_at} = Accounts.get_user_by_session_token(token)
Accounts.delete_user_session_token(token)

# Email management
Accounts.deliver_login_instructions(user, url_fn)
Accounts.deliver_user_confirmation_instructions(user, url_fn)
```

## Testing Your Integration

```elixir
# Test helper functions
defmodule YourApp.PhoenixKitHelpers do
  def create_user(attrs \\ %{}) do
    attrs = 
      %{email: "user#{System.unique_integer()}@example.com"}
      |> Map.merge(attrs)
    
    {:ok, user} = BeamLab.PhoenixKit.register_user(attrs)
    user
  end
  
  def log_in_user(conn, user) do
    token = BeamLab.PhoenixKit.Accounts.generate_user_session_token(user)
    
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end

# Example tests
test "requires authentication", %{conn: conn} do
  conn = get(conn, ~p"/protected")
  assert redirected_to(conn) == ~p"/phoenix_kit/log-in"
end

test "allows authenticated access", %{conn: conn} do
  user = create_user()
  conn = log_in_user(conn, user)
  
  conn = get(conn, ~p"/protected")
  assert html_response(conn, 200) =~ "Welcome"
end
```

## Versioning

PhoenixKit uses semantic versioning with Git tags:

- `v1.0.0` - Zero-configuration release with new router pattern
- `v0.2.1` - Library mode compatibility fixes  
- `v0.1.0` - Initial release

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
- Documentation: Built-in with `h BeamLab.PhoenixKit` in IEx

---

Built with ❤️ by [BeamLab](https://github.com/BeamLabEU)

**Zero configuration. Maximum productivity.** 🚀