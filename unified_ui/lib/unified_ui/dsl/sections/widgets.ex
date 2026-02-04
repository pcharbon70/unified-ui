defmodule UnifiedUi.Dsl.Sections.Widgets do
  @moduledoc """
  The Widgets section for the UnifiedUi DSL.

  This section defines widget entities - the basic building blocks of a UI.
  Widgets include text labels, buttons, inputs, and other UI components.

  ## Planned Widgets

  The following widgets will be defined in future phases:
  * `text` - Display text content
  * `button` - Clickable button
  * `label` - Label for form inputs
  * `text_input` - Single-line text input
  * `text_area` - Multi-line text input
  * `checkbox` - Checkbox input
  * `table` - Data table with sorting
  * `gauge` - Progress indicator
  * `sparkline` - Inline trend graph
  And many more from the TermUi widget library.

  ## Example (Future)

  ```elixir
  ui do
    vbox do
      text "Welcome!", style: [fg: :cyan, attrs: [:bold]]
      button "Submit", id: :submit_btn
    end
  end
  ```
  """

  @widgets_section %Spark.Dsl.Section{
    name: :widgets,
    describe: """
    The widgets section contains widget entity definitions.

    Widgets are the basic building blocks of a user interface.
    Each widget represents a UI element like text, buttons, or inputs.
    """,
    schema: [],
    entities: [
      # Widget entities will be added in future phases:
      # - text
      # - button
      # - text_input
      # - label
      # etc.
    ]
  }

  @doc false
  def section, do: @widgets_section

  @doc false
  def entities, do: @widgets_section.entities

  @doc false
  def top_level?, do: false

  @doc false
  def name, do: @widgets_section.name
end
