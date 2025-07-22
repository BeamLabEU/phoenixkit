defmodule PhoenixModuleTemplateTest do
  @moduledoc """
  Tests for the main PhoenixModuleTemplate API module.
  """

  use ExUnit.Case
  doctest PhoenixModuleTemplate

  describe "version/0" do
    test "returns the correct version" do
      assert PhoenixModuleTemplate.version() == "0.1.0"
    end
  end

  describe "config/0" do
    test "returns application configuration" do
      config = PhoenixModuleTemplate.config()
      assert is_list(config)
    end
  end

  describe "repo/0" do
    test "returns the configured repository" do
      repo = PhoenixModuleTemplate.repo()
      assert is_atom(repo)
      assert Code.ensure_loaded?(repo)
    end
  end
end
