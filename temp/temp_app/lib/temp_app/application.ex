defmodule TempApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TempApp.Repo,
      TempAppWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:temp_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TempApp.PubSub},
      # Start a worker by calling: TempApp.Worker.start_link(arg)
      # {TempApp.Worker, arg},
      # Start to serve requests, typically the last entry
      TempAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TempApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TempAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
