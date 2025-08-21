defmodule PhoenixKit.Migrations.Postgres.V01 do
  @moduledoc false

  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    # Only create schema if it's not 'public' and create_schema is true
    if create? && prefix != "public", do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    # Create citext extension if not exists
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    # Create version tracking table (phoenix_kit)
    create_if_not_exists table(:phoenix_kit, primary_key: false, prefix: prefix) do
      add :id, :serial, primary_key: true
      add :version, :integer, null: false
      add :migrated_at, :naive_datetime, null: false, default: fragment("NOW()")
    end

    create_if_not_exists unique_index(:phoenix_kit, [:version], prefix: prefix)

    # Create users table (phoenix_kit_users)
    create_if_not_exists table(:phoenix_kit_users, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :first_name, :string, size: 100
      add :last_name, :string, size: 100
      add :is_active, :boolean, default: true, null: false
      add :confirmed_at, :naive_datetime

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:phoenix_kit_users, [:email], prefix: prefix)

    # Create tokens table (phoenix_kit_users_tokens)
    create_if_not_exists table(:phoenix_kit_users_tokens, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true

      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all, prefix: prefix),
        null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false, type: :naive_datetime)
    end

    create_if_not_exists index(:phoenix_kit_users_tokens, [:user_id], prefix: prefix)

    create_if_not_exists unique_index(:phoenix_kit_users_tokens, [:context, :token],
                           prefix: prefix
                         )

    # Create user roles table (phoenix_kit_user_roles)
    create_if_not_exists table(:phoenix_kit_user_roles, primary_key: false, prefix: prefix) do
      add :id, :bigserial, primary_key: true
      add :name, :string, size: 50, null: false
      add :description, :text
      add :is_system_role, :boolean, default: false, null: false

      timestamps(type: :naive_datetime)
    end

    create_if_not_exists unique_index(:phoenix_kit_user_roles, [:name], prefix: prefix)

    # Create user role assignments table (phoenix_kit_user_role_assignments)
    create_if_not_exists table(:phoenix_kit_user_role_assignments,
                           primary_key: false,
                           prefix: prefix
                         ) do
      add :id, :bigserial, primary_key: true

      add :user_id, references(:phoenix_kit_users, on_delete: :delete_all, prefix: prefix),
        null: false

      add :role_id, references(:phoenix_kit_user_roles, on_delete: :delete_all, prefix: prefix),
        null: false

      add :assigned_by, references(:phoenix_kit_users, on_delete: :nilify_all, prefix: prefix)
      add :assigned_at, :naive_datetime, null: false, default: fragment("NOW()")
      add :is_active, :boolean, default: true, null: false

      timestamps(updated_at: false, type: :naive_datetime)
    end

    create_if_not_exists index(:phoenix_kit_user_role_assignments, [:user_id], prefix: prefix)
    create_if_not_exists index(:phoenix_kit_user_role_assignments, [:role_id], prefix: prefix)
    create_if_not_exists index(:phoenix_kit_user_role_assignments, [:assigned_by], prefix: prefix)

    create_if_not_exists unique_index(:phoenix_kit_user_role_assignments, [:user_id, :role_id],
                           prefix: prefix
                         )

    # Performance optimization indexes for active role queries
    create_if_not_exists index(:phoenix_kit_user_role_assignments, [:user_id, :is_active],
                           prefix: prefix,
                           name: :idx_user_role_assignments_user_active
                         )

    create_if_not_exists index(:phoenix_kit_user_role_assignments, [:role_id, :is_active],
                           prefix: prefix,
                           name: :idx_user_role_assignments_role_active
                         )

    create_if_not_exists index(:phoenix_kit_users, [:is_active],
                           prefix: prefix,
                           name: :idx_users_active
                         )

    # Insert system roles
    execute """
    INSERT INTO #{inspect(prefix)}.phoenix_kit_user_roles (name, description, is_system_role, inserted_at, updated_at)
    VALUES 
      ('Owner', 'System owner with full access', true, NOW(), NOW()),
      ('Admin', 'Administrator with elevated privileges', true, NOW(), NOW()),
      ('User', 'Standard user with basic access', true, NOW(), NOW())
    ON CONFLICT (name) DO NOTHING
    """

    # Create function and trigger for auto-assigning Owner role to first user
    execute """
    CREATE OR REPLACE FUNCTION assign_owner_to_first_user()
    RETURNS TRIGGER AS $$
    DECLARE
      user_count INTEGER;
      owner_role_id BIGINT;
      user_role_id BIGINT;
      target_role_id BIGINT;
      target_role_name TEXT;
    BEGIN
      -- Get current user count (excluding the just-inserted user)
      SELECT COUNT(*) INTO user_count 
      FROM #{inspect(prefix)}.phoenix_kit_users 
      WHERE id != NEW.id;
      
      -- Get role IDs with error handling
      SELECT id INTO owner_role_id 
      FROM #{inspect(prefix)}.phoenix_kit_user_roles 
      WHERE name = 'Owner' AND is_system_role = true;
      
      SELECT id INTO user_role_id 
      FROM #{inspect(prefix)}.phoenix_kit_user_roles 
      WHERE name = 'User' AND is_system_role = true;
      
      -- Ensure roles exist
      IF owner_role_id IS NULL THEN
        RAISE EXCEPTION 'PhoenixKit: Owner role not found in phoenix_kit_user_roles table';
      END IF;
      
      IF user_role_id IS NULL THEN
        RAISE EXCEPTION 'PhoenixKit: User role not found in phoenix_kit_user_roles table';
      END IF;
      
      -- Determine role assignment based on user count
      IF user_count = 0 THEN
        -- This is the first user - assign Owner role
        target_role_id := owner_role_id;
        target_role_name := 'Owner';
        
        -- Log the Owner assignment
        RAISE NOTICE 'PhoenixKit: Assigning Owner role to first user (ID: %, Email: %)', 
          NEW.id, NEW.email;
      ELSE
        -- This is not the first user - assign User role
        target_role_id := user_role_id;
        target_role_name := 'User';
        
        -- Log the User assignment
        RAISE NOTICE 'PhoenixKit: Assigning User role to user (ID: %, Email: %)', 
          NEW.id, NEW.email;
      END IF;
      
      -- Perform the role assignment with error handling
      BEGIN
        INSERT INTO #{inspect(prefix)}.phoenix_kit_user_role_assignments 
          (user_id, role_id, assigned_at, is_active, inserted_at)
        VALUES 
          (NEW.id, target_role_id, NOW(), true, NOW())
        ON CONFLICT (user_id, role_id) DO NOTHING;
        
        -- Log successful assignment
        RAISE NOTICE 'PhoenixKit: Successfully assigned % role to user ID %', 
          target_role_name, NEW.id;
          
      EXCEPTION
        WHEN OTHERS THEN
          -- Log the error but don't fail the user creation
          RAISE WARNING 'PhoenixKit: Failed to assign % role to user ID %: % (SQLSTATE: %)', 
            target_role_name, NEW.id, SQLERRM, SQLSTATE;
            
          -- Continue with user creation despite role assignment failure
          RETURN NEW;
      END;
      
      RETURN NEW;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Critical error in the trigger itself
        RAISE WARNING 'PhoenixKit: Critical error in assign_owner_to_first_user trigger: % (SQLSTATE: %)', 
          SQLERRM, SQLSTATE;
        
        -- Return NEW to allow user creation to proceed
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER first_user_owner_trigger
      AFTER INSERT ON #{inspect(prefix)}.phoenix_kit_users
      FOR EACH ROW
      EXECUTE FUNCTION assign_owner_to_first_user()
    """
  end

  def down(%{prefix: prefix}) do
    # Drop trigger and function
    execute "DROP TRIGGER IF EXISTS first_user_owner_trigger ON #{inspect(prefix)}.phoenix_kit_users"
    execute "DROP FUNCTION IF EXISTS assign_owner_to_first_user()"

    # Drop tables in correct order (foreign key dependencies)
    drop_if_exists table(:phoenix_kit_user_role_assignments, prefix: prefix)
    drop_if_exists table(:phoenix_kit_user_roles, prefix: prefix)
    drop_if_exists table(:phoenix_kit_users_tokens, prefix: prefix)
    drop_if_exists table(:phoenix_kit_users, prefix: prefix)
    drop_if_exists table(:phoenix_kit, prefix: prefix)
  end
end
