#!/usr/bin/env elixir

# Утилита для исправления порядка атрибутов в layout файлах
# Использование: elixir fix_layout.exs /path/to/layouts.ex

defmodule LayoutFixer do
  def fix_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case fix_attribute_order(content) do
          {:ok, fixed_content} ->
            case File.write(file_path, fixed_content) do
              :ok ->
                IO.puts("✅ Fixed attribute order in #{file_path}")
              {:error, reason} ->
                IO.puts("❌ Failed to write file: #{reason}")
            end
          {:error, reason} ->
            IO.puts("❌ Failed to fix content: #{reason}")
        end
      {:error, reason} ->
        IO.puts("❌ Failed to read file: #{reason}")
    end
  end

  defp fix_attribute_order(content) do
    attribute_regex = ~r/^\s*(@\w+.*?)\n/m
    function_regex = ~r/^\s*(def\s+\w+)/m
    
    # Find all attributes and their positions
    attributes = Regex.scan(attribute_regex, content, return: :index, capture: :all_but_first)
    
    # Find first function definition
    case Regex.run(function_regex, content, return: :index) do
      [{first_func_start, _}] ->
        # Check if any attributes are after the first function
        misplaced_attributes = 
          attributes
          |> Enum.filter(fn [{attr_start, _}] -> attr_start > first_func_start end)
        
        if length(misplaced_attributes) > 0 do
          IO.puts("Found #{length(misplaced_attributes)} misplaced attributes")
          
          # Extract misplaced attributes
          misplaced_attr_texts = 
            misplaced_attributes
            |> Enum.map(fn [{start, length}] -> 
              String.slice(content, start, length)
            end)
          
          # Remove misplaced attributes from their current locations (reverse order to maintain indices)
          fixed_content = 
            misplaced_attributes
            |> Enum.reverse()
            |> Enum.reduce(content, fn [{start, length}], acc ->
              before = String.slice(acc, 0, start)
              after_attr = String.slice(acc, start + length + 1, String.length(acc))  # +1 для \n
              before <> after_attr
            end)
          
          # Find the position after "use ModuleName, :html" line to insert attributes
          case Regex.run(~r/use\s+\w+Web,\s*:html\n/i, fixed_content, return: :index) do
            [{use_start, use_length}] ->
              use_end = use_start + use_length
              before_use = String.slice(fixed_content, 0, use_end)
              after_use = String.slice(fixed_content, use_end, String.length(fixed_content))
              
              # Insert attributes after the use statement
              attribute_block = "\n" <> Enum.join(misplaced_attr_texts, "\n") <> "\n"
              corrected_content = before_use <> attribute_block <> after_use
              
              IO.puts("✅ Moved #{length(misplaced_attributes)} attributes to correct position")
              {:ok, corrected_content}
              
            nil ->
              IO.puts("⚠️  Could not find 'use' statement to place attributes")
              {:ok, content}
          end
        else
          IO.puts("✅ No misplaced attributes found")
          {:ok, content}
        end
        
      nil ->
        IO.puts("✅ No functions found, file is probably fine")
        {:ok, content}
    end
  end
end

# Main execution
case System.argv() do
  [file_path] ->
    if File.exists?(file_path) do
      LayoutFixer.fix_file(file_path)
    else
      IO.puts("❌ File does not exist: #{file_path}")
    end
  _ ->
    IO.puts("Usage: elixir fix_layout.exs /path/to/layouts.ex")
end