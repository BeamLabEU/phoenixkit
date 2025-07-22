import Config

# Configuration for PhoenixModuleTemplate

# Configure the database repository
# When used as a standalone module for development
config :phoenix_module_template,
  ecto_repos: [PhoenixModuleTemplate.Repo]

# Configure Ecto repository for development
config :phoenix_module_template, PhoenixModuleTemplate.Repo, adapter: Ecto.Adapters.Postgres

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
