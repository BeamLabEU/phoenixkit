defmodule PhoenixKitMinimal do
  @moduledoc """
  Minimal Phoenix authentication library.
  
  This library provides basic user management functions
  without Phoenix Application dependencies.
  """
  
  @version Mix.Project.config()[:version]
  
  def version, do: @version
  
  def hello do
    "PhoenixKit Minimal v#{@version} - Simple authentication library"
  end
end