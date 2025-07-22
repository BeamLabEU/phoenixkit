defmodule BeamLab.PhoenixKitWeb.UserSessionHTML do
  use BeamLab.PhoenixKitWeb, :html

  # Library mode: Use simple HTML strings instead of templates
  def new(assigns), do: "<div>Login form placeholder</div>"
  def confirm(assigns), do: "<div>Confirm form placeholder</div>"

  defp local_mail_adapter? do
    Application.get_env(:phoenix_kit, BeamLab.PhoenixKit.Mailer)[:adapter] ==
      Swoosh.Adapters.Local
  end
end
