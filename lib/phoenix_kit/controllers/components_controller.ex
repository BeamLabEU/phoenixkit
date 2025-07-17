defmodule PhoenixKit.ComponentsController do
  use Phoenix.Controller,
    formats: [:html, :json]

  import Plug.Conn
  import Phoenix.HTML

  alias PhoenixKit.ComponentsHTML

  @moduledoc """
  Components showcase controller for PhoenixKit extension.

  Displays available UI components and their usage examples.
  """

  @doc """
  Renders the components showcase page.
  """
  def index(conn, _params) do
    components = get_available_components()

    conn
    |> put_view(ComponentsHTML)
    |> render(:index,
      title: "PhoenixKit Components",
      subtitle: "Ready-to-use UI components for your Phoenix application",
      components: components,
      categories: get_component_categories()
    )
  end

  defp get_available_components do
    [
      %{
        name: "Alert Component",
        category: "feedback",
        description: "Display important messages to users",
        example: """
        <.alert type="success">
          Operation completed successfully!
        </.alert>
        """,
        props: [
          %{
            name: "type",
            type: "string",
            required: true,
            options: ["success", "error", "warning", "info"]
          },
          %{name: "dismissible", type: "boolean", required: false, default: false}
        ]
      },
      %{
        name: "Button Component",
        category: "inputs",
        description: "Customizable button with various styles",
        example: """
        <.button variant="primary" size="lg">
          Click me!
        </.button>
        """,
        props: [
          %{
            name: "variant",
            type: "string",
            required: false,
            options: ["primary", "secondary", "danger"]
          },
          %{name: "size", type: "string", required: false, options: ["sm", "md", "lg"]}
        ]
      },
      %{
        name: "Card Component",
        category: "layout",
        description: "Flexible container for content",
        example: """
        <.card title="Card Title">
          <p>Card content goes here...</p>
        </.card>
        """,
        props: [
          %{name: "title", type: "string", required: false},
          %{name: "footer", type: "string", required: false}
        ]
      },
      %{
        name: "Modal Component",
        category: "overlay",
        description: "Modal dialog for important interactions",
        example: """
        <.modal id="example-modal" title="Modal Title">
          <p>Modal content...</p>
        </.modal>
        """,
        props: [
          %{name: "id", type: "string", required: true},
          %{name: "title", type: "string", required: false},
          %{name: "size", type: "string", required: false, options: ["sm", "md", "lg", "xl"]}
        ]
      },
      %{
        name: "Table Component",
        category: "data",
        description: "Sortable and filterable data table",
        example: """
        <.table rows={@users} columns={@columns} />
        """,
        props: [
          %{name: "rows", type: "list", required: true},
          %{name: "columns", type: "list", required: true},
          %{name: "sortable", type: "boolean", required: false, default: true}
        ]
      }
    ]
  end

  defp get_component_categories do
    [
      %{name: "inputs", label: "Form Inputs", icon: "📝"},
      %{name: "feedback", label: "Feedback", icon: "💬"},
      %{name: "layout", label: "Layout", icon: "📐"},
      %{name: "overlay", label: "Overlays", icon: "🔲"},
      %{name: "data", label: "Data Display", icon: "📊"}
    ]
  end
end
