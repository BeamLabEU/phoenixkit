defmodule TestAutoSetup.Repo do
  use Ecto.Repo,
    otp_app: :test_auto_setup,
    adapter: Ecto.Adapters.Postgres
end