defmodule PhoenixKitWeb.Integration do
  @moduledoc """
  Integration helpers for adding PhoenixKit authentication to parent Phoenix applications.

  This module provides helper functions and macros to easily integrate PhoenixKit's
  authentication system into existing Phoenix applications using the forward pattern.
  """

  @doc """
  Adds PhoenixKit authentication routes to your router.

  ## Usage

  In your main application's router.ex:

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        
        # Add this line to import the helper
        import PhoenixKitWeb.Integration
        
        # ... your existing pipelines ...
        
        # Add PhoenixKit auth routes - they work independently of your :browser pipeline!
        phoenix_kit_routes()  # Uses /phoenix_kit prefix by default
        
        # Or with custom prefix if needed
        phoenix_kit_routes("/authentication")
      end

  **Note:** PhoenixKit routes work completely independently and don't require 
  your application's :browser pipeline. They create their own pipeline with 
  all necessary plugs for LiveView forms to work properly.

  ## Passing Current User to Your App's Layouts

  To access the current user in your application's layouts, add PhoenixKit's 
  on_mount callback to your live_session:

      # Basic approach - adds @phoenix_kit_current_user to assigns
      live_session :default,
        layout: {MyAppWeb.Layouts, :app},
        on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_user}] do
        live "/", PageLive
        live "/dashboard", DashboardLive
        # ... your routes
      end

      # Advanced approach - adds both @phoenix_kit_current_user and @phoenix_kit_current_scope
      live_session :default,
        layout: {MyAppWeb.Layouts, :app},
        on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_scope}] do
        live "/", PageLive
        live "/dashboard", DashboardLive
        # ... your routes
      end

  This makes authentication data available in your layouts and LiveViews:

      <!-- In your app's layout (e.g., app.html.heex) -->
      <%= if @phoenix_kit_current_user do %>
        <div class="user-menu">
          Welcome, {@phoenix_kit_current_user.email}!
          <.link href="/phoenix_kit/settings">Settings</.link>
          <.link href="/phoenix_kit/log_out" method="delete">Logout</.link>
        </div>
      <% else %>
        <div class="auth-links">
          <.link href="/phoenix_kit/log_in">Login</.link>
          <.link href="/phoenix_kit/register">Sign Up</.link>
        </div>
      <% end %>

      <!-- Using the scope approach for better encapsulation -->
      <%= if PhoenixKit.Accounts.Scope.authenticated?(@phoenix_kit_current_scope) do %>
        <div class="user-menu">
          Welcome, {PhoenixKit.Accounts.Scope.user_email(@phoenix_kit_current_scope)}!
          <.link href="/phoenix_kit/settings">Settings</.link>
          <.link href="/phoenix_kit/log_out" method="delete">Logout</.link>
        </div>
      <% else %>
        <div class="auth-links">
          <.link href="/phoenix_kit/log_in">Login</.link>
          <.link href="/phoenix_kit/register">Sign Up</.link>
        </div>
      <% end %>

  ## Authentication Levels Available

  PhoenixKit provides multiple authentication on_mount callbacks:

  ### Basic User Mount
  - `:phoenix_kit_mount_current_user` - Always accessible, mounts current user or nil
  - `:phoenix_kit_mount_current_scope` - Always accessible, mounts both user and scope

  ### Protected Routes  
  - `:phoenix_kit_ensure_authenticated` - Requires authentication, redirects to login if not logged in
  - `:phoenix_kit_ensure_authenticated_scope` - Same as above but using scope system

  ### Redirect If Authenticated
  - `:phoenix_kit_redirect_if_user_is_authenticated` - Redirects away if already logged in (for login/register pages)
  - `:phoenix_kit_redirect_if_authenticated_scope` - Same as above but using scope system

  ## Complete Router Integration Example

      # Complete example showing both PhoenixKit routes and app routes with scope
      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import PhoenixKitWeb.Integration

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_live_flash
          plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end

        # Add PhoenixKit authentication routes
        phoenix_kit_routes()

        # Your app routes with current user available in layouts
        scope "/", MyAppWeb do
          pipe_through :browser

          # Public routes with optional user info in layouts
          live_session :public,
            layout: {MyAppWeb.Layouts, :app},
            on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_scope}] do
            live "/", PageLive
            live "/about", AboutLive
            live "/pricing", PricingLive
          end

          # Protected routes requiring authentication
          live_session :authenticated,
            layout: {MyAppWeb.Layouts, :app},
            on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_ensure_authenticated_scope}] do
            live "/dashboard", DashboardLive
            live "/profile", ProfileLive
            live "/settings", AppSettingsLive  # Note: different from /phoenix_kit/settings
          end

          # Admin-only routes (you can add your own authorization logic)
          live_session :admin,
            layout: {MyAppWeb.Layouts, :admin},
            on_mount: [
              {PhoenixKitWeb.UserAuth, :phoenix_kit_ensure_authenticated_scope},
              {MyAppWeb.AdminAuth, :ensure_admin}  # Your custom admin check
            ] do
            live "/admin", AdminDashboardLive
            live "/admin/users", AdminUsersLive
          end
        end
      end

  ## Migration from existing current_user patterns

  If your app already uses `current_user`, PhoenixKit won't conflict:

      # Your existing patterns continue to work
      <%= if @current_user do %>
        <!-- Your existing user menu -->
      <% end %>

      # PhoenixKit data is separate and prefixed
      <%= if @phoenix_kit_current_user do %>
        <!-- PhoenixKit user menu -->
      <% end %>

  ## Scope System Benefits

  The scope system provides better encapsulation and is ready for future extensions:

      # Instead of checking user directly
      <%= if @phoenix_kit_current_user do %>
        <!-- content -->
      <% end %>

      # Use scope for better structure
      <%= if PhoenixKit.Accounts.Scope.authenticated?(@phoenix_kit_current_scope) do %>
        <!-- content -->
      <% end %>

      # Easy access to user data through scope
      <span>Welcome, {PhoenixKit.Accounts.Scope.user_email(@phoenix_kit_current_scope)}!</span>
      <span>User ID: {PhoenixKit.Accounts.Scope.user_id(@phoenix_kit_current_scope)}</span>


  ## Authentication Levels Available

  PhoenixKit provides multiple authentication on_mount callbacks:

  ### Basic User Callbacks
  - `:phoenix_kit_mount_current_user` - Always accessible, mounts current user or nil
  - `:phoenix_kit_ensure_authenticated` - Requires authentication, redirects to login if not logged in  
  - `:phoenix_kit_redirect_if_user_is_authenticated` - Redirects away if already logged in (for login/register pages)

  ### Advanced Scope Callbacks (Recommended for New Projects)
  - `:phoenix_kit_mount_current_scope` - Always accessible, mounts both user and scope
  - `:phoenix_kit_ensure_authenticated_scope` - Requires authentication via scope system
  - `:phoenix_kit_redirect_if_authenticated_scope` - Redirects away if authenticated via scope system

  ## Complete Router Integration Example

      # Complete example showing both PhoenixKit routes and app routes with scope
      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import PhoenixKitWeb.Integration

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_live_flash
          plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end

        # Add PhoenixKit authentication routes
        phoenix_kit_routes()

        # Your app routes with current user available in layouts
        scope "/", MyAppWeb do
          pipe_through :browser

          # Public routes with optional user info (RECOMMENDED APPROACH)
          live_session :public,
            layout: {MyAppWeb.Layouts, :app},
            on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_scope}] do
            live "/", PageLive
            live "/about", AboutLive
            live "/contact", ContactLive
          end

          # Protected routes requiring authentication
          live_session :authenticated,
            layout: {MyAppWeb.Layouts, :app},
            on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_ensure_authenticated_scope}] do
            live "/dashboard", DashboardLive
            live "/profile", ProfileLive
            live "/settings", AppSettingsLive
          end

          # Routes that redirect authenticated users (login/register pages)
          live_session :redirect_if_authenticated,
            layout: {MyAppWeb.Layouts, :app},
            on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_authenticated_scope}] do
            live "/welcome", WelcomeLive
            live "/pricing", PricingLive
          end
        end
      end

  ## Migration from Existing Implementation

  If you already have a working integration with `phoenix_kit_mount_current_user`,
  you can gradually migrate to the scope system:

      # Step 1: Current working setup
      live_session :default,
        layout: {MyAppWeb.Layouts, :app},
        on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_user}] do
        # ... routes
      end

      # Step 2: Upgrade to scope (adds both user and scope)
      live_session :default,
        layout: {MyAppWeb.Layouts, :app},
        on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_scope}] do
        # ... same routes, now you have access to both:
        # @phoenix_kit_current_user (backwards compatible)
        # @phoenix_kit_current_scope (new, better encapsulation)
      end

  The scope approach provides better encapsulation and is recommended for new projects,
  while maintaining full backwards compatibility with existing `@phoenix_kit_current_user` usage.

  ## Scope vs User: When to Use What

  ### Use `@phoenix_kit_current_user` when:
  - You have simple authentication needs
  - You're migrating from existing Phoenix auth patterns
  - You need quick access to user properties
  - Your app doesn't need complex authorization logic

  ### Use `@phoenix_kit_current_scope` when:
  - You want better encapsulation and structure
  - You're building a new application from scratch
  - You need explicit authentication state checking
  - You plan to extend with roles or permissions later
  - You want to follow modern Phoenix patterns

  ## Quick Reference

  ### Basic User Access
  ```heex
  <!-- Check if logged in -->
  <%%= if @phoenix_kit_current_user do %>
    <p>Welcome, {@phoenix_kit_current_user.email}!</p>
  <%% end %>

  <!-- Access user properties directly -->
  <p>User ID: {@phoenix_kit_current_user.id}</p>
  ```

  ### Scope-based Access (Recommended)
  ```heex
  <!-- Check authentication status -->
  <%%= if PhoenixKit.Accounts.Scope.authenticated?(@phoenix_kit_current_scope) do %>
    <p>Welcome, {PhoenixKit.Accounts.Scope.user_email(@phoenix_kit_current_scope)}!</p>
  <%% end %>

  <!-- Safe property access -->
  <%%= if user_id = PhoenixKit.Accounts.Scope.user_id(@phoenix_kit_current_scope) do %>
    <.link href={"/profile/\#{user_id}"}>View Profile</.link>
  <%% end %>

  <!-- Check if anonymous -->
  <%%= if PhoenixKit.Accounts.Scope.anonymous?(@phoenix_kit_current_scope) do %>
    <.link href="/phoenix_kit/register">Create Account</.link>
  <%% end %>
  ```

  ## Routes created

  The following routes will be available under /phoenix_kit prefix (or your custom prefix):

  - GET /phoenix_kit/register - User registration page
  - GET /phoenix_kit/log_in - User login page  
  - GET /phoenix_kit/magic_link - Magic link login page
  - POST /phoenix_kit/log_in - User login form submission
  - DELETE /phoenix_kit/log_out - User logout
  - GET /phoenix_kit/log_out - User logout (direct URL access)
  - GET /phoenix_kit/reset_password - Password reset request page
  - GET /phoenix_kit/reset_password/:token - Password reset form
  - GET /phoenix_kit/settings - User settings page
  - GET /phoenix_kit/settings/confirm_email/:token - Email confirmation
  - GET /phoenix_kit/confirm/:token - Account confirmation
  - GET /phoenix_kit/confirm - Resend confirmation instructions
  - GET /phoenix_kit/magic_link/:token - Magic link verification

  ## Configuration

  Make sure your application is configured properly:

      # config/config.exs
      config :phoenix_kit,
        repo: MyApp.Repo
        
      # Add to your deps in mix.exs  
      {:phoenix_kit, "~> 0.1.0"}
  """
  defmacro phoenix_kit_routes(prefix \\ "/phoenix_kit") do
    quote do
      # Define the auto-setup pipeline
      pipeline :phoenix_kit_auto_setup do
        plug PhoenixKitWeb.Integration, :phoenix_kit_auto_setup
      end

      pipeline :phoenix_kit_redirect_if_authenticated do
        plug PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated
      end

      pipeline :phoenix_kit_require_authenticated do
        plug PhoenixKitWeb.UserAuth, :fetch_phoenix_kit_current_user
        plug PhoenixKitWeb.UserAuth, :phoenix_kit_require_authenticated_user
      end

      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup, :phoenix_kit_redirect_if_authenticated]

        post "/log_in", UserSessionController, :create
      end

      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup]

        delete "/log_out", UserSessionController, :delete
        get "/log_out", UserSessionController, :get_logout
        get "/magic_link/:token", UserMagicLinkController, :verify
      end

      # LiveView routes with proper authentication
      scope unquote(prefix), PhoenixKitWeb do
        pipe_through [:browser, :phoenix_kit_auto_setup]

        live_session :phoenix_kit_redirect_if_user_is_authenticated,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_redirect_if_user_is_authenticated}] do
          # live "/test", TestLive, :index  # Moved to require_authenticated section
          live "/register", UserRegistrationLive, :new
          live "/log_in", UserLoginLive, :new
          live "/magic_link", UserMagicLinkLive, :new
          live "/reset_password", UserForgotPasswordLive, :new
          live "/reset_password/:token", UserResetPasswordLive, :edit
        end

        live_session :phoenix_kit_current_user,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_mount_current_user}] do
          live "/confirm/:token", UserConfirmationLive, :edit
          live "/confirm", UserConfirmationInstructionsLive, :new
        end

        live_session :phoenix_kit_require_authenticated_user,
          on_mount: [{PhoenixKitWeb.UserAuth, :phoenix_kit_ensure_authenticated}] do
          # live "/test", TestLive, :index
          live "/settings", UserSettingsLive, :edit
          live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
        end
      end
    end
  end

  @doc """
  Pipeline plug for PhoenixKit setup verification.

  Setup is now handled during installation via igniter.
  This plug is maintained for compatibility but no longer performs setup.
  """
  def init(opts), do: opts

  def call(conn, :phoenix_kit_auto_setup) do
    # Setup is handled by igniter installation - just pass through
    conn
  end

  @doc """
  Returns the configuration needed for PhoenixKit integration.

  Add this to your configuration files:

      # In config/config.exs
      config :phoenix_kit, repo: MyApp.Repo
  """
  def sample_config do
    """
    config :phoenix_kit,
      repo: MyApp.Repo
    """
  end

  @doc """
  Instructions for manual route setup if you prefer not to use the macro.
  """
  def manual_setup_instructions do
    """
    If you prefer to set up routes manually, add this to your router:

        scope "/phoenix_kit" do
          pipe_through :browser
          forward "/", PhoenixKitWeb.AuthRouter
        end
        
    Or for a custom path:
        
        scope "/auth" do  
          pipe_through :browser
          forward "/", PhoenixKitWeb.AuthRouter
        end
    """
  end
end
