defmodule PhoenixKit.Accounts.User do
  @moduledoc """
  User schema for PhoenixKit authentication system.

  This schema defines the core user entity with email-based authentication and account management features.

  ## Fields

  - `email`: User's email address (unique, required for authentication)
  - `password`: Virtual field for password input (redacted in logs)
  - `hashed_password`: Bcrypt-hashed password stored in database (redacted)
  - `current_password`: Virtual field for password confirmation (redacted)
  - `confirmed_at`: Timestamp when email was confirmed (nil for unconfirmed accounts)
  - `role`: User role for authorization (user, moderator, admin)
  - `roles2`: Secondary user role (guest, member, editor, owner)

  ## Security Features

  - Password hashing with bcrypt
  - Email uniqueness enforcement
  - Password strength validation
  - Sensitive field redaction in logs
  - Email confirmation workflow support
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "phoenix_kit_users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :naive_datetime
    
    # User role for authorization
    field :role, Ecto.Enum, 
      values: [:user, :moderator, :admin], 
      default: :user

    # Secondary role system
    field :roles2, Ecto.Enum,
      values: [:guest, :member, :editor, :owner],
      default: :guest

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :role, :roles2])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_role()
    |> validate_roles2()
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, PhoenixKit.RepoHelper.repo())
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%PhoenixKit.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for role changes.
  
  This changeset should typically only be used by administrators
  to change user roles.
  """
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_role()
  end

  @doc """
  A user changeset for roles2 changes.
  
  This changeset can be used to manage secondary role system.
  """
  def roles2_changeset(user, attrs) do
    user
    |> cast(attrs, [:roles2])
    |> validate_roles2()
  end

  defp validate_role(changeset) do
    changeset
    |> validate_inclusion(:role, [:user, :moderator, :admin])
  end

  defp validate_roles2(changeset) do
    changeset
    |> validate_inclusion(:roles2, [:guest, :member, :editor, :owner])
  end

  # Role checking helper functions

  @doc """
  Returns true if user has admin role.
  """
  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false

  @doc """
  Returns true if user has moderator or admin role.
  """
  def moderator?(%__MODULE__{role: role}) when role in [:moderator, :admin], do: true
  def moderator?(_), do: false

  @doc """
  Returns true if user has regular user role.
  """
  def user?(%__MODULE__{role: :user}), do: true
  def user?(_), do: false

  @doc """
  Returns true if user can perform moderation actions (moderator or admin).
  """
  def can_moderate?(%__MODULE__{role: role}) when role in [:moderator, :admin], do: true
  def can_moderate?(_), do: false

  @doc """
  Checks if user has at least the required role level.
  
  Role hierarchy: user < moderator < admin
  
  ## Examples
  
      iex> user = %User{role: :admin}
      iex> User.has_role_level?(user, :moderator)
      true
      
      iex> user = %User{role: :user}
      iex> User.has_role_level?(user, :admin)
      false
  """
  def has_role_level?(%__MODULE__{role: user_role}, required_role) do
    role_levels = %{user: 1, moderator: 2, admin: 3}
    Map.get(role_levels, user_role, 0) >= Map.get(role_levels, required_role, 999)
  end

  # Roles2 checking helper functions

  @doc """
  Returns true if user has owner roles2.
  """
  def owner?(%__MODULE__{roles2: :owner}), do: true
  def owner?(_), do: false

  @doc """
  Returns true if user has editor or owner roles2.
  """
  def editor?(%__MODULE__{roles2: roles2}) when roles2 in [:editor, :owner], do: true
  def editor?(_), do: false

  @doc """
  Returns true if user has member, editor or owner roles2.
  """
  def member?(%__MODULE__{roles2: roles2}) when roles2 in [:member, :editor, :owner], do: true
  def member?(_), do: false

  @doc """
  Returns true if user has guest roles2.
  """
  def guest?(%__MODULE__{roles2: :guest}), do: true
  def guest?(_), do: false

  @doc """
  Returns true if user can edit content (editor or owner).
  """
  def can_edit?(%__MODULE__{roles2: roles2}) when roles2 in [:editor, :owner], do: true
  def can_edit?(_), do: false

  @doc """
  Checks if user has at least the required roles2 level.
  
  Roles2 hierarchy: guest < member < editor < owner
  
  ## Examples
  
      iex> user = %User{roles2: :owner}
      iex> User.has_roles2_level?(user, :editor)
      true
      
      iex> user = %User{roles2: :guest}
      iex> User.has_roles2_level?(user, :member)
      false
  """
  def has_roles2_level?(%__MODULE__{roles2: user_roles2}, required_roles2) do
    roles2_levels = %{guest: 1, member: 2, editor: 3, owner: 4}
    Map.get(roles2_levels, user_roles2, 0) >= Map.get(roles2_levels, required_roles2, 999)
  end
end
