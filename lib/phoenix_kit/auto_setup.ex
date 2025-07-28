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
    
    # First check if repo is explicitly configured
    case Application.get_env(:phoenix_kit, :repo) do
      nil ->
        Logger.debug("[PhoenixKit] No explicit repo configured, attempting auto-detection...")
        auto_detect_repo()
      
      repo when is_atom(repo) ->
        Logger.info("[PhoenixKit] Using explicitly configured repo: #{repo}")
        Logger.debug("[PhoenixKit] Configuration found: config :phoenix_kit, repo: #{repo}")
        # Ensure the application is loaded before validating repo
        if repo != PhoenixKit do
          app_module = repo |> Module.split() |> hd() |> String.downcase() |> String.to_atom()
          Logger.debug("[PhoenixKit] Ensuring application #{app_module} is loaded...")
          Application.ensure_loaded(app_module)
        end
        validate_repo(repo)
    end
  end

  defp auto_detect_repo do
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

  defp validate_repo(repo) do
    try do
      # First try to load the module
      case Code.ensure_loaded(repo) do
        {:module, module} ->
          if function_exported?(module, :__adapter__, 0) do
            # Try to get the adapter, but catch any errors
            try do
              adapter = module.__adapter__()
              if adapter == Ecto.Adapters.Postgres do
                {:ok, repo}
              else
                {:error, "Configured repo #{repo} is not using Postgres adapter (got #{adapter})"}
              end
            rescue
              _error ->
                # If we can't get adapter info, assume it's valid and let runtime handle it
                Logger.warning("[PhoenixKit] Could not verify adapter for #{repo}, proceeding anyway")
                {:ok, repo}
            end
          else
            {:error, "Configured repo #{repo} is not an Ecto.Repo (no __adapter__/0 function)"}
          end
        
        {:error, reason} ->
          # Try to be more helpful with common module loading issues
          case reason do
            :nofile ->
              {:error, "Configured repo #{repo} module not found. Make sure the parent application is compiled and loaded."}
            _ ->
              {:error, "Configured repo #{repo} could not be loaded: #{reason}"}
          end
      end
    rescue
      error ->
        Logger.warning("[PhoenixKit] Error validating repo #{repo}: #{inspect(error)}, proceeding anyway")
        {:ok, repo}
    end
  end

  defp find_main_app(apps) do
    # Exclude common library applications that are not the main Phoenix app
    excluded_apps = [
      :phoenix_kit, :phoenix, :phoenix_pubsub, :phoenix_live_view, 
      :phoenix_live_reload, :phoenix_live_dashboard, :phoenix_html,
      :phoenix_template, :plug, :plug_cowboy, :cowboy, :ecto, :ecto_sql,
      :postgrex, :gettext, :swoosh, :jason, :bandit, :thousand_island
    ]
    
    apps
    |> Enum.find(fn {app_name, _, _} -> 
      app_name not in excluded_apps and has_phoenix_dependency?(app_name)
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

  defp find_endpoint_module(app_name) do
    # Common endpoint module patterns
    possible_endpoints = [
      Module.concat([Macro.camelize(to_string(app_name)) <> "Web", "Endpoint"]),
      Module.concat([Macro.camelize(to_string(app_name)), "Web", "Endpoint"]),
      Module.concat([Macro.camelize(to_string(app_name)), "Endpoint"])
    ]

    Logger.debug("[PhoenixKit] Looking for endpoint in: #{inspect(possible_endpoints)}")

    endpoint = Enum.find(possible_endpoints, fn module ->
      loaded = Code.ensure_loaded?(module)
      is_endpoint = loaded && function_exported?(module, :call, 2) && function_exported?(module, :broadcast, 3)
      
      Logger.debug("[PhoenixKit] Checking #{module}: loaded=#{loaded}, is_endpoint=#{is_endpoint}")
      
      is_endpoint
    end)

    case endpoint do
      nil -> 
        Logger.error("[PhoenixKit] Could not find Phoenix.Endpoint module in parent application")
        Logger.error("[PhoenixKit] Tried: #{inspect(possible_endpoints)}")
        {:error, "Could not find Phoenix.Endpoint module in parent application"}
      endpoint_module -> 
        Logger.info("[PhoenixKit] Found endpoint: #{endpoint_module}")
        {:ok, endpoint_module}
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
      # Use the new Postgres migration system
      opts = %{prefix: "public", escaped_prefix: "public", version: 1, repo: repo}
      current_version = PhoenixKit.Migrations.Postgres.migrated_version(opts)
      
      if current_version < 1 do
        Logger.info("[PhoenixKit] Schema migration required: #{current_version} -> 1")
        
        case PhoenixKit.Migrations.Postgres.up(opts) do
          :ok -> 
            Logger.info("[PhoenixKit] Schema migration completed successfully")
            :ok
          {:error, reason} ->
            Logger.error("[PhoenixKit] Schema migration failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        Logger.debug("[PhoenixKit] Schema up to date at version #{current_version}")
        :ok
      end
    rescue
      error ->
        Logger.error("[PhoenixKit] Failed to ensure schema: #{inspect(error)}")
        Logger.error("[PhoenixKit] This might be due to database connection issues or insufficient permissions")
        {:error, error}
    end
  end

  # defp tables_exist?(repo) do
  #   # Check if phoenix_kit table exists
  #   query = """
  #   SELECT EXISTS (
  #     SELECT FROM information_schema.tables 
  #     WHERE table_name = 'phoenix_kit_users'
  #   );
  #   """
  #   
  #   case repo.query(query) do
  #     {:ok, %{rows: [[true]]}} -> true
  #     _ -> false
  #   end
  # end

  # defp create_tables!(repo) do
  #   # Execute the migration directly - functionality removed in favor of new migration system
  #   :ok
  # end

  @doc """
  Detects the parent application's Phoenix endpoint.
  """
  def detect_parent_endpoint do
    Logger.debug("[PhoenixKit] Detecting parent application endpoint...")
    
    # Get all loaded applications
    apps = Application.loaded_applications()
    
    # Find the main Phoenix application (not PhoenixKit)
    main_app = find_main_app(apps)
    
    case main_app do
      nil -> 
        Logger.error("[PhoenixKit] Could not detect parent Phoenix application for endpoint")
        {:error, "Could not detect parent Phoenix application"}
      app_name ->
        Logger.info("[PhoenixKit] Detected parent app for endpoint: #{app_name}")
        find_endpoint_module(app_name)
    end
  end

  @doc """
  Checks if PhoenixKit is properly set up.
  """
  def setup_complete? do
    case Application.get_env(:phoenix_kit, :repo) do
      nil -> 
        false
      _repo -> 
        try do
          # Check if migration has been completed by looking for version comment
          repo = Application.get_env(:phoenix_kit, :repo)
          opts = %{prefix: "public", escaped_prefix: "public", repo: repo}
          version = PhoenixKit.Migrations.Postgres.migrated_version(opts)
          version > 0
        rescue
          _error ->
            false
        end
    end
  end
end