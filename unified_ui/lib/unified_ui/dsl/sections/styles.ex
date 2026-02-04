defmodule UnifiedUi.Dsl.Sections.Styles do
  @moduledoc """
  The Styles section for the UnifiedUi DSL.

  This section defines style and theme configuration for UI components.

  ## Style Attributes

  The following style attributes will be supported:
  * `fg` - Foreground color
  * `bg` - Background color
  * `attrs` - Text attributes (:bold, :italic, :underline, etc.)
  * `padding` - Internal spacing
  * `margin` - External spacing
  * `width` - Width constraint
  * `height` - Height constraint
  * `align` - Alignment (:left, :center, :right, :top, :bottom)
  * `spacing` - Spacing between children (for layouts)

  ## Colors

  Colors can be specified as:
  * Named colors: `:red`, `:blue`, `:green`, etc.
  * RGB tuples: `{255, 128, 0}` for orange
  * Hex strings: `"#FF8000"` for orange

  ## Example (Future)

  ```elixir
  ui do
    vbox style: [padding: 2, bg: :black] do
      text "Title", style: [fg: :cyan, attrs: [:bold]]
      text "Description", style: [fg: :white]
    end
  end
  ```
  """

  @styles_section %Spark.Dsl.Section{
    name: :styles,
    describe: """
    The styles section contains style and theme definitions.

    Styles define the visual appearance of widgets and layouts,
    including colors, fonts, spacing, and other visual properties.
    """,
    schema: [
      fg: [
        type: {:or, [:atom, :tuple, :string]},
        doc: "Foreground color. Can be a named atom, RGB tuple, or hex string.",
        required: false
      ],
      bg: [
        type: {:or, [:atom, :tuple, :string]},
        doc: "Background color. Can be a named atom, RGB tuple, or hex string.",
        required: false
      ],
      attrs: [
        type: {:list, :atom},
        doc: "Text attributes like :bold, :italic, :underline, :reverse.",
        required: false
      ],
      padding: [
        type: :integer,
        doc: "Internal spacing around content.",
        required: false
      ],
      margin: [
        type: :integer,
        doc: "External spacing around the element.",
        required: false
      ],
      width: [
        type: {:or, [:integer, :atom]},
        doc: "Width constraint. Integer for pixels, or :auto, :fill.",
        required: false
      ],
      height: [
        type: {:or, [:integer, :atom]},
        doc: "Height constraint. Integer for pixels, or :auto, :fill.",
        required: false
      ],
      align: [
        type: {:one_of, [:left, :center, :right, :top, :bottom, :start, :end, :stretch]},
        doc: "Alignment of content within the element.",
        required: false
      ],
      spacing: [
        type: :integer,
        doc: "Spacing between children in a layout.",
        required: false
      ]
    ],
    entities: [
      # Theme entities will be added in future phases
    ]
  }

  @doc false
  def section, do: @styles_section

  @doc false
  def entities, do: @styles_section.entities

  @doc false
  def top_level?, do: false

  @doc false
  def name, do: @styles_section.name
end
