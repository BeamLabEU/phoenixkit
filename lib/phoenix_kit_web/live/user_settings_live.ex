defmodule PhoenixKitWeb.UserSettingsLive do
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Accounts

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 py-8">
      <div class="max-w-2xl mx-auto px-4">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold mb-2">Account Settings</h1>
          <p class="text-base-content/70">Manage your account email address and password settings</p>
        </div>

        <div class="space-y-8">
          <!-- Email Settings Card -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Email Address</h2>
              <p class="text-sm text-base-content/70 mb-4">Change your account email address</p>

              <.simple_form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
              >
                <.input field={@email_form[:email]} type="email" label="Email" required />
                <.input
                  field={@email_form[:current_password]}
                  name="current_password"
                  id="current_password_for_email"
                  type="password"
                  label="Current password"
                  value={@email_form_current_password}
                  required
                />
                <:actions>
                  <.button phx-disable-with="Changing..." class="btn-primary">Change Email</.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
          
    <!-- Password Settings Card -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Password</h2>
              <p class="text-sm text-base-content/70 mb-4">Update your account password</p>

              <.simple_form
                for={@password_form}
                id="password_form"
                action="/phoenix_kit/log_in?_action=password_updated"
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  value={@current_email}
                />
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  required
                />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                />
                <.input
                  field={@password_form[:current_password]}
                  name="current_password"
                  type="password"
                  label="Current password"
                  id="current_password_for_password"
                  value={@current_password}
                  required
                />
                <:actions>
                  <.button phx-disable-with="Changing..." class="btn-primary">
                    Change Password
                  </.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
          
    <!-- Development Mode Notice -->
          <div :if={show_dev_notice?()} class="alert alert-info">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current shrink-0 h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              >
              </path>
            </svg>
            <span>
              Development mode: Email confirmation links will be available in
              <.link href="/dev/mailbox" class="font-semibold underline">mailbox</.link>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: "/phoenix_kit/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/phoenix_kit/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  defp show_dev_notice? do
    case Application.get_env(:phoenix_kit, PhoenixKit.Mailer)[:adapter] do
      Swoosh.Adapters.Local -> true
      _ -> false
    end
  end
end
