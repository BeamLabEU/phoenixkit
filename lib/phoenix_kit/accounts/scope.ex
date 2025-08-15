defmodule PhoenixKit.Accounts.Scope do
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

  alias PhoenixKit.Accounts.User

  @type t :: %__MODULE__{
          user: User.t() | nil,
          authenticated?: boolean()
        }

  defstruct user: nil, authenticated?: false

  @doc """
  Creates a new scope for the given user.

  ## Examples

      iex> user = %PhoenixKit.Accounts.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> scope.authenticated?
      true
      iex> scope.user.email
      "user@example.com"

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
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

      iex> user = %PhoenixKit.Accounts.User{id: 1}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.authenticated?(scope)
      true

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
      iex> PhoenixKit.Accounts.Scope.authenticated?(scope)
      false
  """
  @spec authenticated?(t()) :: boolean()
  def authenticated?(%__MODULE__{authenticated?: authenticated?}), do: authenticated?

  @doc """
  Gets the user from the scope.

  ## Examples

      iex> user = %PhoenixKit.Accounts.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.user(scope)
      %PhoenixKit.Accounts.User{id: 1, email: "user@example.com"}

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
      iex> PhoenixKit.Accounts.Scope.user(scope)
      nil
  """
  @spec user(t()) :: User.t() | nil
  def user(%__MODULE__{user: user}), do: user

  @doc """
  Gets the user ID from the scope.

  ## Examples

      iex> user = %PhoenixKit.Accounts.User{id: 123}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.user_id(scope)
      123

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
      iex> PhoenixKit.Accounts.Scope.user_id(scope)
      nil
  """
  @spec user_id(t()) :: integer() | nil
  def user_id(%__MODULE__{user: %User{id: id}}), do: id
  def user_id(%__MODULE__{user: nil}), do: nil

  @doc """
  Gets the user email from the scope.

  ## Examples

      iex> user = %PhoenixKit.Accounts.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.user_email(scope)
      "user@example.com"

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
      iex> PhoenixKit.Accounts.Scope.user_email(scope)
      nil
  """
  @spec user_email(t()) :: String.t() | nil
  def user_email(%__MODULE__{user: %User{email: email}}), do: email
  def user_email(%__MODULE__{user: nil}), do: nil

  @doc """
  Checks if the scope represents an anonymous (non-authenticated) user.

  ## Examples

      iex> scope = PhoenixKit.Accounts.Scope.for_user(nil)
      iex> PhoenixKit.Accounts.Scope.anonymous?(scope)
      true

      iex> user = %PhoenixKit.Accounts.User{id: 1}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.anonymous?(scope)
      false
  """
  @spec anonymous?(t()) :: boolean()
  def anonymous?(%__MODULE__{authenticated?: authenticated?}), do: not authenticated?

  @doc """
  Converts scope to a map for debugging or logging purposes.

  ## Examples

      iex> user = %PhoenixKit.Accounts.User{id: 1, email: "user@example.com"}
      iex> scope = PhoenixKit.Accounts.Scope.for_user(user)
      iex> PhoenixKit.Accounts.Scope.to_map(scope)
      %{
        authenticated?: true,
        user_id: 1,
        user_email: "user@example.com"
      }
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = scope) do
    %{
      authenticated?: authenticated?(scope),
      user_id: user_id(scope),
      user_email: user_email(scope)
    }
  end
end
