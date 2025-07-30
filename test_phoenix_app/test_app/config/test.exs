import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :test_app, TestAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "uBimycfjreeIoFhufeOntDNM8T4OOwWx9GXM1R0FVNsIvLdqEfTZpwuN5sqUIg7u",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure your database
config :test_app, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost", 
  database: "test_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
