defmodule BeamLab.PhoenixKit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = case Application.get_env(:phoenix_kit, :library_mode, false) do
      true ->
        # Library mode: Only core services, no web layer
        [
          BeamLab.PhoenixKit.Repo,
          {Phoenix.PubSub, name: BeamLab.PhoenixKit.PubSub}
        ]
      false ->
        # Standalone mode: Full application with web layer
        [
          BeamLab.PhoenixKitWeb.Telemetry,
          BeamLab.PhoenixKit.Repo,
          {DNSCluster, query: Application.get_env(:phoenix_kit, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: BeamLab.PhoenixKit.PubSub},
          BeamLab.PhoenixKitWeb.Endpoint
        ]
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamLab.PhoenixKit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    # Only update endpoint config in standalone mode
    unless Application.get_env(:phoenix_kit, :library_mode, false) do
      BeamLab.PhoenixKitWeb.Endpoint.config_change(changed, removed)
    end
    :ok
  end
end
