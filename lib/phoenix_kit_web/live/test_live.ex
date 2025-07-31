defmodule PhoenixKitWeb.TestLive do
  use PhoenixKitWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="hero min-h-screen bg-base-200">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold">LiveView Test</h1>
          <p class="py-6">If you see this styled page, LiveView is working with DaisyUI!</p>

          <div class="card w-96 bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Simple Form Test</h2>
              <.simple_form for={@form} phx-submit="test" class="form-control">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Test Field</span>
                  </label>
                  <.input
                    field={@form[:test_field]}
                    type="text"
                    placeholder="Type something..."
                    class="input input-bordered"
                  />
                </div>
                <div class="card-actions justify-end mt-4">
                  <.button class="btn btn-primary">Test Button</.button>
                </div>
              </.simple_form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{"test_field" => ""}, as: "test")
    {:ok, assign(socket, form: form)}
  end

  def handle_event("test", %{"test" => test_params}, socket) do
    IO.inspect(test_params, label: "Received test form data")
    {:noreply, socket}
  end
end
