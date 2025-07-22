import Config

# Database configuration template for Phoenix module development
# This configuration is used when developing the module as a standalone project
# When used as a dependency, the parent application handles database configuration

config :phoenix_module_template, PhoenixModuleTemplate.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_module_template_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Development logging
config :logger, :default_formatter, format: "[$level] $message\n"

# Optional: Configure test database if running module tests
config :phoenix_module_template, PhoenixModuleTemplate.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_module_template_test",
  pool: Ecto.Adapters.SQL.Sandbox
