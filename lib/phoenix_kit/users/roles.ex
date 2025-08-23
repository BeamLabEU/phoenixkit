defmodule PhoenixKit.Users.Roles do
  @moduledoc """
  API for managing user roles in PhoenixKit authentication system.

  This module provides functions for assigning, removing, and querying user roles.
  It works with the role system to provide authorization capabilities.

  ## Role Management

  - Assign and remove roles from users
  - Query users by role
  - Check user permissions
  - Bulk role operations

  ## System Roles

  PhoenixKit includes three built-in system roles:

  - **Owner**: System owner with full access (assigned automatically to first user)
  - **Admin**: Administrator with elevated privileges
  - **User**: Standard user with basic access (default for new users)

  ## Examples

      # Check if user has a role
      iex> user_has_role?(user, "Admin")
      true

      # Get all user roles
      iex> get_user_roles(user)
      ["Admin", "User"]

      # Assign a role to user
      iex> assign_role(user, "Admin")
      {:ok, %RoleAssignment{}}

      # Get all users with a specific role
      iex> users_with_role("Admin")
      [%User{}, %User{}]
  """

  import Ecto.Query, warn: false
  alias PhoenixKit.RepoHelper
  alias PhoenixKit.Users.Auth.User
  alias PhoenixKit.Users.{Role, RoleAssignment}

  @doc """
  Assigns a role to a user.

  ## Parameters

  - `user`: The user to assign the role to
  - `role_name`: The name of the role to assign
  - `assigned_by` (optional): The user who is assigning the role

  ## Examples

      iex> assign_role(user, "Admin")
      {:ok, %RoleAssignment{}}

      iex> assign_role(user, "Admin", assigned_by_user)
      {:ok, %RoleAssignment{}}

      iex> assign_role(user, "NonexistentRole")
      {:error, :role_not_found}
  """
  def assign_role(%User{} = user, role_name, assigned_by \\ nil) when is_binary(role_name) do
    repo = RepoHelper.repo()

    case get_role_by_name(role_name) do
      nil ->
        {:error, :role_not_found}

      role ->
        attrs = %{
          user_id: user.id,
          role_id: role.id,
          assigned_by: assigned_by && assigned_by.id,
          is_active: true
        }

        # Use upsert with ON CONFLICT DO NOTHING for idempotency
        # This prevents duplicate role assignment errors during concurrent operations
        %RoleAssignment{}
        |> RoleAssignment.changeset(attrs)
        |> repo.insert(
          on_conflict: :nothing,
          conflict_target: [:user_id, :role_id]
        )
        |> case do
          {:ok, assignment} -> {:ok, assignment}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Removes a role from a user by deactivating the assignment.

  ## Parameters

  - `user`: The user to remove the role from
  - `role_name`: The name of the role to remove

  ## Examples

      iex> remove_role(user, "Admin")
      {:ok, %RoleAssignment{}}

      iex> remove_role(user, "NonexistentRole")
      {:error, :assignment_not_found}
  """
  def remove_role(%User{} = user, role_name) when is_binary(role_name) do
    repo = RepoHelper.repo()

    case get_active_assignment(user.id, role_name) do
      nil ->
        {:error, :assignment_not_found}

      assignment ->
        assignment
        |> RoleAssignment.update_changeset(%{is_active: false})
        |> repo.update()
    end
  end

  @doc """
  Checks if a user has a specific role.

  ## Parameters

  - `user`: The user to check
  - `role_name`: The name of the role to check for

  ## Examples

      iex> user_has_role?(user, "Admin")
      true

      iex> user_has_role?(user, "Owner")
      false
  """
  def user_has_role?(%User{} = user, role_name) when is_binary(role_name) do
    repo = RepoHelper.repo()

    query =
      from assignment in RoleAssignment,
        join: role in assoc(assignment, :role),
        where: assignment.user_id == ^user.id,
        where: role.name == ^role_name,
        where: assignment.is_active == true

    repo.exists?(query)
  end

  @doc """
  Gets all active roles for a user.

  ## Parameters

  - `user`: The user to get roles for

  ## Examples

      iex> get_user_roles(user)
      ["Admin", "User"]

      iex> get_user_roles(user_with_no_roles)
      []
  """
  def get_user_roles(%User{} = user) do
    repo = RepoHelper.repo()

    query =
      from assignment in RoleAssignment,
        join: role in assoc(assignment, :role),
        where: assignment.user_id == ^user.id,
        where: assignment.is_active == true,
        select: role.name,
        order_by: role.name

    repo.all(query)
  end

  @doc """
  Gets all users who have a specific role.

  ## Parameters

  - `role_name`: The name of the role to search for

  ## Examples

      iex> users_with_role("Admin")
      [%User{}, %User{}]

      iex> users_with_role("NonexistentRole")
      []
  """
  def users_with_role(role_name) when is_binary(role_name) do
    repo = RepoHelper.repo()

    query =
      from user in User,
        join: assignment in assoc(user, :role_assignments),
        join: role in assoc(assignment, :role),
        where: role.name == ^role_name,
        where: assignment.is_active == true,
        distinct: user.id,
        order_by: user.email

    repo.all(query)
  end

  @doc """
  Creates a new role.

  ## Parameters

  - `attrs`: Attributes for the new role

  ## Examples

      iex> create_role(%{name: "Manager", description: "Department manager"})
      {:ok, %Role{}}

      iex> create_role(%{name: ""})
      {:error, %Ecto.Changeset{}}
  """
  def create_role(attrs \\ %{}) do
    repo = RepoHelper.repo()

    %Role{}
    |> Role.changeset(attrs)
    |> repo.insert()
  end

  @doc """
  Gets a role by its name.

  ## Parameters

  - `name`: The name of the role

  ## Examples

      iex> get_role_by_name("Admin")
      %Role{name: "Admin"}

      iex> get_role_by_name("NonexistentRole")
      nil
  """
  def get_role_by_name(name) when is_binary(name) do
    repo = RepoHelper.repo()
    repo.get_by(Role, name: name)
  end

  @doc """
  Lists all roles.

  ## Examples

      iex> list_roles()
      [%Role{}, %Role{}, %Role{}]
  """
  def list_roles do
    repo = RepoHelper.repo()

    query =
      from role in Role,
        order_by: [desc: role.is_system_role, asc: role.name]

    repo.all(query)
  end

  @doc """
  Gets role statistics for dashboard display.

  ## Examples

      iex> get_role_stats()
      %{
        total_users: 10,
        owner_count: 1,
        admin_count: 2,
        user_count: 7
      }
  """
  def get_role_stats do
    repo = RepoHelper.repo()

    total_users_query = from(u in User, select: count(u.id))
    total_users = repo.one(total_users_query)

    owner_count = count_users_with_role("Owner")
    admin_count = count_users_with_role("Admin")
    user_count = count_users_with_role("User")

    %{
      total_users: total_users,
      owner_count: owner_count,
      admin_count: admin_count,
      user_count: user_count
    }
  end

  @doc """
  Counts users with a specific role.

  ## Parameters

  - `role_name`: The name of the role to count

  ## Examples

      iex> count_users_with_role("Admin")
      3
  """
  def count_users_with_role(role_name) when is_binary(role_name) do
    repo = RepoHelper.repo()

    query =
      from assignment in RoleAssignment,
        join: role in assoc(assignment, :role),
        where: role.name == ^role_name,
        where: assignment.is_active == true,
        select: count(assignment.id)

    repo.one(query) || 0
  end

  @doc """
  Promotes a user to admin role.

  ## Parameters

  - `user`: The user to promote
  - `assigned_by` (optional): The user who is doing the promotion

  ## Examples

      iex> promote_to_admin(user)
      {:ok, %RoleAssignment{}}
  """
  def promote_to_admin(%User{} = user, assigned_by \\ nil) do
    assign_role(user, "Admin", assigned_by)
  end

  @doc """
  Safely demotes a user from Admin or Owner role with protection.

  Prevents demotion of last Owner to maintain system security.

  ## Parameters

  - `user`: The user to demote

  ## Examples

      iex> demote_to_user(admin_user)
      {:ok, %RoleAssignment{}}
      
      iex> demote_to_user(last_owner)
      {:error, :cannot_demote_last_owner}
  """
  def demote_to_user(%User{} = user) do
    cond do
      user_has_role?(user, "Owner") ->
        # Use safe removal for Owner role
        safely_remove_role(user, "Owner")

      user_has_role?(user, "Admin") ->
        # Admin can be demoted safely
        remove_role(user, "Admin")

      true ->
        # User has no roles to demote from
        {:error, :no_role_to_demote}
    end
  end

  @doc """
  Counts active users with Owner role.

  Critical security function - ensures we never have zero owners.

  ## Examples

      iex> count_active_owners()
      1
  """
  def count_active_owners do
    repo = RepoHelper.repo()

    query =
      from user in User,
        join: assignment in assoc(user, :role_assignments),
        join: role in assoc(assignment, :role),
        where: role.name == "Owner",
        where: assignment.is_active == true,
        where: user.is_active == true,
        select: count(user.id)

    repo.one(query) || 0
  end

  @doc """
  Safely assigns Owner role to first user using database transaction.

  This function prevents race conditions by using FOR UPDATE lock.

  ## Parameters

  - `user`: The user to potentially make Owner

  ## Returns

  - `{:ok, :owner}` if user became Owner
  - `{:ok, :user}` if user became regular User  
  - `{:error, reason}` on failure

  ## Examples

      iex> ensure_first_user_is_owner(user)
      {:ok, :owner}
  """
  def ensure_first_user_is_owner(%User{} = user) do
    repo = RepoHelper.repo()

    repo.transaction(fn ->
      # Lock users table to prevent race condition
      user_count =
        repo.one(
          from u in User,
            select: count(u.id),
            lock: "FOR UPDATE"
        )

      role_name = if user_count == 1, do: "Owner", else: "User"
      role_type = if user_count == 1, do: :owner, else: :user

      case assign_role(user, role_name) do
        {:ok, _assignment} -> role_type
        {:error, reason} -> repo.rollback(reason)
      end
    end)
  end

  @doc """
  Safely removes role with Owner protection.

  Prevents removal of Owner role if it would leave system without owners.

  ## Parameters

  - `user`: User to remove role from
  - `role_name`: Name of role to remove

  ## Examples

      iex> safely_remove_role(owner_user, "Owner")
      {:error, :cannot_remove_last_owner}
      
      iex> safely_remove_role(admin_user, "Admin") 
      {:ok, %RoleAssignment{}}
  """
  def safely_remove_role(%User{} = user, role_name) when role_name == "Owner" do
    repo = RepoHelper.repo()

    repo.transaction(fn ->
      remaining_owners = count_remaining_owners(repo, user.id)

      if remaining_owners < 1 do
        repo.rollback(:cannot_remove_last_owner)
      else
        execute_role_removal(user, role_name, repo)
      end
    end)
  end

  def safely_remove_role(%User{} = user, role_name) do
    # Non-Owner roles can be removed safely
    remove_role(user, role_name)
  end

  @doc """
  Checks if user can be deactivated safely.

  Prevents deactivation of last active Owner.

  ## Parameters

  - `user`: User to check for deactivation

  ## Examples

      iex> can_deactivate_user?(last_owner)
      {:error, :cannot_deactivate_last_owner}
      
      iex> can_deactivate_user?(regular_user)
      :ok
  """
  def can_deactivate_user?(%User{} = user) do
    if user_has_role?(user, "Owner") do
      case count_active_owners() do
        count when count <= 1 -> {:error, :cannot_deactivate_last_owner}
        _ -> :ok
      end
    else
      :ok
    end
  end

  # Private helper functions

  defp execute_role_removal(user, role_name, repo) do
    case remove_role(user, role_name) do
      {:ok, assignment} -> assignment
      {:error, reason} -> repo.rollback(reason)
    end
  end

  defp count_remaining_owners(repo, excluding_user_id) do
    repo.one(
      from u in User,
        join: assignment in assoc(u, :role_assignments),
        join: role in assoc(assignment, :role),
        where: role.name == "Owner",
        where: assignment.is_active == true,
        where: u.is_active == true,
        where: u.id != ^excluding_user_id,
        select: count(u.id)
    ) || 0
  end

  defp get_active_assignment(user_id, role_name) do
    repo = RepoHelper.repo()

    query =
      from assignment in RoleAssignment,
        join: role in assoc(assignment, :role),
        where: assignment.user_id == ^user_id,
        where: role.name == ^role_name,
        where: assignment.is_active == true

    repo.one(query)
  end
end
