defmodule BeamLab.PhoenixKit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamLab.PhoenixKitWeb.Telemetry,
      BeamLab.PhoenixKit.Repo,
      {DNSCluster, query: Application.get_env(:phoenix_kit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BeamLab.PhoenixKit.PubSub},
      # Start a worker by calling: BeamLab.PhoenixKit.Worker.start_link(arg)
      # {BeamLab.PhoenixKit.Worker, arg},
      # Start to serve requests, typically the last entry
      BeamLab.PhoenixKitWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamLab.PhoenixKit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeamLab.PhoenixKitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
