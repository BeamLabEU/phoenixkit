defmodule BeamLab.PhoenixKit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = case BeamLab.PhoenixKit.mode() do
      :library ->
        # Library mode: Only core services, no web layer
        [
          BeamLab.PhoenixKit.Repo,
          {Phoenix.PubSub, name: BeamLab.PhoenixKit.PubSub}
        ]
      :standalone ->
        # Standalone mode: Full application with web layer
        base_children = [
          BeamLab.PhoenixKitWeb.Telemetry,
          BeamLab.PhoenixKit.Repo,
          {Phoenix.PubSub, name: BeamLab.PhoenixKit.PubSub},
          BeamLab.PhoenixKitWeb.Endpoint
        ]
        
        # Add DNSCluster only if available (optional dependency)
        if Code.ensure_loaded?(DNSCluster) do
          [{DNSCluster, query: Application.get_env(:phoenix_kit, :dns_cluster_query) || :ignore} | base_children]
        else
          base_children
        end
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
    if BeamLab.PhoenixKit.standalone?() do
      BeamLab.PhoenixKitWeb.Endpoint.config_change(changed, removed)
    end
    :ok
  end
end
