defmodule BeamLab.PhoenixKitWeb.PageController do
  use BeamLab.PhoenixKitWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: {BeamLab.PhoenixKitWeb.Layouts, :app})
  end
end
