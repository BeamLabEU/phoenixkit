ExUnit.start()

# Configure Ecto sandbox for tests
Ecto.Adapters.SQL.Sandbox.mode(BeamLab.PhoenixKit.Repo, :manual)
