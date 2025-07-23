# PhoenixKit Integration Example

## Parent Application Router Setup

To integrate PhoenixKit authentication routes into your Phoenix application, follow these steps:

### 1. Add dependency in mix.exs

```elixir
def deps do
  [
    {:phoenix_kit, "~> 0.1.1"}
  ]
end
```

### 2. Configure your application

In `config/config.exs`:

```elixir
config :phoenix_kit,
  repo: YourApp.Repo
```

### 3. Update your router.ex

**Option A: Using the helper macro (recommended)**

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  
  # Import PhoenixKit integration helpers
  import PhoenixKitWeb.Integration

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", YourAppWeb do
    pipe_through :browser
    
    get "/", PageController, :home
  end

  # Add PhoenixKit authentication routes
  phoenix_kit_auth_routes("/phoenix_kit")
end
```

**Option B: Manual setup**

```elixir
defmodule YourAppWeb.Router do
  use YourAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", YourAppWeb do
    pipe_through :browser
    
    get "/", PageController, :home
  end

  # PhoenixKit authentication routes
  scope "/phoenix_kit" do
    pipe_through :browser
    forward "/", PhoenixKitWeb.AuthRouter
  end
end
```

### 4. Available Routes

After integration, the following routes will be available:

- `GET /phoenix_kit/register` - User registration
- `GET /phoenix_kit/log-in` - User login  
- `POST /phoenix_kit/log-in` - Login form submission
- `DELETE /phoenix_kit/log-out` - User logout
- `GET /phoenix_kit/reset-password` - Password reset request
- `GET /phoenix_kit/reset-password/:token` - Password reset form
- `GET /phoenix_kit/settings` - User settings
- `GET /phoenix_kit/settings/confirm-email/:token` - Email confirmation
- `GET /phoenix_kit/confirm/:token` - Account confirmation
- `GET /phoenix_kit/confirm` - Resend confirmation

### 5. Run migrations

```bash
mix ecto.migrate
```

## Troubleshooting

### Route not found error

If you get `no route found for GET /phoenix_kit/register`, make sure:

1. You've added the routes to your router (see step 3)
2. You've run `mix deps.get` to fetch the dependency
3. You've recompiled with `mix compile`
4. Your router includes either the macro or manual setup

### Missing configuration

If you get repo errors, ensure your config includes:

```elixir
config :phoenix_kit,
  repo: YourApp.Repo
```