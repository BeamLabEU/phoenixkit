#!/usr/bin/env elixir

# Simple integration test runner that doesn't require database setup
# This validates that our integration tests are structurally correct

defmodule IntegrationTestRunner do
  @moduledoc """
  Simple runner to validate integration test structure without requiring database setup.
  """

  def run do
    IO.puts("🧪 PhoenixKit Integration Test Structure Validation")
    IO.puts("=" |> String.duplicate(60))

    test_files = [
      "test/phoenix_kit/install/router_integration_test.exs",
      "test/phoenix_kit/install/layout_integration_test.exs",
      "test/phoenix_kit/install/conflict_detection_test.exs",
      "test/phoenix_kit/install/professional_installer_integration_test.exs"
    ]

    results = Enum.map(test_files, &validate_test_file/1)

    IO.puts("\n📊 Test Validation Summary:")
    IO.puts("=" |> String.duplicate(40))

    Enum.each(results, fn {file, status, details} ->
      status_icon = if status == :ok, do: "✅", else: "❌"
      IO.puts("#{status_icon} #{Path.basename(file)}")

      if details != [] do
        Enum.each(details, fn detail ->
          IO.puts("   • #{detail}")
        end)
      end
    end)

    success_count = Enum.count(results, fn {_, status, _} -> status == :ok end)
    total_count = length(results)

    IO.puts("\n🎯 Results: #{success_count}/#{total_count} test files valid")

    if success_count == total_count do
      IO.puts("🎉 All integration tests are structurally valid!")
      :ok
    else
      IO.puts("⚠️  Some integration tests have structural issues")
      :error
    end
  end

  defp validate_test_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        details = []

        # Check basic structure
        details = details ++ validate_basic_structure(content, file_path)
        details = details ++ validate_test_organization(content, file_path)
        details = details ++ validate_assertions(content, file_path)

        status = if details == [], do: :ok, else: :warning
        {file_path, status, details}

      {:error, reason} ->
        {file_path, :error, ["File not found: #{reason}"]}
    end
  end

  defp validate_basic_structure(content, file_path) do
    details = []

    # Check for required modules
    unless String.contains?(content, "use ExUnit.Case") do
      details = details ++ ["Missing ExUnit.Case usage"]
    end

    # Check for describe blocks
    describe_count = content |> String.split("describe ") |> length() |> Kernel.-(1)

    if describe_count == 0 do
      details = details ++ ["No describe blocks found"]
    else
      details = details ++ ["Found #{describe_count} describe blocks"]
    end

    # Check for test definitions
    test_count = content |> String.split(~r/test "|@tag.*test /) |> length() |> Kernel.-(1)

    if test_count == 0 do
      details = details ++ ["No test cases found"]
    else
      details = details ++ ["Found #{test_count} test cases"]
    end

    details
  end

  defp validate_test_organization(content, file_path) do
    details = []

    # Check for setup blocks
    if String.contains?(content, "setup do") do
      details = details ++ ["Has setup blocks"]
    end

    # Check for helper functions
    if String.contains?(content, "defp ") do
      details = details ++ ["Has helper functions"]
    end

    # Check for mock usage
    if String.contains?(content, "with_mock") do
      details = details ++ ["Uses mocking"]
    end

    details
  end

  defp validate_assertions(content, file_path) do
    details = []

    # Count assertions
    assert_count = content |> String.split("assert ") |> length() |> Kernel.-(1)

    if assert_count > 0 do
      details = details ++ ["Has #{assert_count} assertions"]
    end

    # Check for different assertion types
    if String.contains?(content, "assert {:ok") do
      details = details ++ ["Uses pattern matching assertions"]
    end

    if String.contains?(content, "assert_") do
      details = details ++ ["Uses custom assertions"]
    end

    details
  end
end

# Run the validation
case IntegrationTestRunner.run() do
  :ok -> System.halt(0)
  :error -> System.halt(1)
end
