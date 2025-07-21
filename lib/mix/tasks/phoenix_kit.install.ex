defmodule Mix.Tasks.PhoenixKit.Install do
  @shortdoc "DEPRECATED: PhoenixKit now works without installation"

  @moduledoc """
  DEPRECATED: This task is no longer needed.

  As of PhoenixKit v1.0.0, no installation is required. PhoenixKit works out-of-the-box
  with a simple one-line router integration.

  ## Migration Guide

      # OLD WAY (deprecated)
      mix phoenix_kit.install
      
      # NEW WAY (zero configuration)
      # 1. Add to your router.ex:
      import BeamLab.PhoenixKitWeb.Router
      phoenix_kit()
      
      # 2. Add migrations:
      mix ecto.gen.migration add_phoenix_kit_auth_tables
      # Copy from deps/phoenix_kit/priv/repo/migrations/
      
  The new approach follows Phoenix LiveDashboard pattern for better integration.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("""
    #{IO.ANSI.red()}DEPRECATED:#{IO.ANSI.reset()} mix phoenix_kit.install is no longer needed.
    
    #{IO.ANSI.green()}🎉 PhoenixKit v1.0.0+ works without installation!#{IO.ANSI.reset()}
    
    ## New Simple Integration:
    
    1. Add to your router.ex:
    
       #{IO.ANSI.cyan()}import BeamLab.PhoenixKitWeb.Router
       phoenix_kit()#{IO.ANSI.reset()}
    
    2. Generate migrations:
    
       #{IO.ANSI.cyan()}mix ecto.gen.migration add_phoenix_kit_auth_tables#{IO.ANSI.reset()}
       # Copy from: deps/phoenix_kit/priv/repo/migrations/
    
    3. Run migrations:
    
       #{IO.ANSI.cyan()}mix ecto.migrate#{IO.ANSI.reset()}
    
    That's it! No installation commands needed.
    Routes automatically available at /phoenix_kit/register, /phoenix_kit/log-in, etc.
    """)
  end
end