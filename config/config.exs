import Config

# Configuration for PhoenixKit with web layer support

# Configure the database repository
config :phoenix_kit, ecto_repos: [PhoenixKit.Repo], repo: PhoenixKit.Repo

# Configure Ecto repository for development
config :phoenix_kit, PhoenixKit.Repo, adapter: Ecto.Adapters.Postgres

# Configure the endpoint
config :phoenix_kit, PhoenixKitWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: PhoenixKitWeb.ErrorHTML, json: PhoenixKitWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixKit.PubSub,
  live_view: [signing_salt: "UHVYcLyP"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.21.5",
  phoenix_kit: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  phoenix_kit: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure mailer
config :phoenix_kit, PhoenixKit.Mailer, adapter: Swoosh.Adapters.Local

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# PhoenixKit configuration
config :phoenix_kit,
  repo: PhoenixKit.Repo

# Layout configuration - defaults to PhoenixKit layouts
# Uncomment and modify to use your app's layouts:
# config :phoenix_kit,
#   layout: {MyAppWeb.Layouts, :app},
#   root_layout: {MyAppWeb.Layouts, :root},  # optional
#   page_title_prefix: "Auth"  # optional
