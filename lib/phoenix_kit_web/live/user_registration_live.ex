defmodule PhoenixKitWeb.UserRegistrationLive do
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Accounts
  alias PhoenixKit.Accounts.User

  def render(assigns) do
    ~H"""
    <.form 
      for={@form}
      id="registration_form"
      phx-submit="save"
      phx-change="validate"
      phx-trigger-action={@trigger_submit}
      action="./log-in?_action=registered"
      method="post"
    >
      <fieldset class="fieldset">
        <legend class="fieldset-legend">Account Information</legend>
        
        <div :if={@check_errors} class="alert alert-error text-sm mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>Oops, something went wrong! Please check the errors below.</span>
        </div>

        <label class="label" for="user_email">Email</label>
        <input 
          id="user_email"
          name="user[email]"
          type="email"
          class="input input-bordered w-full"
          placeholder="Enter your email address"
          value={@form.params["email"] || ""}
          pattern="^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$"
          title="Please enter a valid email address"
          required
        />
        <p class="text-xs text-gray-500 mt-1">Please enter a valid email address</p>
        
        <label class="label" for="user_password">Password</label>
        <input 
          id="user_password"
          name="user[password]"
          type="password"
          class="input input-bordered w-full"
          placeholder="Choose a secure password"
          minlength="8"
          title="Password must be at least 8 characters long"
          required
        />
        <p class="text-xs text-gray-500 mt-1">Password must be at least 8 characters long</p>
        
        <button 
          type="submit"
          phx-disable-with="Creating account..."
          class="btn btn-primary w-full mt-4"
        >
          Create account <span aria-hidden="true">→</span>
        </button>
      </fieldset>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false, page_title: "Register")
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            fn token -> "./confirm/#{token}" end
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
