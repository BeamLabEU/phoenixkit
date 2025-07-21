defmodule Mix.Tasks.PhoenixKit.Gen.Routes do
  @shortdoc "DEPRECATED: Use the new router pattern instead"

  @moduledoc """
  DEPRECATED: Use the new router pattern for zero-configuration setup.

  As of PhoenixKit v1.0.0, route injection is no longer needed.

  ## Migration Guide

      # OLD WAY (deprecated)
      mix phoenix_kit.gen.routes
      
      # NEW WAY (zero configuration)
      # Add to your router.ex:
      import BeamLab.PhoenixKitWeb.Router
      phoenix_kit()

  The new approach follows Phoenix LiveDashboard pattern and works instantly.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("""
    #{IO.ANSI.red()}DEPRECATED:#{IO.ANSI.reset()} mix phoenix_kit.gen.routes is no longer needed.
    
    #{IO.ANSI.green()}🎉 PhoenixKit v1.0.0+ uses simple router pattern!#{IO.ANSI.reset()}
    
    Just add one line to your router:
    
       #{IO.ANSI.cyan()}import BeamLab.PhoenixKitWeb.Router
       phoenix_kit()#{IO.ANSI.reset()}
    
    Routes are automatically available at:
    - /phoenix_kit/register
    - /phoenix_kit/log-in
    - /phoenix_kit/log-out  
    - /phoenix_kit/settings
    
    No code injection needed! Follows Phoenix LiveDashboard pattern.
    """)
  end
end