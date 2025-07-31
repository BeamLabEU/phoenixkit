#!/usr/bin/env elixir

# Test script for PhoenixKit Professional Installer functionality

Mix.start()
Mix.shell(Mix.Shell.Process)

defmodule ProInstallerTest do
  @moduledoc """
  Test the PhoenixKit Professional Installer functionality.

  This validates that:
  1. The installer task loads correctly
  2. Router integration functions are accessible
  3. Layout integration functions are accessible  
  4. Conflict detection functions are accessible
  5. Core Mix task info structure is correct
  """

  def run_tests do
    IO.puts("🚀 Testing PhoenixKit Professional Installer")
    IO.puts("=" <> String.duplicate("=", 50))

    test_mix_task_loading()
    test_task_info_structure()
    test_router_integration_access()
    test_layout_integration_access()
    test_conflict_detection_access()

    IO.puts("\n🎉 Professional installer tests completed!")
  end

  defp test_mix_task_loading do
    IO.puts("\n📦 Testing Mix Task Loading...")

    try do
      # Test if the Mix task can be loaded
      case Code.ensure_loaded(Mix.Tasks.PhoenixKit.Install.Pro) do
        {:module, _} ->
          IO.puts("  ✅ Mix.Tasks.PhoenixKit.Install.Pro loaded successfully")

        {:error, reason} ->
          IO.puts("  ❌ Failed to load Mix task: #{inspect(reason)}")
      end

      # Test if Igniter is available (required for pro installer)
      case Code.ensure_loaded(Igniter) do
        {:module, _} ->
          IO.puts("  ✅ Igniter dependency available")

        {:error, _} ->
          IO.puts("  ⚠️  Igniter not available - Pro installer will show fallback message")
      end
    rescue
      error ->
        IO.puts("  ❌ Mix task loading failed: #{inspect(error)}")
    end
  end

  defp test_task_info_structure do
    IO.puts("\n📋 Testing Task Info Structure...")

    try do
      # Test if we can get task info
      task_module = Mix.Tasks.PhoenixKit.Install.Pro

      # Check if the module responds to basic functions
      functions = task_module.module_info(:exports)
      expected_functions = [:run, :igniter, :info]

      found_functions =
        expected_functions
        |> Enum.filter(fn func -> Enum.any?(functions, fn {name, _arity} -> name == func end) end)

      IO.puts("  ✅ Found functions: #{inspect(found_functions)}")

      if :igniter in found_functions do
        IO.puts("  ✅ Igniter function available - Professional features enabled")
      else
        IO.puts("  ⚠️  Igniter function not available - Basic installer mode")
      end
    rescue
      error ->
        IO.puts("  ❌ Task info structure test failed: #{inspect(error)}")
    end
  end

  defp test_router_integration_access do
    IO.puts("\n🛣️  Testing Router Integration Access...")

    try do
      # Test if router integration modules are accessible
      router_modules = [
        PhoenixKit.Install.RouterIntegration,
        PhoenixKit.Install.RouterIntegration.ASTAnalyzer,
        PhoenixKit.Install.RouterIntegration.ImportInjector,
        PhoenixKit.Install.RouterIntegration.RouteInjector
      ]

      loaded_modules =
        router_modules
        |> Enum.map(fn mod ->
          case Code.ensure_loaded(mod) do
            {:module, _} -> {mod, :loaded}
            {:error, reason} -> {mod, {:error, reason}}
          end
        end)

      successes = loaded_modules |> Enum.count(fn {_, status} -> status == :loaded end)
      total = length(loaded_modules)

      IO.puts("  ✅ Router integration modules: #{successes}/#{total} loaded")

      if successes == total do
        IO.puts("  ✅ All router integration modules available")
      else
        failed = loaded_modules |> Enum.filter(fn {_, status} -> status != :loaded end)
        IO.puts("  ⚠️  Failed modules: #{inspect(failed)}")
      end
    rescue
      error ->
        IO.puts("  ❌ Router integration access test failed: #{inspect(error)}")
    end
  end

  defp test_layout_integration_access do
    IO.puts("\n🎨 Testing Layout Integration Access...")

    try do
      # Test if layout integration modules are accessible
      layout_modules = [
        PhoenixKit.Install.LayoutIntegration,
        PhoenixKit.Install.LayoutIntegration.LayoutDetector,
        PhoenixKit.Install.LayoutIntegration.AutoConfigurator,
        PhoenixKit.Install.LayoutIntegration.LayoutEnhancer,
        PhoenixKit.Install.LayoutIntegration.FallbackHandler
      ]

      loaded_modules =
        layout_modules
        |> Enum.map(fn mod ->
          case Code.ensure_loaded(mod) do
            {:module, _} -> {mod, :loaded}
            {:error, reason} -> {mod, {:error, reason}}
          end
        end)

      successes = loaded_modules |> Enum.count(fn {_, status} -> status == :loaded end)
      total = length(loaded_modules)

      IO.puts("  ✅ Layout integration modules: #{successes}/#{total} loaded")

      if successes == total do
        IO.puts("  ✅ All layout integration modules available")
      else
        failed = loaded_modules |> Enum.filter(fn {_, status} -> status != :loaded end)
        IO.puts("  ⚠️  Failed modules: #{inspect(failed)}")
      end
    rescue
      error ->
        IO.puts("  ❌ Layout integration access test failed: #{inspect(error)}")
    end
  end

  defp test_conflict_detection_access do
    IO.puts("\n🔍 Testing Conflict Detection Access...")

    try do
      # Test if conflict detection modules are accessible
      conflict_modules = [
        PhoenixKit.Install.ConflictDetection,
        PhoenixKit.Install.ConflictDetection.DependencyAnalyzer,
        PhoenixKit.Install.ConflictDetection.ConfigAnalyzer,
        PhoenixKit.Install.ConflictDetection.CodeAnalyzer,
        PhoenixKit.Install.ConflictDetection.MigrationAdvisor
      ]

      loaded_modules =
        conflict_modules
        |> Enum.map(fn mod ->
          case Code.ensure_loaded(mod) do
            {:module, _} -> {mod, :loaded}
            {:error, reason} -> {mod, {:error, reason}}
          end
        end)

      successes = loaded_modules |> Enum.count(fn {_, status} -> status == :loaded end)
      total = length(loaded_modules)

      IO.puts("  ✅ Conflict detection modules: #{successes}/#{total} loaded")

      if successes == total do
        IO.puts("  ✅ All conflict detection modules available")
      else
        failed = loaded_modules |> Enum.filter(fn {_, status} -> status != :loaded end)
        IO.puts("  ⚠️  Failed modules: #{inspect(failed)}")
      end
    rescue
      error ->
        IO.puts("  ❌ Conflict detection access test failed: #{inspect(error)}")
    end
  end
end

# Run the tests
ProInstallerTest.run_tests()
