import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Database configuration for testing
config :phoenix_kit, PhoenixKit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_kit_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure the endpoint for testing
config :phoenix_kit, PhoenixKitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XGg6yUJ1Z9Jp9pQD0w7L8r+JK+8cM8t7cL1N9R5u2rUu7bE9iF+wNqS7vV9n1kBh",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
