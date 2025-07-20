if Code.ensure_loaded?(Swoosh.Mailer) do
  defmodule BeamLab.PhoenixKit.Mailer do
    use Swoosh.Mailer, otp_app: :phoenix_kit
  end
else
  defmodule BeamLab.PhoenixKit.Mailer do
    def deliver(_email), do: {:error, :mailer_not_available}
  end
end
