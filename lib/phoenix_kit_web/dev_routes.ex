if Application.compile_env(:phoenix_kit, :dev_routes) do
  defmodule BeamLab.PhoenixKitWeb.DevRoutes do
    @moduledoc """
    Development routes for Phoenix Kit standalone mode.
    Only included when dev_routes is enabled in configuration.
    """
    
    defmacro dev_routes do
      quote do
        import Phoenix.LiveDashboard.Router

        scope "/dev" do
          pipe_through :browser

          live_dashboard "/dashboard", metrics: BeamLab.PhoenixKitWeb.Telemetry
          forward "/mailbox", Plug.Swoosh.MailboxPreview
        end
      end
    end
  end
else
  defmodule BeamLab.PhoenixKitWeb.DevRoutes do
    @moduledoc """
    Development routes for Phoenix Kit standalone mode.
    Disabled when dev_routes is not enabled.
    """
    
    defmacro dev_routes do
      quote do
        # No dev routes in library mode
      end
    end
  end
end