defmodule PhoenixKitWeb.TestController do
  use PhoenixKitWeb, :controller

  def register(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html>
    <head>
      <title>PhoenixKit Registration Test</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-50">
      <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-md w-full space-y-8">
          <div>
            <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
              Register for an account
            </h2>
            #{if Phoenix.Flash.get(conn.assigns.flash, :error) do
              "<div class=\"mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded\">#{Phoenix.Flash.get(conn.assigns.flash, :error)}</div>"
            else
              ""
            end}
            #{if Phoenix.Flash.get(conn.assigns.flash, :info) do
              "<div class=\"mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded\">#{Phoenix.Flash.get(conn.assigns.flash, :info)}</div>"
            else
              ""
            end}
            <p class="mt-2 text-center text-sm text-gray-600">
              Already registered?
              <a href="/phoenix_kit/log_in" class="font-medium text-indigo-600 hover:text-indigo-500">
                Log in
              </a>
              to your account now.
            </p>
          </div>
          
          <form class="mt-8 space-y-6" method="post" action="/phoenix_kit/register">
            <input type="hidden" name="_csrf_token" value="#{get_csrf_token()}">
            
            <div class="rounded-md shadow-sm -space-y-px">
              <div>
                <label for="user_email" class="sr-only">Email address</label>
                <input id="user_email" name="user[email]" type="email" required 
                       class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                       placeholder="Email address">
              </div>
              <div>
                <label for="user_password" class="sr-only">Password</label>
                <input id="user_password" name="user[password]" type="password" required 
                       class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                       placeholder="Password">
              </div>
            </div>

            <div>
              <button type="submit"
                      class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Create an account
              </button>
            </div>
          </form>
        </div>
      </div>
    </body>
    </html>
    """)
  end
  
  def login(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html>
    <head>
      <title>PhoenixKit Login Test</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-50">
      <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <div class="max-w-md w-full space-y-8">
          <div>
            <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
              Log in to account
            </h2>
            #{if Phoenix.Flash.get(conn.assigns.flash, :error) do
              "<div class=\"mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded\">#{Phoenix.Flash.get(conn.assigns.flash, :error)}</div>"
            else
              ""
            end}
            #{if Phoenix.Flash.get(conn.assigns.flash, :info) do
              "<div class=\"mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded\">#{Phoenix.Flash.get(conn.assigns.flash, :info)}</div>"
            else
              ""
            end}
            <p class="mt-2 text-center text-sm text-gray-600">
              Don't have an account?
              <a href="/phoenix_kit/register" class="font-medium text-indigo-600 hover:text-indigo-500">
                Sign up
              </a>
              for an account now.
            </p>
          </div>
          
          <form class="mt-8 space-y-6" method="post" action="/phoenix_kit/log_in">
            <input type="hidden" name="_csrf_token" value="#{get_csrf_token()}">
            
            <div class="rounded-md shadow-sm -space-y-px">
              <div>
                <label for="user_email" class="sr-only">Email address</label>
                <input id="user_email" name="user[email]" type="email" required 
                       class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                       placeholder="Email address">
              </div>
              <div>
                <label for="user_password" class="sr-only">Password</label>
                <input id="user_password" name="user[password]" type="password" required 
                       class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm" 
                       placeholder="Password">
              </div>
            </div>

            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <input id="user_remember_me" name="user[remember_me]" type="checkbox" 
                       class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded">
                <label for="user_remember_me" class="ml-2 block text-sm text-gray-900">
                  Keep me logged in
                </label>
              </div>

              <div class="text-sm">
                <a href="/phoenix_kit/reset_password" class="font-medium text-indigo-600 hover:text-indigo-500">
                  Forgot your password?
                </a>
              </div>
            </div>

            <div>
              <button type="submit"
                      class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Log in
                <span class="ml-2">→</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </body>
    </html>
    """)
  end
  
  def create_user(conn, %{"user" => user_params}) do
    case PhoenixKit.Accounts.register_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully! Please check your email for confirmation.")
        |> redirect(to: "/phoenix_kit/log_in")
        
      {:error, changeset} ->
        errors = Enum.map(changeset.errors, fn {field, {message, _}} ->
          "#{field}: #{message}"
        end)
        
        conn
        |> put_flash(:error, "Registration failed: #{Enum.join(errors, ", ")}")
        |> redirect(to: "/phoenix_kit/register")
    end
  end
end