import Config

# Database configuration for testing
config :phoenix_module_template, PhoenixModuleTemplate.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_module_template_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
