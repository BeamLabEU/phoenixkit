import Config
config :phoenix_kit, PhoenixKit.Mailer, adapter: Swoosh.Adapters.Local

# Database configuration for PhoenixKit development
config :phoenix_kit, PhoenixKit.Repo,
  username: "postgres",
  password: "yourrandompassword",
  hostname: "172.18.0.2",
  database: "phoenix_kit_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure the endpoint
config :phoenix_kit, PhoenixKitWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "YqF5ZG5h7JgS8N1w2VbOqLUY8I+8V8f+iQlC8tO7a8gYK8e8n+x4iP+YsEQ2J8GF",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:phoenix_kit, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:phoenix_kit, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :phoenix_kit, PhoenixKitWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/phoenix_kit_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :phoenix_kit, dev_routes: true

# Development logging
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
