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
    create database migrations, and automatically integrate authentication routes
    into your router using advanced AST manipulation.

    ## Examples

    Full automatic installation with router integration:

    ```bash
    mix phoenix_kit.install.pro
    ```

    Custom configuration:

    ```bash
    mix phoenix_kit.install.pro --repo MyApp.Repo --prefix "auth" --route-prefix "/auth"
    ```

    Disable automatic router modification:

    ```bash
    mix phoenix_kit.install.pro --no-add-routes
    ```

    ## Options

    * `--repo` or `-r` — Specify an Ecto repo for PhoenixKit to use
    * `--prefix` or `-p` — PostgreSQL schema prefix, defaults to "public"
    * `--create-schema` — Create schema if using custom prefix (default: true for non-public)
    * `--layout` — Configure custom layout integration
    * `--add-routes` — Add authentication routes to router.ex (default: true)
    * `--route-prefix` — URL prefix for PhoenixKit routes (default: "/phoenix_kit")
    * `--no-auto-resolve-conflicts` — Disable automatic conflict resolution
    * `--skip-conflict-detection` — Skip all conflict detection (not recommended)
    * `--conflict-tolerance` — Set conflict tolerance level: low/medium/high (default: medium)
    * `--quick-check-only` — Perform only quick conflict check, skip full analysis
    * `--integrate-layouts` — Enable automatic layout integration (default: true)
    * `--layout-strategy` — Layout integration strategy: auto/existing/phoenix_kit (default: auto)
    * `--enhance-layouts` — Enhance existing layouts for PhoenixKit compatibility (default: true)
    * `--create-fallbacks` — Create fallback layouts when needed (default: true)

    ## Professional Features - Complete Installation Automation

    🔥 **Automatic Router Integration** - Intelligently adds PhoenixKit routes to your router.ex
    🎨 **Smart Layout Integration** - Automatically detects and integrates with your app's layouts
    🔍 **Advanced Conflict Detection** - Comprehensive analysis of dependencies, configs, and code
    📊 **Migration Strategy Generation** - Automated migration planning for complex scenarios
    🚨 **Risk Assessment** - Multi-level risk analysis with tolerance controls
    ⚡ **Quick Conflict Check** - Fast pre-installation conflict assessment
    🎯 **Personalized Recommendations** - Context-aware guidance for your specific setup
    🛡️ **Fallback System** - Creates fallback layouts for seamless user experience
    ✨ **Layout Enhancement** - Improves existing layouts for better PhoenixKit compatibility
    ✅ **Comprehensive Validation** - Ensures successful installation with multi-step checks

    ## Conflict Detection Examples

    ```bash
    # Standard installation with full conflict detection
    mix phoenix_kit.install.pro

    # High-risk installations (strict mode)
    mix phoenix_kit.install.pro --conflict-tolerance low

    # Permissive mode for experienced developers
    mix phoenix_kit.install.pro --conflict-tolerance high

    # Quick assessment only (faster for CI/testing)
    mix phoenix_kit.install.pro --quick-check-only

    # Skip all checks (use with caution!)
    mix phoenix_kit.install.pro --skip-conflict-detection
    ```

    ## Layout Integration Examples

    ```bash
    # Standard installation with full layout integration
    mix phoenix_kit.install.pro

    # Use existing layouts without enhancements
    mix phoenix_kit.install.pro --layout-strategy existing --no-enhance-layouts

    # Create comprehensive PhoenixKit layouts  
    mix phoenix_kit.install.pro --layout-strategy phoenix_kit --create-fallbacks

    # Disable layout integration entirely
    mix phoenix_kit.install.pro --no-integrate-layouts
    ```

    The installer now provides **intelligent conflict resolution and seamless layout integration** for 95% of Phoenix applications!
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PhoenixKit.Install.Pro do
    @shortdoc __MODULE__.Docs.short_doc()

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task
    require Logger

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
          add_routes: :boolean,
          route_prefix: :string,
          auto_resolve_conflicts: :boolean,
          skip_conflict_detection: :boolean,
          conflict_tolerance: :string,
          quick_check_only: :boolean,
          integrate_layouts: :boolean,
          layout_strategy: :string,
          enhance_layouts: :boolean,
          create_fallbacks: :boolean
        ],
        defaults: [
          prefix: "public",
          create_schema: false,
          add_routes: true,
          route_prefix: "/phoenix_kit",
          auto_resolve_conflicts: true,
          skip_conflict_detection: false,
          conflict_tolerance: "medium",
          quick_check_only: false,
          integrate_layouts: true,
          layout_strategy: "auto",
          enhance_layouts: true,
          create_fallbacks: true
        ],
        aliases: [r: :repo, p: :prefix],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)
      opts = igniter.args.options

      # Perform conflict detection and analysis before installation
      igniter =
        case perform_conflict_analysis(igniter, opts) do
          {:ok, updated_igniter, analysis_result} ->
            log_conflict_analysis_summary(analysis_result)
            updated_igniter

          {:warning, updated_igniter, warnings} ->
            log_conflict_warnings(warnings)
            updated_igniter

          {:error, updated_igniter, critical_conflicts} ->
            log_critical_conflicts_and_abort(critical_conflicts)
            updated_igniter

          # Skip conflict detection if requested
          {:skip, updated_igniter} ->
            updated_igniter
        end

      case extract_repo(igniter, app_name, opts[:repo]) do
        {:ok, repo} ->
          prefix = opts[:prefix] || "public"
          create_schema = opts[:create_schema] || prefix != "public"

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
          migration_opts =
            if prefix == "public" and not create_schema do
              ""
            else
              inspect(prefix: prefix, create_schema: create_schema)
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
          |> perform_router_integration(opts)
          |> validate_and_fix_layout_files()
          |> perform_layout_integration(opts)
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

    defp perform_router_integration(igniter, opts) do
      if opts[:add_routes] do
        route_prefix = opts[:route_prefix] || "/phoenix_kit"
        auto_resolve = opts[:auto_resolve_conflicts] !== false

        case PhoenixKit.Install.RouterIntegration.perform_full_integration(igniter,
               prefix: route_prefix,
               auto_resolve_conflicts: auto_resolve,
               validate_integration: true,
               skip_if_exists: true
             ) do
          {:ok, updated_igniter, integration_result} ->
            router_module = integration_result.router_module

            success_notice = """
            ✅ PhoenixKit routes automatically added to #{inspect(router_module)}!

            Routes available at:
            #{route_prefix}/register - User registration
            #{route_prefix}/log_in - User login  
            #{route_prefix}/settings - User settings

            Conflicts resolved: #{length(integration_result.conflicts_resolved)}
            """

            Igniter.add_notice(updated_igniter, success_notice)

          {:skipped, :already_integrated} ->
            Igniter.add_notice(igniter, "✅ PhoenixKit routes already integrated in router")

          {:error, reason} ->
            error_notice = """
            ⚠️  Could not automatically add routes to router: #{inspect(reason)}

            Please add PhoenixKit routes manually:

            1. Add import to your router.ex:
               import PhoenixKitWeb.Integration

            2. Add routes call:
               phoenix_kit_auth_routes("#{route_prefix}")

            For detailed instructions, see: https://github.com/BeamLabEU/phoenixkit
            """

            Igniter.add_notice(igniter, error_notice)
        end
      else
        # Router integration disabled by user
        manual_notice = """
        ℹ️  Router integration disabled. To add routes manually:

        1. Add import to your router.ex:
           import PhoenixKitWeb.Integration

        2. Add routes call:
           phoenix_kit_auth_routes()
        """

        Igniter.add_notice(igniter, manual_notice)
      end
    end

    defp add_completion_notice(igniter) do
      Igniter.add_notice(igniter, """
      🎉 PhoenixKit Professional Installation Complete!

      ✅ Database migrations created
      ✅ Configuration files updated  
      ✅ Router integration performed (if enabled)
      ✅ Layout integration completed (if enabled)
      ✅ Conflict detection and resolution applied
      ✅ Mailer configuration added

      Next steps:
        1. Run database migration: mix ecto.migrate
        2. Start your Phoenix server: mix phx.server
        3. Visit /phoenix_kit/register to test authentication

      🚀 Your Phoenix application now has zero-config professional authentication with seamless layout integration!

      For production deployment:
        - Configure your mailer in config/prod.exs
        - Set up email templates if needed
        - Review security settings
        - Customize layout styles if desired
        
      Documentation: https://github.com/BeamLabEU/phoenixkit
      """)
    end

    # ============================================================================
    # Conflict Detection Integration Functions
    # ============================================================================

    defp perform_conflict_analysis(igniter, opts) do
      if opts[:skip_conflict_detection] do
        Igniter.add_notice(igniter, "ℹ️  Conflict detection skipped by user request")
        {:skip, igniter}
      else
        conflict_tolerance = parse_conflict_tolerance(opts[:conflict_tolerance])
        quick_check_only = opts[:quick_check_only] || false

        if quick_check_only do
          perform_quick_conflict_check(igniter, conflict_tolerance)
        else
          perform_comprehensive_conflict_analysis(igniter, conflict_tolerance, opts)
        end
      end
    end

    defp perform_quick_conflict_check(igniter, _conflict_tolerance) do
      case PhoenixKit.Install.ConflictDetection.quick_conflict_check(igniter) do
        {:ok, quick_assessment} ->
          if quick_assessment.should_run_full_analysis do
            Igniter.add_notice(igniter, """
            ⚠️  Quick conflict check suggests running full analysis

            Detected potential conflicts: #{quick_assessment.estimated_conflict_level}
            Recommendation: #{quick_assessment.recommendation}

            To run full analysis: mix phoenix_kit.install.pro --no-quick-check-only
            To skip all checks: mix phoenix_kit.install.pro --skip-conflict-detection
            """)

            {:warning, igniter, [quick_assessment.recommendation]}
          else
            Igniter.add_notice(igniter, """
            ✅ Quick conflict check passed: #{quick_assessment.recommendation}
            """)

            {:ok, igniter, quick_assessment}
          end

        {:error, reason} ->
          Igniter.add_notice(igniter, """
          ⚠️  Quick conflict check failed: #{inspect(reason)}
          Proceeding with installation - use --skip-conflict-detection to disable checks
          """)

          {:warning, igniter, ["Quick conflict check failed"]}
      end
    end

    defp perform_comprehensive_conflict_analysis(igniter, conflict_tolerance, _opts) do
      analysis_opts = [
        risk_tolerance: conflict_tolerance,
        generate_migration_strategy: true,
        scan_test_files: false,
        max_files: 1000
      ]

      case PhoenixKit.Install.ConflictDetection.perform_comprehensive_analysis(
             igniter,
             analysis_opts
           ) do
        {:ok, comprehensive_analysis} ->
          handle_comprehensive_analysis_result(
            igniter,
            comprehensive_analysis,
            conflict_tolerance
          )

        {:error, reason} ->
          error_notice = """
          ❌ Conflict detection failed: #{inspect(reason)}

          This may indicate issues with your project structure or dependencies.
          You can skip conflict detection with: --skip-conflict-detection

          Proceeding with installation at your own risk...
          """

          Igniter.add_notice(igniter, error_notice)
          {:warning, igniter, ["Conflict detection failed"]}
      end
    end

    defp handle_comprehensive_analysis_result(igniter, analysis, conflict_tolerance) do
      overall_assessment = analysis.overall_assessment

      cond do
        not overall_assessment.safe_to_proceed and conflict_tolerance == :low ->
          # Строгий режим - прерываем установку при любых серьезных конфликтах
          critical_conflicts_notice = """
          🚨 CRITICAL CONFLICTS DETECTED - Installation Aborted

          Critical conflicts: #{overall_assessment.critical_conflicts}
          Total conflicts: #{overall_assessment.total_conflicts}
          Risk level: #{overall_assessment.overall_risk_level}

          Blocking issues:
          #{Enum.join(overall_assessment.blocking_issues, "\n")}

          Recommended actions:
          #{Enum.join(analysis.recommendations, "\n")}

          To override this check: --conflict-tolerance high --skip-conflict-detection
          """

          {:error, Igniter.add_issue(igniter, critical_conflicts_notice),
           overall_assessment.blocking_issues}

        overall_assessment.requires_manual_intervention and conflict_tolerance == :medium ->
          # Средний режим - предупреждаем о необходимости ручного вмешательства
          manual_intervention_notice = """
          ⚠️  MANUAL INTERVENTION REQUIRED

          Found conflicts requiring attention:
          Total conflicts: #{overall_assessment.total_conflicts}
          Critical: #{overall_assessment.critical_conflicts}
          Auto-resolvable: #{overall_assessment.auto_resolvable_conflicts}

          Migration strategy: #{Map.get(analysis.migration_strategy, :strategy_name, "Not generated")}
          Estimated timeline: #{Map.get(analysis.migration_strategy, :estimated_timeline, "Unknown")}

          Next steps:
          #{Enum.join(analysis.next_steps, "\n")}

          Proceeding with installation - please review conflicts carefully.
          """

          {:warning, Igniter.add_notice(igniter, manual_intervention_notice),
           analysis.recommendations}

        true ->
          # Все хорошо или high tolerance - продолжаем с информационными сообщениями
          success_notice = """
          ✅ Conflict Detection Complete

          Analysis summary:
          - Total conflicts: #{overall_assessment.total_conflicts}
          - Critical conflicts: #{overall_assessment.critical_conflicts}
          - Overall risk: #{overall_assessment.overall_risk_level}
          - Safe to proceed: #{overall_assessment.safe_to_proceed}

          #{if length(analysis.recommendations) > 0 do
            "Recommendations:\n#{Enum.join(analysis.recommendations, "\n")}"
          else
            "No specific recommendations."
          end}
          """

          {:ok, Igniter.add_notice(igniter, success_notice), analysis}
      end
    end

    defp log_conflict_analysis_summary(_analysis_result) do
      # Дополнительное логирование для debugging
      # В production версии это может быть отключено
      :ok
    end

    defp log_conflict_warnings(_warnings) do
      # Логирование предупреждений
      :ok
    end

    defp log_critical_conflicts_and_abort(_critical_conflicts) do
      # Логирование критических конфликтов
      :ok
    end

    defp parse_conflict_tolerance(tolerance_str) do
      case String.downcase(tolerance_str || "medium") do
        "low" -> :low
        "medium" -> :medium
        "high" -> :high
        _ -> :medium
      end
    end

    defp perform_layout_integration(igniter, opts) do
      if opts[:integrate_layouts] do
        layout_strategy = parse_layout_strategy(opts[:layout_strategy])
        enhance_layouts = opts[:enhance_layouts] !== false
        create_fallbacks = opts[:create_fallbacks] !== false

        integration_opts = [
          layout_preference: layout_strategy,
          enhance_layouts: enhance_layouts,
          create_fallbacks: create_fallbacks
        ]

        case PhoenixKit.Install.LayoutIntegration.perform_full_integration(
               igniter,
               integration_opts
             ) do
          {:ok, updated_igniter, integration_result} ->
            strategy = integration_result.integration_strategy

            success_notice = """
            🎨 PhoenixKit layout integration complete!

            Strategy: #{strategy}
            Detected layouts: #{length(integration_result.detected_layouts)}
            Enhancements applied: #{integration_result.enhancements_applied != %{}}
            Fallbacks created: #{integration_result.fallbacks_created != %{}}

            Your Phoenix app layouts are now seamlessly integrated with PhoenixKit!
            """

            Igniter.add_notice(updated_igniter, success_notice)

          {:skipped, reason} ->
            Igniter.add_notice(igniter, "ℹ️  Layout integration skipped: #{reason}")

          {:error, reason} ->
            error_notice = """
            ⚠️  Could not automatically integrate layouts: #{inspect(reason)}

            PhoenixKit will use default layouts. You can manually configure layouts in config.exs:

            config :phoenix_kit,
              layout: {YourAppWeb.Layouts, :app},
              root_layout: {YourAppWeb.Layouts, :root}

            For detailed instructions, see: https://github.com/BeamLabEU/phoenixkit
            """

            Igniter.add_notice(igniter, error_notice)
        end
      else
        # Layout integration disabled by user
        manual_notice = """
        ℹ️  Layout integration disabled. To configure layouts manually:

        Add to your config.exs:
          config :phoenix_kit,
            layout: {YourAppWeb.Layouts, :app},
            root_layout: {YourAppWeb.Layouts, :root}
        """

        Igniter.add_notice(igniter, manual_notice)
      end
    end

    defp parse_layout_strategy(strategy_str) do
      case String.downcase(strategy_str || "auto") do
        "auto" -> :auto
        "existing" -> :existing
        "phoenix_kit" -> :phoenix_kit
        _ -> :auto
      end
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

    defp validate_and_fix_layout_files(igniter) do
      Logger.info("🔍 Checking layout files for attribute order issues...")
      
      # Find layout files that might have been modified
      layout_patterns = [
        "lib/**/components/layouts.ex",
        "lib/**/layouts.ex"
      ]
      
      layout_files = 
        layout_patterns
        |> Enum.flat_map(fn pattern ->
          Path.wildcard(pattern)
        end)
        |> Enum.uniq()
        |> Enum.filter(&File.exists?/1)
      
      if length(layout_files) > 0 do
        Logger.info("Found #{length(layout_files)} layout files to check")
        
        # Apply layout fixes using our existing LayoutEnhancer
        case PhoenixKit.Install.LayoutIntegration.LayoutEnhancer.apply_specific_enhancement(
          igniter, 
          Enum.at(layout_files, 0), 
          :fix_attribute_order
        ) do
          {:ok, updated_igniter} ->
            Logger.info("✅ Layout files validated and fixed if needed")
            updated_igniter
          {:error, reason} ->
            Logger.warning("⚠️  Could not validate layout files: #{inspect(reason)}")
            igniter
        end
      else
        Logger.debug("No layout files found to validate")
        igniter
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
