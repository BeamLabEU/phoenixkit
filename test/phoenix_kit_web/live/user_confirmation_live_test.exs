defmodule PhoenixKitWeb.UserConfirmationLiveTest do
  use PhoenixKitWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PhoenixKit.UsersFixtures

  alias PhoenixKit.Repo
  alias PhoenixKit.Users.Auth

  setup do
    %{user: user_fixture()}
  end

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, "/phoenix_kit/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Auth.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, "/phoenix_kit/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "User confirmed successfully"

      assert Auth.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Auth.UserToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, "/phoenix_kit/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_user(user)

      {:ok, lv, _html} = live(conn, "/phoenix_kit/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, "/phoenix_kit/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User confirmation link is invalid or it has expired"

      refute Auth.get_user!(user.id).confirmed_at
    end
  end
end
