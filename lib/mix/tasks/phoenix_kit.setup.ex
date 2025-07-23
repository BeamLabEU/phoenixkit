defmodule Mix.Tasks.PhoenixKit.Setup do
  @moduledoc """
  Manual setup task for PhoenixKit authentication tables.
  
  This task can be used if the automatic zero-config setup fails.
  
  ## Usage
  
  Run this task in your Phoenix application directory:
  
      mix phoenix_kit.setup
  
  Or with a specific repo:
  
      mix phoenix_kit.setup --repo MyApp.Repo
  
  ## What it does
  
  1. Detects your application's Ecto repository
  2. Creates the required PhoenixKit authentication tables
  3. Configures PhoenixKit to use your repository
  
  ## Prerequisites
  
  - Your Phoenix application must have Ecto configured
  - Database must be created and accessible
  - User must have CREATE TABLE permissions
  """
  
  use Mix.Task
  require Logger

  @shortdoc "Manually set up PhoenixKit authentication tables"

  def run(args) do
    Mix.Task.run("app.start")
    
    {opts, _, _} = OptionParser.parse(args, switches: [repo: :string])
    
    Logger.info("PhoenixKit Manual Setup")
    Logger.info("======================")
    
    repo = case opts[:repo] do
      nil ->
        Logger.info("Detecting repository automatically...")
        case PhoenixKit.AutoSetup.detect_parent_repo() do
          {:ok, detected_repo} ->
            Logger.info("Detected repo: #{inspect(detected_repo)}")
            detected_repo
          {:error, reason} ->
            Logger.error("Could not detect repository: #{reason}")
            Logger.error("Please specify repo with: mix phoenix_kit.setup --repo YourApp.Repo")
            exit({:shutdown, 1})
        end
      repo_string ->
        Logger.info("Using specified repo: #{repo_string}")
        Module.concat([repo_string])
    end
    
    # Verify repo exists and is accessible
    unless Code.ensure_loaded?(repo) do
      Logger.error("Repository module #{repo} not found or not loaded")
      exit({:shutdown, 1})
    end
    
    unless function_exported?(repo, :__adapter__, 0) do
      Logger.error("#{repo} is not an Ecto repository")
      exit({:shutdown, 1})
    end
    
    # Configure PhoenixKit
    Logger.info("Configuring PhoenixKit to use #{repo}...")
    Application.put_env(:phoenix_kit, :repo, repo)
    
    # Create tables
    Logger.info("Creating authentication tables...")
    
    case create_tables(repo) do
      :ok ->
        Logger.info("✅ PhoenixKit setup completed successfully!")
        Logger.info("")
        Logger.info("Tables created:")
        Logger.info("- phoenix_kit (users)")
        Logger.info("- phoenix_kit_tokens (authentication tokens)")
        Logger.info("")
        Logger.info("You can now use PhoenixKit authentication in your app:")
        Logger.info("")
        Logger.info("# In your router.ex:")
        Logger.info("import PhoenixKitWeb.Integration")  
        Logger.info("phoenix_kit_auth_routes()")
        Logger.info("")
        Logger.info("Authentication will be available at /phoenix_kit/register and /phoenix_kit/log_in")
        
      {:error, reason} ->
        Logger.error("❌ Failed to create tables: #{inspect(reason)}")
        Logger.error("")
        Logger.error("Common issues:")
        Logger.error("- Database not accessible")
        Logger.error("- Insufficient permissions") 
        Logger.error("- PostgreSQL citext extension not available")
        Logger.error("")
        Logger.error("Try running: CREATE EXTENSION IF NOT EXISTS citext;")
        Logger.error("in your PostgreSQL database as a superuser.")
        exit({:shutdown, 1})
    end
  end
  
  defp create_tables(repo) do
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
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end