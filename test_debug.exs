#!/usr/bin/env elixir

# Simple debug script to test PhoenixKit behavior

# Set debug logging
Logger.configure(level: :debug)

IO.puts("=== PhoenixKit Debug Test ===")

# Test 1: Check configuration
IO.puts("\n1. Configuration check:")
repo_config = Application.get_env(:phoenix_kit, :repo)
IO.puts("  phoenix_kit repo config: #{inspect(repo_config)}")

# Test 2: Check setup_complete?
IO.puts("\n2. setup_complete? check:")
try do
  result = PhoenixKit.AutoSetup.setup_complete?()
  IO.puts("  setup_complete?: #{result}")
rescue
  error ->
    IO.puts("  ERROR in setup_complete?: #{inspect(error)}")
    IO.puts("  Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
end

# Test 3: Check migration_required?
IO.puts("\n3. migration_required? check:")
if repo_config do
  try do
    result = PhoenixKit.SchemaMigrations.migration_required?(repo_config)
    IO.puts("  migration_required?: #{result}")
  rescue
    error ->
      IO.puts("  ERROR in migration_required?: #{inspect(error)}")
      IO.puts("  Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
  end
else
  IO.puts("  Skipped (no repo configured)")
end

# Test 4: Check get_installed_version
IO.puts("\n4. get_installed_version check:")
if repo_config do
  try do
    result = PhoenixKit.SchemaMigrations.get_installed_version(repo_config)
    IO.puts("  get_installed_version: #{inspect(result)}")
  rescue
    error ->
      IO.puts("  ERROR in get_installed_version: #{inspect(error)}")
      IO.puts("  Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
  end
else
  IO.puts("  Skipped (no repo configured)")
end

# Test 5: Check endpoint detection
IO.puts("\n5. detect_parent_endpoint check:")
try do
  result = PhoenixKit.AutoSetup.detect_parent_endpoint()
  IO.puts("  detect_parent_endpoint: #{inspect(result)}")
rescue
  error ->
    IO.puts("  ERROR in detect_parent_endpoint: #{inspect(error)}")
    IO.puts("  Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
end

IO.puts("\n=== End Debug Test ===")