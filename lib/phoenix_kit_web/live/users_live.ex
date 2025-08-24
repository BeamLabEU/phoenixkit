defmodule PhoenixKitWeb.Live.UsersLive do
  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Users.Auth
  alias PhoenixKit.Users.Auth.User
  alias PhoenixKit.Users.Roles

  @per_page 10

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page, 1)
      |> assign(:per_page, @per_page)
      |> assign(:search_query, "")
      |> assign(:filter_role, "all")
      |> load_users()
      |> load_stats()

    {:ok, socket}
  end

  def handle_event("search", %{"search" => search_query}, socket) do
    socket =
      socket
      |> assign(:search_query, search_query)
      |> assign(:page, 1)
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("filter_by_role", %{"role" => role}, socket) do
    socket =
      socket
      |> assign(:filter_role, role)
      |> assign(:page, 1)
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("change_page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    socket =
      socket
      |> assign(:page, page)
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("promote_to_admin", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.phoenix_kit_current_user
    user = Auth.get_user!(user_id)

    # Self-promotion is allowed for admin role
    case Roles.promote_to_admin(user, current_user) do
      {:ok, _assignment} ->
        socket =
          socket
          |> put_flash(:info, "User promoted to admin successfully")
          |> load_users()
          |> load_stats()

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Failed to promote user")
        {:noreply, socket}
    end
  end

  def handle_event("demote_to_user", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.phoenix_kit_current_user
    user = Auth.get_user!(user_id)

    # Prevent self-modification
    if current_user.id == user.id do
      socket = put_flash(socket, :error, "Cannot demote yourself")
      {:noreply, socket}
    else
      case Roles.demote_to_user(user) do
        {:ok, _assignment} ->
          socket =
            socket
            |> put_flash(:info, "User demoted successfully")
            |> load_users()
            |> load_stats()

          {:noreply, socket}

        {:error, :cannot_demote_last_owner} ->
          socket = put_flash(socket, :error, "Cannot demote the last system owner")
          {:noreply, socket}

        {:error, :cannot_remove_last_owner} ->
          socket = put_flash(socket, :error, "Cannot remove the last system owner")
          {:noreply, socket}

        {:error, :no_role_to_demote} ->
          socket = put_flash(socket, :error, "User has no elevated role to demote")
          {:noreply, socket}

        {:error, _changeset} ->
          socket = put_flash(socket, :error, "Failed to demote user")
          {:noreply, socket}
      end
    end
  end

  def handle_event("toggle_user_status", %{"user_id" => user_id}, socket) do
    current_user = socket.assigns.phoenix_kit_current_user
    user = Auth.get_user!(user_id)

    if current_user.id == user.id do
      socket = put_flash(socket, :error, "Cannot modify your own status")
      {:noreply, socket}
    else
      toggle_user_status_safely(socket, user)
    end
  end

  defp toggle_user_status_safely(socket, user) do
    new_status = !user.is_active

    case Auth.update_user_status(user, %{"is_active" => new_status}) do
      {:ok, _user} ->
        status_text = if new_status, do: "activated", else: "deactivated"

        socket =
          socket
          |> put_flash(:info, "User #{status_text} successfully")
          |> load_users()
          |> load_stats()

        {:noreply, socket}

      {:error, :cannot_deactivate_last_owner} ->
        socket = put_flash(socket, :error, "Cannot deactivate the last system owner")
        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Failed to update user status")
        {:noreply, socket}
    end
  end

  defp load_users(socket) do
    params = [
      page: socket.assigns.page,
      page_size: socket.assigns.per_page,
      search: socket.assigns.search_query,
      role: socket.assigns.filter_role
    ]

    %{users: users, total_count: total_count, total_pages: total_pages} =
      Auth.list_users_paginated(params)

    socket
    |> assign(:users, users)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
  end

  defp load_stats(socket) do
    stats = Roles.get_extended_stats()

    socket
    |> assign(:total_users, stats.total_users)
    |> assign(:total_owners, stats.owner_count)
    |> assign(:total_admins, stats.admin_count)
    |> assign(:total_regular_users, stats.user_count)
    |> assign(:active_users, stats.active_users)
    |> assign(:inactive_users, stats.inactive_users)
    |> assign(:confirmed_users, stats.confirmed_users)
    |> assign(:pending_users, stats.pending_users)
  end

  defp role_badge_class("Owner"), do: "badge-error"
  defp role_badge_class("Admin"), do: "badge-warning"
  defp role_badge_class("User"), do: "badge-info"
  defp role_badge_class(_), do: "badge-ghost"

  defp format_datetime(nil), do: "Never"

  defp format_datetime(datetime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Date.to_string()
  end

  defp user_primary_role(user) do
    roles = User.get_roles(user)

    cond do
      "Owner" in roles -> "Owner"
      "Admin" in roles -> "Admin"
      true -> "User"
    end
  end
end
