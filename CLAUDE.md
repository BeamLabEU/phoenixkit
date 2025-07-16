# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhonixKit is a minimal Phoenix LiveView component library for creating beautiful welcome pages. It provides a single `welcome` component that renders a full-screen gradient background with centered text.

## Architecture

- **Main Module**: `lib/phonix_kit.ex` - Contains the single `PhonixKit.welcome/1` component
- **Component Pattern**: Uses Phoenix.Component with HEEx templates
- **Styling**: Uses Tailwind CSS classes for gradient backgrounds and responsive design
- **Dependencies**: Phoenix LiveView ~> 0.18 (no other runtime dependencies)

## Development Commands

This is an Elixir/Phoenix project using Mix:

```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Run tests (if any exist)
mix test

# Format code
mix format

# Check for compilation warnings
mix compile --warnings-as-errors

# Build documentation
mix docs
```

## Component Usage

The library exports a single component `PhonixKit.welcome/1` with these attributes:
- `title` (required) - Main heading text
- `subtitle` (optional) - Subheading text, defaults to "Phonix Kit успешно установлен"
- `class` (optional) - Additional CSS classes

## Project Structure

- `lib/phonix_kit.ex` - Main component implementation
- `mix.exs` - Project configuration and dependencies
- `README.md` - Russian documentation with usage examples

## Notes

- This is a library package, not a standalone application
- All text and documentation is in Russian
- The component creates a full-screen gradient (blue to purple) welcome page
- Requires Tailwind CSS to be available in the consuming application