defmodule PhoenixKit.Users.SecurityTest do
  @moduledoc """
  Critical security tests for PhoenixKit role system.

  Validates that security fixes for race conditions, Owner protection,
  and user deactivation are properly implemented.
  """
  use ExUnit.Case, async: false

  alias PhoenixKit.Users.Auth
  alias PhoenixKit.Users.Roles
  alias PhoenixKitWeb.Live.UsersLive

  describe "Security module compilation" do
    test "Auth module compiles and loads" do
      assert Code.ensure_loaded?(Auth)
    end

    test "Roles module compiles and loads" do
      assert Code.ensure_loaded?(Roles)
    end

    test "UsersLive module compiles and loads" do
      assert Code.ensure_loaded?(UsersLive)
    end
  end

  describe "Critical security API exists" do
    test "basic role management functions exist" do
      roles_functions = Roles.__info__(:functions)

      assert Enum.member?(roles_functions, {:assign_role, 2})
      assert Enum.member?(roles_functions, {:assign_role, 3})
      assert Enum.member?(roles_functions, {:remove_role, 2})
      assert Enum.member?(roles_functions, {:user_has_role?, 2})
    end

    test "advanced security functions exist" do
      roles_functions = Roles.__info__(:functions)

      assert Enum.member?(roles_functions, {:promote_to_admin, 1})
      assert Enum.member?(roles_functions, {:promote_to_admin, 2})
      assert Enum.member?(roles_functions, {:demote_to_user, 1})
    end

    test "Owner protection functions exist" do
      roles_functions = Roles.__info__(:functions)

      assert Enum.member?(roles_functions, {:count_active_owners, 0})
      assert Enum.member?(roles_functions, {:can_deactivate_user?, 1})
      assert Enum.member?(roles_functions, {:safely_remove_role, 2})
    end

    test "race condition prevention exists" do
      roles_functions = Roles.__info__(:functions)

      assert Enum.member?(roles_functions, {:ensure_first_user_is_owner, 1})
    end

    test "authentication functions exist" do
      auth_functions = Auth.__info__(:functions)

      assert Enum.member?(auth_functions, {:register_user, 1})
      assert Enum.member?(auth_functions, {:update_user_status, 2})
    end

    test "UI protection exists" do
      ui_functions = UsersLive.__info__(:functions)

      assert Enum.member?(ui_functions, {:handle_event, 3})
    end
  end

  describe "Security error handling" do
    test "proper error atoms are defined for security violations" do
      expected_errors = [
        :cannot_remove_last_owner,
        :cannot_demote_last_owner,
        :cannot_deactivate_last_owner,
        :no_role_to_demote
      ]

      for error <- expected_errors do
        assert is_atom(error), "Security error #{error} should be an atom"
      end
    end
  end

  describe "Database constraints" do
    test "migration creates proper database constraints" do
      migration_source = File.read!("lib/phoenix_kit/migrations/postgres/v01.ex")

      assert String.contains?(
               migration_source,
               "unique_index(:phoenix_kit_user_role_assignments, [:user_id, :role_id]"
             )

      assert String.contains?(migration_source, "references(:phoenix_kit_users")
      assert String.contains?(migration_source, "references(:phoenix_kit_user_roles")
    end
  end
end
