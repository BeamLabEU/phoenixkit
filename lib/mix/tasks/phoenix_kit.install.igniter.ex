if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.PhoenixKit.Install.Igniter do
    @moduledoc """
    Install PhoenixKit using Igniter for intelligent project patching.

    This is meant to be called from within a Phoenix application that already
    has PhoenixKit as a dependency via Git or local path.

    ## Usage

    Add PhoenixKit to your deps first:

    ```elixir
    # In mix.exs
    defp deps do
      [
        {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"},
        {:igniter, "~> 0.6.0", only: [:dev]}
      ]
    end
    ```

    Then run:

    ```bash
    mix deps.get
    mix phoenix_kit.install.igniter
    ```

    ## Options

    * `--prefix` or `-p` — PostgreSQL schema prefix (default: "public")
    * `--create-schema` — Create schema if using custom prefix (default: true for non-public)
    * `--repo` — Specify the Ecto repo module (will attempt to auto-detect)
    * `--add-routes` — Add authentication routes to router.ex (default: prompt user)
    * `--layout` — Configure custom layout integration
    """

    @shortdoc "Install PhoenixKit using Igniter for intelligent project setup"

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # This task adds files, modifies configuration, and potentially modifies router
        adds_deps: [],
        composes: [],
        example: "mix phoenix_kit.install.igniter --prefix auth",
        extra_args?: true,
        only: nil,
        positional: [],
        schema: [
          prefix: :string,
          create_schema: :boolean,
          repo: :string,
          add_routes: :boolean,
          layout: :string,
          yes: :boolean
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = parse_options(igniter.args.argv)

      igniter
      |> ensure_phoenix_kit_in_deps()
      |> detect_repo(options)
      |> add_phoenix_kit_configuration(options)
      |> create_phoenix_kit_migration(options)
      |> maybe_add_routes_to_router(options)
      |> maybe_configure_layout(options)
      |> add_mailer_configuration()
      |> validate_installation()
    end

    defp parse_options(argv) do
      {opts, _} = OptionParser.parse!(argv,
        strict: [
          prefix: :string,
          create_schema: :boolean,
          repo: :string,
          add_routes: :boolean,
          layout: :string,
          interactive: :boolean,
          yes: :boolean
        ],
        aliases: [p: :prefix, r: :repo, i: :interactive]
      )

      opts
      |> Keyword.put_new(:prefix, "public")
      |> Keyword.put_new(:create_schema, opts[:prefix] != "public")
      |> Keyword.put_new(:interactive, true)
    end

    defp ensure_phoenix_kit_in_deps(igniter) do
      # Check if phoenix_kit is already in deps
      case Igniter.Project.Deps.get_dep(igniter, :phoenix_kit) do
        {:ok, _} -> 
          igniter
        :error ->
          # Add phoenix_kit dependency (this handles both hex and git scenarios)
          Igniter.Project.Deps.add_dep(igniter, {:phoenix_kit, git: "https://github.com/BeamLabEU/phoenixkit.git"})
      end
    end

    defp detect_repo(igniter, options) do
      case options[:repo] do
        nil -> 
          case auto_detect_repo(igniter) do
            {:ok, repo} -> 
              Igniter.assign(igniter, :detected_repo, repo)
            :error ->
              # Try to get from user input or fail gracefully
              require_repo_configuration(igniter, options)
          end
        repo_string ->
          repo_module = Module.concat([repo_string])
          Igniter.assign(igniter, :detected_repo, repo_module)
      end
    end

    defp auto_detect_repo(igniter) do
      case Igniter.Project.Application.app_name(igniter) do
        {:ok, app_name} ->
          app_module = Macro.camelize(to_string(app_name))
          potential_repos = [
            Module.concat([app_module, "Repo"]),
            Module.concat([app_module <> "Web", "Repo"])
          ]

          # Check if any exist by looking at config files
          Enum.find_value(potential_repos, :error, fn repo ->
            if repo_exists_in_config?(igniter, repo), do: {:ok, repo}, else: nil
          end)
        _error -> 
          :error
      end
    end

    defp repo_exists_in_config?(_igniter, _repo) do
      # This would need to scan config files for the repo module
      # Simplified implementation - in real use this would scan config files
      true
    end

    defp require_repo_configuration(igniter, options) do
      if options[:interactive] do
        # In a real implementation, this would prompt the user
        # For now, we'll use a common default
        case Igniter.Project.Application.app_name(igniter) do
          {:ok, app_name} ->
            repo = Module.concat([Macro.camelize(to_string(app_name)), "Repo"])
            Igniter.assign(igniter, :detected_repo, repo)
          _error ->
            Igniter.add_issue(igniter, """
            Could not determine application name. Please specify with --repo option:
            
            mix phoenix_kit.install.igniter --repo MyApp.Repo
            """)
        end
      else
        # Fail with helpful error
        Igniter.add_issue(igniter, """
        Could not auto-detect repository module. Please specify with --repo option:
        
        mix phoenix_kit.install.igniter --repo MyApp.Repo
        """)
      end
    end

    defp add_phoenix_kit_configuration(igniter, options) do
      repo = igniter.assigns[:detected_repo]
      
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :phoenix_kit,
        [:repo],
        repo
      )
      |> maybe_configure_prefix(options[:prefix])
    end

    defp maybe_configure_prefix(igniter, "public"), do: igniter
    defp maybe_configure_prefix(igniter, prefix) when is_binary(prefix) do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :phoenix_kit,
        [:prefix],
        prefix
      )
    end

    defp create_phoenix_kit_migration(igniter, options) do
      timestamp = generate_timestamp()
      migration_name = "add_phoenix_kit_auth_tables"
      migration_file = "#{timestamp}_#{migration_name}.exs"

      # Try different ways to get app name
      app_name = case Igniter.Project.Application.app_name(igniter) do
        {:ok, name} -> name
        name when is_atom(name) -> name
        _ ->
          # Fallback: try to get from Mix.Project
          Mix.Project.config()[:app]
      end

      if app_name do
        app_module = Macro.camelize(to_string(app_name))
        module_name = "#{app_module}.Repo.Migrations.#{Macro.camelize(migration_name)}"
        
        migration_opts = format_migration_options(options[:prefix], options[:create_schema])

        migration_content = """
        defmodule #{module_name} do
          use Ecto.Migration

          def up, do: PhoenixKit.Migration.up(#{migration_opts})

          def down, do: PhoenixKit.Migration.down(#{migration_opts})
        end
        """

        migration_path = Path.join(["priv", "repo", "migrations", migration_file])

        Igniter.create_new_file(igniter, migration_path, migration_content)
      else
        Igniter.add_issue(igniter, """
        Could not determine application name for migration creation.
        Please ensure you're running this from a Phoenix application root.
        App name result: #{inspect(Igniter.Project.Application.app_name(igniter))}
        """)
      end
    end

    defp maybe_add_routes_to_router(igniter, options) do
      case options[:add_routes] do
        true -> add_phoenix_kit_routes(igniter)
        false -> igniter
        nil -> 
          # Interactive mode - would prompt user in real implementation
          if options[:interactive] do
            add_phoenix_kit_routes(igniter)
          else
            igniter
          end
      end
    end

    defp add_phoenix_kit_routes(igniter) do
      # Find the router module and add PhoenixKit routes
      case find_router_module(igniter) do
        {:ok, router_module} ->
          add_routes_to_router_module(igniter, router_module)
        :error ->
          Igniter.add_notice(igniter, """
          Could not automatically add routes to router. Please add manually:
          
          # In your router.ex
          use PhoenixKitWeb, :router
          
          scope "/auth" do
            pipe_through :browser
            phoenix_kit_routes()
          end
          """)
      end
    end

    defp find_router_module(igniter) do
      case Igniter.Project.Application.app_name(igniter) do
        {:ok, app_name} ->
          app_web = Macro.camelize(to_string(app_name)) <> "Web"
          router_module = Module.concat([app_web, "Router"])
          
          # Check if the router module exists using Igniter's module checking
          if Igniter.Project.Module.module_exists(igniter, router_module) do
            {:ok, router_module}
          else
            :error
          end
        _error ->
          :error
      end
    end

    defp add_routes_to_router_module(igniter, router_module) do
      # For now, provide clear instructions since router modification is complex
      # In a full implementation, this would use Igniter's AST manipulation
      Igniter.add_notice(igniter, """
      PhoenixKit routes need to be added to #{inspect(router_module)}.
      
      Add these lines to your router file:
      
      # At the top with other use statements:
      use PhoenixKitWeb, :router
      
      # Add this scope where you want auth routes:
      scope "/auth" do
        pipe_through :browser
        phoenix_kit_routes()
      end
      """)
    end

    defp maybe_configure_layout(igniter, options) do
      case options[:layout] do
        nil -> igniter
        layout_config ->
          layout_tuple = parse_layout_config(layout_config)
          
          Igniter.Project.Config.configure(
            igniter,
            "config.exs",
            :phoenix_kit,
            [:layout],
            layout_tuple
          )
      end
    end

    defp add_mailer_configuration(igniter) do
      Igniter.Project.Config.configure(
        igniter,
        "config.exs",
        :phoenix_kit,
        [PhoenixKit.Mailer, :adapter],
        Swoosh.Adapters.Local
      )
    end

    defp validate_installation(igniter) do
      # Add final validation and helpful messages
      Igniter.add_notice(igniter, """
      PhoenixKit installation completed! Next steps:
      
      1. Run: mix ecto.migrate
      2. Add authentication routes to your router (if not done automatically)
      3. Configure your mailer for production use
      
      See documentation for full setup instructions.
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

    defp format_migration_options("public", false), do: ""
    defp format_migration_options(prefix, create_schema) when is_binary(prefix) do
      opts = [prefix: prefix]
      opts = if create_schema, do: Keyword.put(opts, :create_schema, true), else: opts
      inspect(opts)
    end

    defp generate_timestamp do
      {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
      "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    end

    defp pad(i) when i < 10, do: <<?0, ?0 + i>>
    defp pad(i), do: to_string(i)
  end
else
  defmodule Mix.Tasks.PhoenixKit.Install.Igniter do
    @moduledoc """
    Igniter is not available. Please add {:igniter, "~> 0.6.0"} to your dependencies.
    """
    use Mix.Task

    @shortdoc "Install PhoenixKit using Igniter (requires Igniter dependency)"

    def run(_args) do
      Mix.shell().error("""
      Igniter is not available. To use Igniter-based installation:
      
      1. Add Igniter to your dependencies in mix.exs:
         {:igniter, "~> 0.6.0", only: [:dev]}
      
      2. Run: mix deps.get
      
      3. Then run: mix phoenix_kit.install.igniter
      
      Alternatively, use the traditional installer:
         mix phoenix_kit.install --repo MyApp.Repo
      """)
    end
  end
end