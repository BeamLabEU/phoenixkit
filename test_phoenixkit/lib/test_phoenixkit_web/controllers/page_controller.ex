defmodule TestPhoenixkitWeb.PageController do
  use TestPhoenixkitWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
