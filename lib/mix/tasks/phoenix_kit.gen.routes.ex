defmodule Mix.Tasks.PhoenixKit.Gen.Routes do
  @shortdoc "Generates PhoenixKit authentication routes in your router"

  @moduledoc """
  Generates PhoenixKit authentication routes in your Phoenix router.

  This task automatically injects the necessary authentication routes
  and plugs into your existing router.ex file.

  ## Examples

      $ mix phoenix_kit.gen.routes
      $ mix phoenix_kit.gen.routes --scope-prefix auth  
      $ mix phoenix_kit.gen.routes --dry-run

  ## Options

    * `--scope-prefix` - The prefix for authentication routes (default: "auth")
    * `--dry-run` - Show what would be generated without modifying files
    * `--force` - Overwrite existing route configuration without prompting

  The generated routes include:
  
    * Registration routes (GET/POST /register)
    * Session routes (GET/POST /log-in, DELETE /log-out)  
    * Magic link confirmation (GET /log-in/:token)
    * Settings routes (GET/PUT /settings)

  This task will also add the necessary authentication plugs to your browser pipeline.
  """

  use Mix.Task

  @switches [
    scope_prefix: :string,
    dry_run: :boolean,
    force: :boolean
  ]

  @default_options [
    scope_prefix: "auth",
    dry_run: false,
    force: false
  ]

  @impl Mix.Task
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phoenix_kit.gen.routes must be invoked from within your *_web application root directory")
    end

    options = parse_options(args)
    
    ensure_phoenix_project!()
    
    router_file = find_router_file()
    
    if options[:dry_run] do
      show_dry_run(router_file, options)
    else
      inject_routes(router_file, options)
    end
  end

  defp parse_options(args) do
    {options, _} = OptionParser.parse!(args, switches: @switches)
    Keyword.merge(@default_options, options)
  end

  defp ensure_phoenix_project! do
    unless phoenix_project?() do
      Mix.raise("""
      This task can only be run within a Phoenix application.
      
      Make sure you're in the root directory of a Phoenix project.
      """)
    end
  end

  defp find_router_file do
    app_name = Mix.Phoenix.otp_app() |> to_string() |> Macro.camelize()
    potential_paths = [
      "lib/#{Mix.Phoenix.otp_app()}_web/router.ex",
      "lib/#{app_name}Web/router.ex",
      "lib/#{app_name}_web/router.ex"
    ]
    
    router_file = Enum.find(potential_paths, &File.exists?/1)
    
    unless router_file do
      Mix.raise("""
      Could not find router.ex file.
      
      Expected to find it at one of:
      #{Enum.map(potential_paths, &("  - #{&1}")) |> Enum.join("\n")}
      
      Please ensure you're in a Phoenix project root directory.
      """)
    end
    
    router_file
  end

  defp show_dry_run(router_file, options) do
    Mix.shell().info("#{IO.ANSI.yellow()}Dry run mode - no files will be modified#{IO.ANSI.reset()}")
    Mix.shell().info("Would modify: #{router_file}")
    Mix.shell().info("")
    
    router_content = generate_route_injection(options)
    
    Mix.shell().info("#{IO.ANSI.cyan()}Routes to be added:#{IO.ANSI.reset()}")
    Mix.shell().info(router_content)
  end

  defp inject_routes(router_file, options) do
    content = File.read!(router_file)
    
    # Check if PhoenixKit routes already exist
    if String.contains?(content, "BeamLab.PhoenixKitWeb") do
      if options[:force] or Mix.shell().yes?("PhoenixKit routes already exist. Replace them?") do
        update_existing_routes(router_file, content, options)
      else
        Mix.shell().info("Skipping route injection.")
      end
    else
      inject_new_routes(router_file, content, options)
    end
  end

  defp inject_new_routes(router_file, content, options) do
    # First, add the import if it doesn't exist
    updated_content = add_user_auth_import(content)
    
    # Add plug to browser pipeline
    updated_content = add_browser_plug(updated_content)
    
    # Add route scopes
    updated_content = add_route_scopes(updated_content, options)
    
    File.write!(router_file, updated_content)
    
    Mix.shell().info("""
    
    #{IO.ANSI.green()}✓ PhoenixKit routes added successfully!#{IO.ANSI.reset()}
    
    Modified: #{router_file}
    
    Added routes:
    - Registration: GET/POST /#{options[:scope_prefix]}/register
    - Login: GET/POST /#{options[:scope_prefix]}/log-in
    - Magic link: GET /#{options[:scope_prefix]}/log-in/:token
    - Settings: GET/PUT /#{options[:scope_prefix]}/settings
    - Logout: DELETE /#{options[:scope_prefix]}/log-out
    """)
  end

  defp update_existing_routes(router_file, content, options) do
    # Remove existing PhoenixKit routes and re-inject them
    cleaned_content = remove_existing_phoenix_kit_routes(content)
    inject_new_routes(router_file, cleaned_content, options)
  end

  defp add_user_auth_import(content) do
    if String.contains?(content, "import BeamLab.PhoenixKitWeb.UserAuth") do
      content
    else
      # Find the router module definition and add import after it
      String.replace(content, ~r/(defmodule\s+\w+\.Router\s+do\s*\n\s*use\s+\w+,\s*:router)/, 
        "\\1\n\n  import BeamLab.PhoenixKitWeb.UserAuth")
    end
  end

  defp add_browser_plug(content) do
    if String.contains?(content, "plug :fetch_current_scope_for_user") do
      content
    else
      # Add the plug to the browser pipeline
      String.replace(content, ~r/(pipeline\s+:browser\s+do.*?plug\s+:put_secure_browser_headers)/s,
        "\\1\n    plug :fetch_current_scope_for_user")
    end
  end

  defp add_route_scopes(content, options) do
    route_scopes = generate_route_injection(options)
    
    # Find a good place to inject routes (usually after existing scopes)
    if String.contains?(content, "scope \"/\"") do
      # Insert after the first scope
      String.replace(content, ~r/(scope\s+"\/",.*?end)/s, "\\1\n\n#{route_scopes}", global: false)
    else
      # Insert before the final 'end' of the module
      String.replace(content, ~r/\nend\s*$/, "\n\n#{route_scopes}\nend")
    end
  end

  defp generate_route_injection(options) do
    scope_prefix = options[:scope_prefix]
    
    "  # PhoenixKit Authentication routes\n" <>
    "  scope \"/#{scope_prefix}\", BeamLab.PhoenixKitWeb do\n" <>
    "    pipe_through [:browser, :redirect_if_user_is_authenticated]\n\n" <>
    "    get \"/register\", UserRegistrationController, :new\n" <>
    "    post \"/register\", UserRegistrationController, :create\n" <>
    "    get \"/log-in\", UserSessionController, :new\n" <>
    "    post \"/log-in\", UserSessionController, :create\n" <>
    "    get \"/log-in/:token\", UserSessionController, :confirm\n" <>
    "  end\n\n" <>
    "  scope \"/#{scope_prefix}\", BeamLab.PhoenixKitWeb do\n" <>
    "    pipe_through [:browser, :require_authenticated_user]\n\n" <>
    "    get \"/settings\", UserSettingsController, :edit\n" <>
    "    put \"/settings\", UserSettingsController, :update\n" <>
    "    delete \"/log-out\", UserSessionController, :delete\n" <>
    "  end"
  end

  defp remove_existing_phoenix_kit_routes(content) do
    # Remove PhoenixKit-specific content
    content
    |> String.replace(~r/\n\s*import BeamLab\.PhoenixKitWeb\.UserAuth.*?\n/, "\n")
    |> String.replace(~r/\n\s*plug :fetch_current_scope_for_user.*?\n/, "\n")
    |> String.replace(~r/\n\s*# PhoenixKit Authentication routes.*?end\n/s, "\n")
  end

  defp phoenix_project? do
    File.exists?("mix.exs") and 
    String.contains?(File.read!("mix.exs"), ":phoenix")
  end
end