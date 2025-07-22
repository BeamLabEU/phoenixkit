defmodule BeamLab.PhoenixKit do
  @moduledoc """
  BeamLab.PhoenixKit - Simple authentication library for Phoenix.
  
  This library provides basic user management and authentication
  functions that can be integrated into Phoenix applications.
  """
  
  @version Mix.Project.config()[:version]
  
  def version, do: @version
  
  def hello do
    "PhoenixKit v#{@version} - Authentication library ready!"
  end
end
