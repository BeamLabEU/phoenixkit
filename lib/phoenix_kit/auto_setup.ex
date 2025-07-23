defmodule PhoenixKit.AutoSetup do
  @moduledoc """
  Zero-configuration automatic setup for PhoenixKit.
  
  This module handles automatic detection and setup of PhoenixKit
  in parent Phoenix applications without requiring manual configuration.
  """

  require Logger

  @doc """
  Automatically configures PhoenixKit for the parent application.
  
  This function:
  1. Detects the parent application's repo
  2. Configures PhoenixKit to use that repo
  3. Ensures required database tables exist
  4. Sets up the authentication system
  
  Called automatically when PhoenixKit routes are first accessed.
  """
  def ensure_setup! do
    Logger.info("[PhoenixKit] Starting zero-config setup...")
    
    with {:ok, repo} <- detect_parent_repo(),
         :ok <- configure_repo(repo),
         :ok <- ensure_tables_exist(repo) do
      Logger.info("[PhoenixKit] Zero-config setup completed successfully")
      :ok
    else
      {:error, reason} ->
        Logger.error("[PhoenixKit] Auto-setup failed: #{inspect(reason)}")
        Logger.error("[PhoenixKit] Manual setup may be required. See documentation.")
        {:error, reason}
    end
  end

  @doc """
  Detects the parent application's Ecto repository.
  """
  def detect_parent_repo do
    Logger.debug("[PhoenixKit] Detecting parent application repository...")
    
    # Get all loaded applications
    apps = Application.loaded_applications()
    Logger.debug("[PhoenixKit] Loaded applications: #{inspect(Enum.map(apps, fn {name, _, _} -> name end))}")
    
    # Find the main Phoenix application (not PhoenixKit)
    main_app = find_main_app(apps)
    
    case main_app do
      nil -> 
        Logger.error("[PhoenixKit] Could not detect parent Phoenix application")
        Logger.error("[PhoenixKit] Available apps: #{inspect(Enum.map(apps, fn {name, _, _} -> name end))}")
        {:error, "Could not detect parent Phoenix application"}
      app_name ->
        Logger.info("[PhoenixKit] Detected parent app: #{app_name}")
        find_repo_module(app_name)
    end
  end

  defp find_main_app(apps) do
    apps
    |> Enum.find(fn {app_name, _, _} -> 
      app_name != :phoenix_kit and has_phoenix_dependency?(app_name)
    end)
    |> case do
      {app_name, _, _} -> app_name
      nil -> nil
    end
  end

  defp has_phoenix_dependency?(app_name) do
    try do
      deps = Application.spec(app_name, :applications) || []
      :phoenix in deps
    rescue
      _ -> false
    end
  end

  defp find_repo_module(app_name) do
    # Common repo module patterns
    possible_repos = [
      Module.concat([Macro.camelize(to_string(app_name)), "Repo"]),
      Module.concat([Macro.camelize(to_string(app_name)), "App", "Repo"]),
      Module.concat([Macro.camelize(to_string(app_name)) <> "Web", "Repo"])
    ]

    Logger.debug("[PhoenixKit] Looking for repo in: #{inspect(possible_repos)}")

    repo = Enum.find(possible_repos, fn module ->
      loaded = Code.ensure_loaded?(module)
      has_adapter = loaded && function_exported?(module, :__adapter__, 0)
      is_postgres = has_adapter && module.__adapter__() == Ecto.Adapters.Postgres
      
      Logger.debug("[PhoenixKit] Checking #{module}: loaded=#{loaded}, has_adapter=#{has_adapter}, is_postgres=#{is_postgres}")
      
      is_postgres
    end)

    case repo do
      nil -> 
        Logger.error("[PhoenixKit] Could not find Ecto.Repo module in parent application")
        Logger.error("[PhoenixKit] Tried: #{inspect(possible_repos)}")
        {:error, "Could not find Ecto.Repo module in parent application"}
      repo_module -> 
        Logger.info("[PhoenixKit] Found repo: #{repo_module}")
        {:ok, repo_module}
    end
  end

  defp configure_repo(repo) do
    # Configure PhoenixKit to use the detected repo
    Application.put_env(:phoenix_kit, :repo, repo)
    Logger.info("[PhoenixKit] Configured to use repo: #{inspect(repo)}")
    :ok
  end

  defp ensure_tables_exist(repo) do
    Logger.debug("[PhoenixKit] Checking schema version and migrations...")
    
    try do
      # Use the new schema migration system
      if PhoenixKit.SchemaMigrations.migration_required?(repo) do
        installed = PhoenixKit.SchemaMigrations.get_installed_version(repo)
        target = PhoenixKit.SchemaMigrations.get_target_version()
        
        Logger.info("[PhoenixKit] Schema migration required: #{installed || "fresh"} -> #{target}")
        
        case PhoenixKit.SchemaMigrations.migrate_to_current(repo) do
          :ok -> 
            Logger.info("[PhoenixKit] Schema migration completed successfully")
            :ok
          {:error, reason} ->
            Logger.error("[PhoenixKit] Schema migration failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        installed = PhoenixKit.SchemaMigrations.get_installed_version(repo)
        Logger.debug("[PhoenixKit] Schema up to date at version #{installed}")
        :ok
      end
    rescue
      error ->
        Logger.error("[PhoenixKit] Failed to ensure schema: #{inspect(error)}")
        Logger.error("[PhoenixKit] This might be due to database connection issues or insufficient permissions")
        {:error, error}
    end
  end

  defp tables_exist?(repo) do
    # Check if phoenix_kit table exists
    query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_name = 'phoenix_kit'
    );
    """
    
    case repo.query(query) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end

  defp create_tables!(repo) do
    # Execute the migration directly
    migration_sql = """
    CREATE EXTENSION IF NOT EXISTS citext;

    CREATE TABLE IF NOT EXISTS phoenix_kit (
      id bigserial PRIMARY KEY,
      email citext NOT NULL,
      hashed_password varchar(255) NOT NULL,
      confirmed_at timestamp,
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );

    CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_email_index ON phoenix_kit (email);

    CREATE TABLE IF NOT EXISTS phoenix_kit_tokens (
      id bigserial PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES phoenix_kit(id) ON DELETE CASCADE,
      token bytea NOT NULL,
      context varchar(255) NOT NULL,
      sent_to varchar(255),
      inserted_at timestamp NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS phoenix_kit_tokens_user_id_index ON phoenix_kit_tokens (user_id);
    CREATE UNIQUE INDEX IF NOT EXISTS phoenix_kit_tokens_context_token_index ON phoenix_kit_tokens (context, token);
    """

    case repo.query(migration_sql) do
      {:ok, _} -> 
        Logger.info("[PhoenixKit] Database tables created successfully")
        :ok
      {:error, error} -> 
        raise "Failed to create PhoenixKit tables: #{inspect(error)}"
    end
  end

  @doc """
  Checks if PhoenixKit is properly set up.
  """
  def setup_complete? do
    case Application.get_env(:phoenix_kit, :repo) do
      nil -> false
      repo -> 
        try do
          # Check if schema is up to date
          not PhoenixKit.SchemaMigrations.migration_required?(repo)
        rescue
          _ -> false
        end
    end
  end
end