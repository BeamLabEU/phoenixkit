defmodule Mix.Tasks.PhoenixKit.Gen.Migration do
  @shortdoc "DEPRECATED: Use standard Phoenix migrations instead"

  @moduledoc """
  DEPRECATED: Use standard Phoenix migration approach.

  As of PhoenixKit v1.0.0, use the standard Phoenix pattern for database migrations.

  ## Migration Guide

      # OLD WAY (deprecated)
      mix phoenix_kit.gen.migration
      
      # NEW WAY (standard Phoenix)
      mix ecto.gen.migration add_phoenix_kit_auth_tables
      # Then copy from deps/phoenix_kit/priv/repo/migrations/

  This follows Phoenix best practices and standard migration patterns.
  """

  use Mix.Task

  @impl Mix.Task  
  def run(_args) do
    Mix.shell().info("""
    #{IO.ANSI.red()}DEPRECATED:#{IO.ANSI.reset()} mix phoenix_kit.gen.migration is no longer needed.
    
    Use standard Phoenix migration approach:
    
    1. Generate migration:
       #{IO.ANSI.cyan()}mix ecto.gen.migration add_phoenix_kit_auth_tables#{IO.ANSI.reset()}
    
    2. Copy migration content from:
       #{IO.ANSI.cyan()}deps/phoenix_kit/priv/repo/migrations/#{IO.ANSI.reset()}
    
    3. Run migration:
       #{IO.ANSI.cyan()}mix ecto.migrate#{IO.ANSI.reset()}
    
    This follows Phoenix best practices for database migrations.
    """)
  end
end