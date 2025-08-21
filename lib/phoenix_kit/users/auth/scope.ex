defmodule PhoenixKit.Users.Auth.Scope do
  @moduledoc """
  Scope module for encapsulating PhoenixKit authentication state.

  This module provides a structured way to handle user authentication context
  throughout your Phoenix application, similar to Phoenix's built-in authentication
  patterns but with PhoenixKit prefixing to avoid conflicts.

  ## Usage

      # Create scope for authenticated user
      scope = Scope.for_user(user)
      
      # Create scope for anonymous user  
      scope = Scope.for_user(nil)
      
      # Check authentication status
      Scope.authenticated?(scope)  # true or false
      
      # Get user information
      Scope.user(scope)        # %User{} or nil
      Scope.user_id(scope)     # user.id or nil
      Scope.user_email(scope)  # user.email or nil

  ## Struct Fields

  - `:user` - The current user struct or nil
  - `:authenticated?` - Boolean indicating if user is authenticated
  """

  alias PhoenixKit.Users.Auth.User

  @type t :: %__MODULE__{
          user: User.t() | nil,
          authenticated?: boolean()
        }

  defstruct user: nil, authenticated?: false

  @doc """
  Creates a new scope for the given user.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> scope.authenticated?
      true
      iex> scope.user.email
      "user@example.com"

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> scope.authenticated?
      false
      iex> scope.user
      nil
  """
  @spec for_user(User.t() | nil) :: t()
  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      authenticated?: true
    }
  end

  def for_user(nil) do
    %__MODULE__{
      user: nil,
      authenticated?: false
    }
  end

  @doc """
  Checks if the scope represents an authenticated user.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.authenticated?(scope)
      true

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.authenticated?(scope)
      false
  """
  @spec authenticated?(t()) :: boolean()
  def authenticated?(%__MODULE__{authenticated?: authenticated?}), do: authenticated?

  @doc """
  Gets the user from the scope.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user(scope)
      %PhoenixKit.Users.Auth.User{id: 1, email: "user@example.com"}

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user(scope)
      nil
  """
  @spec user(t()) :: User.t() | nil
  def user(%__MODULE__{user: user}), do: user

  @doc """
  Gets the user ID from the scope.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 123}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user_id(scope)
      123

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user_id(scope)
      nil
  """
  @spec user_id(t()) :: integer() | nil
  def user_id(%__MODULE__{user: %User{id: id}}), do: id
  def user_id(%__MODULE__{user: nil}), do: nil

  @doc """
  Gets the user email from the scope.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user_email(scope)
      "user@example.com"

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user_email(scope)
      nil
  """
  @spec user_email(t()) :: String.t() | nil
  def user_email(%__MODULE__{user: %User{email: email}}), do: email
  def user_email(%__MODULE__{user: nil}), do: nil

  @doc """
  Checks if the scope represents an anonymous (non-authenticated) user.

  ## Examples

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.anonymous?(scope)
      true

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.anonymous?(scope)
      false
  """
  @spec anonymous?(t()) :: boolean()
  def anonymous?(%__MODULE__{authenticated?: authenticated?}), do: not authenticated?

  @doc """
  Checks if the user has a specific role.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.has_role?(scope, "Admin")
      true

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.has_role?(scope, "Admin")
      false
  """
  @spec has_role?(t(), String.t()) :: boolean()
  def has_role?(%__MODULE__{user: %User{} = user}, role_name) when is_binary(role_name) do
    User.has_role?(user, role_name)
  end

  def has_role?(%__MODULE__{user: nil}, _role_name), do: false

  @doc """
  Checks if the user is an owner.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.owner?(scope)
      true

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.owner?(scope)
      false
  """
  @spec owner?(t()) :: boolean()
  def owner?(%__MODULE__{user: %User{} = user}) do
    User.owner?(user)
  end

  def owner?(%__MODULE__{user: nil}), do: false

  @doc """
  Checks if the user is an admin or owner.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.admin?(scope)
      true

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.admin?(scope)
      false
  """
  @spec admin?(t()) :: boolean()
  def admin?(%__MODULE__{user: %User{} = user}) do
    User.admin?(user)
  end

  def admin?(%__MODULE__{user: nil}), do: false

  @doc """
  Gets all roles for the user.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user_roles(scope)
      ["Admin", "User"]

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user_roles(scope)
      []
  """
  @spec user_roles(t()) :: [String.t()]
  def user_roles(%__MODULE__{user: %User{} = user}) do
    User.get_roles(user)
  end

  def user_roles(%__MODULE__{user: nil}), do: []

  @doc """
  Gets the user's full name.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{first_name: "John", last_name: "Doe"}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user_full_name(scope)
      "John Doe"

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user_full_name(scope)
      nil
  """
  @spec user_full_name(t()) :: String.t() | nil
  def user_full_name(%__MODULE__{user: %User{} = user}) do
    User.full_name(user)
  end

  def user_full_name(%__MODULE__{user: nil}), do: nil

  @doc """
  Checks if the user is active.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{is_active: true}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.user_active?(scope)
      true

      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(nil)
      iex> PhoenixKit.Users.Auth.Scope.user_active?(scope)
      false
  """
  @spec user_active?(t()) :: boolean()
  def user_active?(%__MODULE__{user: %User{is_active: is_active}}) do
    is_active
  end

  def user_active?(%__MODULE__{user: nil}), do: false

  @doc """
  Converts scope to a map for debugging or logging purposes.

  ## Examples

      iex> user = %PhoenixKit.Users.Auth.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Users.Auth.Scope.for_user(user)
      iex> PhoenixKit.Users.Auth.Scope.to_map(scope)
      %{
        authenticated?: true,
        user_id: 1,
        user_email: "user@example.com",
        user_roles: ["Admin", "User"],
        owner?: false,
        admin?: true
      }
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = scope) do
    %{
      authenticated?: authenticated?(scope),
      user_id: user_id(scope),
      user_email: user_email(scope),
      user_full_name: user_full_name(scope),
      user_roles: user_roles(scope),
      owner?: owner?(scope),
      admin?: admin?(scope),
      user_active?: user_active?(scope)
    }
  end
end
