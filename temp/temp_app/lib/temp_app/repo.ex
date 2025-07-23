defmodule TempApp.Repo do
  use Ecto.Repo,
    otp_app: :temp_app,
    adapter: Ecto.Adapters.Postgres
end