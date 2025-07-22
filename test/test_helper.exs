# Test helper for PhoenixModuleTemplate

# Start ExUnit
ExUnit.start()

# Start the repository for testing
Ecto.Adapters.SQL.Sandbox.mode(PhoenixModuleTemplate.Repo, :manual)
