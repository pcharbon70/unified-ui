defmodule UnifiedUi.Dsl.Sections.Styles do
  @moduledoc """
  Canonical styles section definition used by the UnifiedUi DSL.
  """

  @styles_section %Spark.Dsl.Section{
    name: :styles,
    describe: """
    Style and theme entity definitions.
    """,
    schema: [
      fg: [
        type: {:or, [:atom, :tuple, :string]},
        doc: "Foreground color.",
        required: false
      ],
      bg: [
        type: {:or, [:atom, :tuple, :string]},
        doc: "Background color.",
        required: false
      ],
      attrs: [
        type: {:list, :atom},
        doc: "Text attributes (:bold, :italic, etc.).",
        required: false
      ],
      padding: [
        type: :integer,
        doc: "Internal spacing around content.",
        required: false
      ],
      margin: [
        type: :integer,
        doc: "External spacing around element.",
        required: false
      ],
      width: [
        type: {:or, [:integer, :atom]},
        doc: "Width constraint.",
        required: false
      ],
      height: [
        type: {:or, [:integer, :atom]},
        doc: "Height constraint.",
        required: false
      ],
      align: [
        type: {:one_of, [:left, :center, :right, :top, :bottom, :start, :end, :stretch]},
        doc: "Alignment.",
        required: false
      ],
      spacing: [
        type: :integer,
        doc: "Spacing between children in a layout.",
        required: false
      ]
    ],
    entities: [
      UnifiedUi.Dsl.Entities.Styles.style_entity()
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
