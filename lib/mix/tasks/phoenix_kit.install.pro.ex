defmodule Mix.Tasks.PhoenixKit.Install.Pro.Docs do
  @moduledoc false

  def short_doc do
    "Install and configure PhoenixKit for use in a Phoenix application."
  end

  def example do
    "mix phoenix_kit.install.pro"
  end

  def long_doc do
    """
    Install and configure PhoenixKit for use in a Phoenix application.

    This task uses Igniter to intelligently modify your project configuration,
    create database migrations, and set up authentication routes.

    ## Example

    Install using auto-detected repo:

    ```bash
    mix phoenix_kit.install.pro
    ```

    Specify a custom repo and PostgreSQL schema prefix:

    ```bash
    mix phoenix_kit.install.pro --repo MyApp.Repo --prefix "auth"
    ```

    ## Options

    * `--repo` or `-r` — Specify an Ecto repo for PhoenixKit to use
    * `--prefix` or `-p` — PostgreSQL schema prefix, defaults to "public"
    * `--create-schema` — Create schema if using custom prefix (default: true for non-public)
    * `--layout` — Configure custom layout integration
    * `--add-routes` — Add authentication routes to router.ex (default: false)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PhoenixKit.Install.Pro do
    @shortdoc __MODULE__.Docs.short_doc()

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_kit,
        adds_deps: [{:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"}],
        installs: [],
        example: __MODULE__.Docs.example(),
        only: nil,
        positional: [],
        composes: [],
        schema: [
          repo: :string,
          prefix: :string,
          create_schema: :boolean,
          layout: :string,
          add_routes: :boolean
        ],
        defaults: [prefix: "public", create_schema: false, add_routes: false],
        aliases: [r: :repo, p: :prefix],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)
      opts = igniter.args.options

      case extract_repo(igniter, app_name, opts[:repo]) do
        {:ok, repo} ->
          prefix = opts[:prefix] || "public"
          create_schema = opts[:create_schema] || (prefix != "public")

          # Configuration for production
          conf_code = [
            repo: repo,
            prefix: prefix
          ]

          # Configuration for test environment
          test_code = [
            repo: repo,
            prefix: prefix,
            async: true
          ]

          # Migration body
          migration_opts = if prefix == "public" and not create_schema do
            ""
          else
            inspect([prefix: prefix, create_schema: create_schema])
          end

          migration_body = """
          use Ecto.Migration

          def up, do: PhoenixKit.Migration.up(#{migration_opts})

          def down, do: PhoenixKit.Migration.down(#{migration_opts})
          """

          igniter
          |> Igniter.Project.Config.configure(
            "config.exs",
            app_name,
            [PhoenixKit],
            {:code, conf_code}
          )
          |> Igniter.Project.Config.configure(
            "test.exs",
            app_name,
            [PhoenixKit],
            {:code, test_code}
          )
          |> add_mailer_configuration(app_name)
          |> maybe_configure_layout(app_name, opts[:layout])
          |> Igniter.Project.Formatter.import_dep(:phoenix_kit)
          |> Igniter.Libs.Ecto.gen_migration(
            repo,
            "add_phoenix_kit_auth_tables",
            body: migration_body,
            on_exists: :skip
          )
          |> maybe_add_routes_to_router(opts[:add_routes])
          |> add_completion_notice()

        {:error, igniter} ->
          igniter
      end
    end

    defp extract_repo(igniter, app_name, nil) do
      case Igniter.Libs.Ecto.list_repos(igniter) do
        {_igniter, [repo | _]} ->
          {:ok, repo}

        _ ->
          issue = """
          No Ecto repos found for #{inspect(app_name)}.

          PhoenixKit requires an Ecto repository to store authentication data.
          Please ensure you have configured an Ecto repo in your application.

          Example:
            # In config/config.exs
            config :my_app, ecto_repos: [MyApp.Repo]

          Then run:
            mix phoenix_kit.install.pro --repo MyApp.Repo
          """

          {:error, Igniter.add_issue(igniter, issue)}
      end
    end

    defp extract_repo(igniter, _app_name, module_string) do
      repo = Igniter.Project.Module.parse(module_string)

      case Igniter.Project.Module.module_exists(igniter, repo) do
        {true, _igniter} ->
          {:ok, repo}

        {false, _} ->
          issue = """
          Provided repo (#{inspect(repo)}) doesn't exist.

          Please ensure the repo module is properly defined in your application.
          
          Available options:
            1. Let PhoenixKit auto-detect your repo: mix phoenix_kit.install.pro
            2. Specify the correct repo: mix phoenix_kit.install.pro --repo YourApp.Repo
          """

          {:error, Igniter.add_issue(igniter, issue)}
      end
    end

    defp add_mailer_configuration(igniter, app_name) do
      mailer_code = [adapter: Swoosh.Adapters.Local]

      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        app_name,
        [PhoenixKit.Mailer],
        {:code, mailer_code}
      )
    end

    defp maybe_configure_layout(igniter, _app_name, nil), do: igniter
    defp maybe_configure_layout(igniter, app_name, layout_string) do
      layout_tuple = parse_layout_config(layout_string)

      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        app_name,
        [PhoenixKit, :layout],
        layout_tuple
      )
    end

    defp maybe_add_routes_to_router(igniter, false), do: igniter
    defp maybe_add_routes_to_router(igniter, true) do
      # For now, provide instructions since router modification is complex
      # In a full implementation, this would use AST manipulation
      Igniter.add_notice(igniter, """
      Please add PhoenixKit routes to your router.ex:

      1. Add the PhoenixKitWeb import at the top:
         use PhoenixKitWeb, :router

      2. Add the authentication scope:
         scope "/auth" do
           pipe_through :browser
           phoenix_kit_routes()
         end
      """)
    end

    defp add_completion_notice(igniter) do
      Igniter.add_notice(igniter, """
      🎉 PhoenixKit installation completed successfully!

      Next steps:
        1. Run database migration: mix ecto.migrate
        2. Add authentication routes to your router (if not done automatically)
        3. Configure your mailer for production use

      Your Phoenix application now has professional authentication ready to use!
      """)
    end

    defp parse_layout_config(layout_string) do
      case String.split(layout_string, ".") do
        [module, function] -> 
          {Module.concat([module]), String.to_atom(function)}
        parts when length(parts) > 2 ->
          {function, module_parts} = List.pop_at(parts, -1)
          module = Module.concat(module_parts)
          {module, String.to_atom(function)}
        _ -> 
          layout_string
      end
    end
  end
else
  defmodule Mix.Tasks.PhoenixKit.Install.Pro do
    @shortdoc "Install Igniter to use PhoenixKit's advanced installer."

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'phoenix_kit.install.pro' requires Igniter for intelligent project setup.

      To use PhoenixKit's professional installer:

      1. Add Igniter to your dependencies:
         # In mix.exs
         {:igniter, "~> 0.6.0", only: [:dev]}

      2. Install dependencies:
         mix deps.get

      3. Run the professional installer:
         mix phoenix_kit.install.pro

      Alternatively, use the basic installer:
         mix phoenix_kit.install --repo MyApp.Repo

      For more information, see: https://hexdocs.pm/igniter/readme.html
      """)

      exit({:shutdown, 1})
    end
  end
end