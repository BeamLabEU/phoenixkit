defmodule PhoenixModuleTemplate.Repo do
  @moduledoc """
  Repository module for PhoenixModuleTemplate.

  This repository is used for development and testing of the module.
  In production, the module will use the parent application's repository.

  ## Configuration

  For development, configure in `config/dev.exs`:

      config :phoenix_module_template, PhoenixModuleTemplate.Repo,
        username: "postgres",
        password: "postgres",
        hostname: "localhost",
        database: "phoenix_module_template_dev",
        show_sensitive_data_on_connection_error: true,
        pool_size: 10

  For testing, configure in `config/test.exs`:

      config :phoenix_module_template, PhoenixModuleTemplate.Repo,
        username: "postgres",
        password: "postgres",
        hostname: "localhost", 
        database: "phoenix_module_template_test",
        pool: Ecto.Adapters.SQL.Sandbox

  ## Usage in Parent Application

  When using this module in a Phoenix application, you typically don't need
  this repository. Instead, configure the parent application's repo:

      config :phoenix_module_template, repo: MyApp.Repo

  """

  use Ecto.Repo,
    otp_app: :phoenix_module_template,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
