defmodule PhoenixKitWeb.UserMagicLinkLive do
  @moduledoc """
  LiveView for magic link authentication.

  This LiveView handles the magic link authentication flow:
  1. User enters their email address
  2. System sends magic link to their email
  3. User clicks link to authenticate

  The magic link verification is handled by the controller, this LiveView
  handles the email input and confirmation flow.
  """
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Accounts.MagicLink
  alias PhoenixKit.Mailer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Magic Link Login")
     |> assign(:email, "")
     |> assign(:sent, false)
     |> assign(:loading, false)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("validate", %{"email" => email}, socket) do
    # Simple client-side validation
    error = if valid_email?(email), do: nil, else: "Please enter a valid email address"

    {:noreply,
     socket
     |> assign(:email, email)
     |> assign(:error, error)}
  end

  @impl true
  def handle_event("send_magic_link", %{"email" => email}, socket) do
    if valid_email?(email) do
      {:noreply,
       socket
       |> assign(:loading, true)
       |> assign(:error, nil)
       |> send_magic_link_async(email)}
    else
      {:noreply, assign(socket, :error, "Please enter a valid email address")}
    end
  end

  @impl true
  def handle_async(:send_magic_link, {:ok, result}, socket) do
    case result do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:sent, true)
         |> assign(:loading, false)
         |> put_flash(:info, "Magic link sent! Check your email.")}

      {:error, _} ->
        # For security, we don't reveal whether the email exists or not
        {:noreply,
         socket
         |> assign(:sent, true)
         |> assign(:loading, false)
         |> put_flash(:info, "If that email address exists, a magic link has been sent.")}
    end
  end

  @impl true
  def handle_async(:send_magic_link, {:exit, _reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:error, "Failed to send magic link. Please try again.")}
  end

  # Process the magic link sending in the background
  defp send_magic_link_async(socket, email) do
    Phoenix.LiveView.start_async(socket, :send_magic_link, fn ->
      case MagicLink.generate_magic_link(email) do
        {:ok, user, token} ->
          # Send the magic link email
          magic_link_url = MagicLink.magic_link_url(token)

          case Mailer.send_magic_link_email(user, magic_link_url) do
            {:ok, _} -> {:ok, user}
            {:error, reason} -> {:error, reason}
          end

        {:error, :user_not_found} ->
          # For security, we simulate the same delay as successful case
          Process.sleep(100)
          {:error, :user_not_found}

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  # Simple email validation
  defp valid_email?(email) when is_binary(email) do
    String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Magic Link Login
        <:subtitle>Enter your email to receive a secure login link</:subtitle>
      </.header>

      <.simple_form for={%{}} as={:magic_link} phx-change="validate" phx-submit="send_magic_link">
        <.input
          name="email"
          value={@email}
          type="email"
          label="Email"
          placeholder="you@example.com"
          required
        />

        <.error :if={@error}>{@error}</.error>

        <:actions>
          <.button phx-disable-with="Sending..." class="w-full" disabled={@loading || @sent}>
            <%= if @loading do %>
              <.icon name="hero-arrow-path" class="animate-spin -ml-1 mr-2 h-4 w-4" />
              Sending magic link...
            <% else %>
              Send Magic Link
            <% end %>
          </.button>
        </:actions>
      </.simple_form>

      <div :if={@sent} class="mt-6 p-4 bg-green-50 border border-green-200 rounded-md">
        <div class="flex">
          <.icon name="hero-check-circle" class="h-5 w-5 text-green-400" />
          <div class="ml-3">
            <h3 class="text-sm font-medium text-green-800">
              Magic link sent!
            </h3>
            <p class="mt-1 text-sm text-green-700">
              Check your email for a secure login link. The link will expire in 15 minutes.
            </p>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-gray-300" />
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-white text-gray-500">Or continue with</span>
          </div>
        </div>

        <div class="mt-6 text-center">
          <.link navigate={~p"/phoenix_kit/log_in"} class="text-sm text-brand hover:underline">
            Sign in with password
          </.link>
        </div>

        <div class="mt-3 text-center">
          <.link
            navigate={~p"/phoenix_kit/register"}
            class="text-sm text-gray-600 hover:text-gray-500"
          >
            Don't have an account? Sign up
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
