defmodule BeamLab.PhoenixKitWeb.UserRegistrationController do
  use BeamLab.PhoenixKitWeb, :controller

  alias BeamLab.PhoenixKit.Accounts
  alias BeamLab.PhoenixKit.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset, layout: {BeamLab.PhoenixKitWeb.Layouts, :app})
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/phoenix_kit/log-in/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          "An email was sent to #{user.email}, please access it to confirm your account."
        )
        |> redirect(to: ~p"/phoenix_kit/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, layout: {BeamLab.PhoenixKitWeb.Layouts, :app})
    end
  end
end
