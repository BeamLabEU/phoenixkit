# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix Framework web application called BeamLab.PhoenixKit, built with Elixir. It's a standard Phoenix 1.8 application using PostgreSQL as the database, with LiveView for real-time features and Tailwind CSS for styling.

## Development Commands

### Setup and Dependencies
- `mix setup` - Complete project setup (installs deps, sets up database, builds assets)
- `mix deps.get` - Install Elixir dependencies only

### Database Operations
- `mix ecto.create` - Create the database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with fresh data
- `mix ecto.setup` - Create database, run migrations, and seed data

### Development Server
- `mix phx.server` - Start Phoenix server (visit http://localhost:4000)
- `iex -S mix phx.server` - Start server with interactive Elixir shell

### Testing
- `mix test` - Run all tests (automatically sets up test database)

### Asset Management
- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build CSS and JavaScript assets for development
- `mix assets.deploy` - Build and minify assets for production

## Architecture

### Module Structure
- **BeamLab.PhoenixKit** - Main application module and context
- **BeamLab.PhoenixKitWeb** - Web layer (controllers, views, templates, router)
- **BeamLab.PhoenixKit.Repo** - Database repository using Ecto
- **BeamLab.PhoenixKit.Application** - OTP application supervisor

### Key Components
- **Router** (`lib/phoenix_kit_web/router.ex`) - Defines routes with browser and API pipelines
- **Endpoint** (`lib/phoenix_kit_web/endpoint.ex`) - HTTP endpoint configuration
- **Layouts** (`lib/phoenix_kit_web/components/layouts.ex`) - Page layout components
- **Core Components** (`lib/phoenix_kit_web/components/core_components.ex`) - Reusable UI components

### Database Configuration
- Development: PostgreSQL with credentials in `config/dev.exs`
- Test: Separate test database configured in `config/test.exs`
- Production: Runtime configuration in `config/runtime.exs`

### Asset Pipeline
- **Tailwind CSS** - Configured for CSS processing with input at `assets/css/app.css`
- **esbuild** - JavaScript bundling with entry point at `assets/js/app.js`
- **Heroicons** - Icon library included from GitHub

### Development Tools
- **Phoenix LiveDashboard** - Available at `/dev/dashboard` in development
- **Swoosh Mailbox** - Email preview at `/dev/mailbox` in development
- **Phoenix LiveReload** - Automatic browser refresh during development

## File Structure Notes

- `priv/repo/migrations/` - Database migration files
- `priv/repo/seeds.exs` - Database seed data
- `test/support/` - Test helper modules (ConnCase, DataCase)
- `assets/` - Frontend assets (CSS, JS, images)
- `priv/static/` - Compiled static assets served by the web server