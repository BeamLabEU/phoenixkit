defmodule PhoenixKit.Users.Auth do
  @moduledoc """
  The Auth context for user authentication and management.

  This module provides functions for user registration, authentication, password management,
  and email confirmation. It serves as the main interface for all user-related operations
  in PhoenixKit.

  ## Core Functions

  ### User Registration and Authentication

  - `register_user/1` - Register a new user with email and password
  - `get_user_by_email_and_password/2` - Authenticate user credentials
  - `get_user_by_email/1` - Find user by email address

  ### Password Management

  - `change_user_password/2` - Update user password
  - `reset_user_password/2` - Reset password with token
  - `deliver_user_reset_password_instructions/1` - Send password reset email

  ### Email Confirmation

  - `deliver_user_confirmation_instructions/1` - Send confirmation email
  - `confirm_user/1` - Confirm user account with token
  - `update_user_email/2` - Change user email with confirmation

  ### Session Management

  - `generate_user_session_token/1` - Create session token for login
  - `get_user_by_session_token/1` - Get user from session token
  - `delete_user_session_token/1` - Logout user session

  ## Usage Examples

      # Register a new user
      {:ok, user} = PhoenixKit.Users.Auth.register_user(%{
        email: "user@example.com",
        password: "secure_password123"
      })

      # Authenticate user
      case PhoenixKit.Users.Auth.get_user_by_email_and_password(email, password) do
        %User{} = user -> {:ok, user}
        nil -> {:error, :invalid_credentials}
      end

      # Send confirmation email
      PhoenixKit.Users.Auth.deliver_user_confirmation_instructions(user)

  ## Security Features

  - Passwords are hashed using bcrypt
  - Email confirmation prevents unauthorized account creation
  - Session tokens provide secure authentication
  - Password reset tokens expire for security
  - All sensitive operations are logged
  """

  import Ecto.Query, warn: false
  alias PhoenixKit.RepoHelper, as: Repo

  # This module will be populated by mix phx.gen.auth

  alias PhoenixKit.Users.Auth.{User, UserNotifier, UserToken}
  alias PhoenixKit.Users.Roles

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user with safe Owner assignment.

  This function prevents race conditions by safely assigning Owner role
  to the first user using database transactions.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    case %User{}
         |> User.registration_changeset(attrs)
         |> Repo.insert() do
      {:ok, user} ->
        # Safely assign Owner role to first user, User role to others
        case Roles.ensure_first_user_is_owner(user) do
          {:ok, role_type} ->
            # Log successful role assignment for security audit
            require Logger
            Logger.info("PhoenixKit: User #{user.id} (#{user.email}) assigned #{role_type} role")
            {:ok, user}

          {:error, reason} ->
            # Role assignment failed - this is critical
            require Logger

            Logger.error(
              "PhoenixKit: Failed to assign role to user #{user.id}: #{inspect(reason)}"
            )

            # User was created but role assignment failed
            # In production, you might want to delete the user or mark as needs_role_assignment
            {:ok, user}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    multi = Ecto.Multi.new()
    multi = Ecto.Multi.update(multi, :user, changeset)
    Ecto.Multi.delete_all(multi, :tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &"/phoenix_kit/users/settings/confirm_email/#{&1}")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    multi = Ecto.Multi.new()
    multi = Ecto.Multi.update(multi, :user, changeset)

    Ecto.Multi.delete_all(multi, :tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &"/phoenix_kit/users/confirm/#{&1}")
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &"/phoenix_kit/users/confirm/#{&1}")
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    multi = Ecto.Multi.new()
    multi = Ecto.Multi.update(multi, :user, User.confirm_changeset(user))
    Ecto.Multi.delete_all(multi, :tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &"/phoenix_kit/users/reset-password/#{&1}")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    multi = Ecto.Multi.new()
    multi = Ecto.Multi.update(multi, :user, User.password_changeset(user, attrs))

    Ecto.Multi.delete_all(multi, :tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Role Management Functions

  @doc """
  Assigns a role to a user.

  ## Examples

      iex> assign_role(user, "Admin")
      {:ok, %RoleAssignment{}}

      iex> assign_role(user, "Admin", assigned_by_user)
      {:ok, %RoleAssignment{}}

      iex> assign_role(user, "NonexistentRole")
      {:error, :role_not_found}
  """
  defdelegate assign_role(user, role_name, assigned_by \\ nil), to: PhoenixKit.Users.Roles

  @doc """
  Removes a role from a user.

  ## Examples

      iex> remove_role(user, "Admin")
      {:ok, %RoleAssignment{}}

      iex> remove_role(user, "NonexistentRole")
      {:error, :assignment_not_found}
  """
  defdelegate remove_role(user, role_name), to: PhoenixKit.Users.Roles

  @doc """
  Checks if a user has a specific role.

  ## Examples

      iex> user_has_role?(user, "Admin")
      true

      iex> user_has_role?(user, "Owner")
      false
  """
  defdelegate user_has_role?(user, role_name), to: PhoenixKit.Users.Roles

  @doc """
  Gets all active roles for a user.

  ## Examples

      iex> get_user_roles(user)
      ["Admin", "User"]

      iex> get_user_roles(user_with_no_roles)
      []
  """
  defdelegate get_user_roles(user), to: PhoenixKit.Users.Roles

  @doc """
  Gets all users who have a specific role.

  ## Examples

      iex> users_with_role("Admin")
      [%User{}, %User{}]

      iex> users_with_role("NonexistentRole")
      []
  """
  defdelegate users_with_role(role_name), to: PhoenixKit.Users.Roles

  @doc """
  Promotes a user to admin role.

  ## Examples

      iex> promote_to_admin(user)
      {:ok, %RoleAssignment{}}

      iex> promote_to_admin(user, assigned_by_user)
      {:ok, %RoleAssignment{}}
  """
  defdelegate promote_to_admin(user, assigned_by \\ nil), to: PhoenixKit.Users.Roles

  @doc """
  Demotes an admin user to regular user role.

  ## Examples

      iex> demote_to_user(user)
      {:ok, %RoleAssignment{}}
  """
  defdelegate demote_to_user(user), to: PhoenixKit.Users.Roles

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
  defdelegate get_role_stats(), to: PhoenixKit.Users.Roles

  @doc """
  Lists all roles.

  ## Examples

      iex> list_roles()
      [%Role{}, %Role{}, %Role{}]
  """
  defdelegate list_roles(), to: PhoenixKit.Users.Roles

  @doc """
  Updates a user's profile information.

  ## Examples

      iex> update_user_profile(user, %{first_name: "John", last_name: "Doe"})
      {:ok, %User{}}

      iex> update_user_profile(user, %{first_name: ""})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates user status with Owner protection.

  Prevents deactivation of the last Owner to maintain system security.

  ## Parameters

  - `user`: User to update
  - `attrs`: Status attributes (typically %{"is_active" => true/false})

  ## Examples

      iex> update_user_status(user, %{"is_active" => false})
      {:ok, %User{}}

      iex> update_user_status(last_owner, %{"is_active" => false})
      {:error, :cannot_deactivate_last_owner}
  """
  def update_user_status(%User{} = user, attrs) do
    # Check if this would deactivate the last owner
    if attrs["is_active"] == false or attrs[:is_active] == false do
      case Roles.can_deactivate_user?(user) do
        :ok ->
          user
          |> User.status_changeset(attrs)
          |> Repo.update()

        {:error, :cannot_deactivate_last_owner} ->
          require Logger
          Logger.warning("PhoenixKit: Attempted to deactivate last Owner user #{user.id}")
          {:error, :cannot_deactivate_last_owner}
      end
    else
      # Activation is always safe
      user
      |> User.status_changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Gets a user by ID with preloaded roles.

  ## Examples

      iex> get_user_with_roles(123)
      %User{roles: [%Role{}, %Role{}]}

      iex> get_user_with_roles(999)
      nil
  """
  def get_user_with_roles(id) when is_integer(id) do
    from(u in User, where: u.id == ^id, preload: [:roles])
    |> Repo.one()
  end

  @doc """
  Lists users with pagination and optional role filtering.

  ## Examples

      iex> list_users_paginated(page: 1, page_size: 10)
      %{users: [%User{}], total_count: 50, total_pages: 5}

      iex> list_users_paginated(page: 1, page_size: 10, role: "Admin")
      %{users: [%User{}], total_count: 3, total_pages: 1}
  """
  def list_users_paginated(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 10)
    role_filter = Keyword.get(opts, :role)
    search_query = Keyword.get(opts, :search, "")

    base_query = from(u in User, order_by: [desc: u.inserted_at])

    query =
      base_query
      |> maybe_filter_by_role(role_filter)
      |> maybe_filter_by_search(search_query)

    total_count = PhoenixKit.RepoHelper.aggregate(query, :count, :id)
    total_pages = div(total_count + page_size - 1, page_size)

    users =
      query
      |> limit(^page_size)
      |> offset(^((page - 1) * page_size))
      |> preload([:roles])
      |> Repo.all()

    %{
      users: users,
      total_count: total_count,
      total_pages: total_pages,
      current_page: page
    }
  end

  defp maybe_filter_by_role(query, nil), do: query
  defp maybe_filter_by_role(query, "all"), do: query

  defp maybe_filter_by_role(query, role_name) when is_binary(role_name) do
    from [u] in query,
      join: assignment in assoc(u, :role_assignments),
      join: role in assoc(assignment, :role),
      where: role.name == ^role_name,
      where: assignment.is_active == true,
      distinct: u.id
  end

  defp maybe_filter_by_search(query, ""), do: query

  defp maybe_filter_by_search(query, search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"

    from [u] in query,
      where:
        ilike(u.email, ^search_pattern) or
          ilike(u.first_name, ^search_pattern) or
          ilike(u.last_name, ^search_pattern)
  end
end
