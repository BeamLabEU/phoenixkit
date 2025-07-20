ExUnit.start()

# Only configure Ecto sandbox in standalone mode
if BeamLab.PhoenixKit.standalone?() do
  Ecto.Adapters.SQL.Sandbox.mode(BeamLab.PhoenixKit.Repo, :manual)
end
