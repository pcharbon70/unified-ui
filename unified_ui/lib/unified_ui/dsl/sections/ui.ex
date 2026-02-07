defmodule UnifiedUi.Dsl.Sections.Ui do
  @moduledoc """
  The UI section for the UnifiedUi DSL.

  This is the top-level section for defining user interfaces.
  It serves as the entry point for all UI definitions and can contain
  layouts, widgets, and style definitions.

  ## Example

  ```elixir
  ui do
    vbox style: [padding: 2] do
      text "Hello, World!"
      button "Click me"
    end
  end
  ```
  """

  @ui_section %Spark.Dsl.Section{
    name: :ui,
    describe: """
    The top-level UI definition section.

    This section contains the entire UI definition for a component or screen.
    It can contain layouts, widgets, and style definitions.
    """,
    schema: [
      id: [
        type: :atom,
        doc: "A unique identifier for this UI component.",
        required: false
      ],
      theme: [
        type: :atom,
        doc: "The theme to apply to this UI component.",
        required: false
      ]
    ],
    entities: [
      # Layout entities will be added here in future phases
      # Widget entities will be added here in future phases
    ]
  }

  @doc false
  def section, do: @ui_section

  @doc false
  def entities, do: @ui_section.entities

  # Top-level section following the Reactor pattern
  # Entities are written directly in the module body without a `ui do...end` wrapper
  @doc false
  def top_level?, do: true

  @doc false
  def name, do: @ui_section.name
end
