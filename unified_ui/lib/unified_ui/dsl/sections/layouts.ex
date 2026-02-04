defmodule UnifiedUi.Dsl.Sections.Layouts do
  @moduledoc """
  The Layouts section for the UnifiedUi DSL.

  This section defines layout entities - containers that arrange widgets
  and other layouts in specific patterns.

  ## Planned Layouts

  The following layouts will be defined in future phases:
  * `vbox` - Vertical box (arranges children top to bottom)
  * `hbox` - Horizontal box (arranges children left to right)
  * `grid` - Grid layout (rows and columns)
  * `stack` - Stacked layout (overlapping children)
  * `split` - Split pane (resizable dividers)

  ## Example (Future)

  ```elixir
  ui do
    vbox spacing: 1 do
      hbox do
        text "Label:"
        text_input id: :name_input
      end
      hbox do
        button "Save"
        button "Cancel"
      end
    end
  end
  ```
  """

  @layouts_section %Spark.Dsl.Section{
    name: :layouts,
    describe: """
    The layouts section contains layout entity definitions.

    Layouts are containers that arrange widgets and other layouts
    in specific patterns like rows, columns, or grids.
    """,
    schema: [],
    entities: [
      # Layout entities will be added in future phases:
      # - vbox
      # - hbox
      # - grid
      # - stack
      # - split
      # etc.
    ]
  }

  @doc false
  def section, do: @layouts_section

  @doc false
  def entities, do: @layouts_section.entities

  @doc false
  def top_level?, do: false

  @doc false
  def name, do: @layouts_section.name
end
