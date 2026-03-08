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
        type: {:or, [:atom, :string, {:tuple, [:integer, :integer, :integer]}]},
        doc: "Foreground color.",
        required: false
      ],
      bg: [
        type: {:or, [:atom, :string, {:tuple, [:integer, :integer, :integer]}]},
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
      UnifiedUi.Dsl.Entities.Styles.style_entity(),
      UnifiedUi.Dsl.Entities.Styles.theme_entity()
    ]
  }

  @doc false
  @spec section() :: Spark.Dsl.Section.t()
  def section, do: @styles_section

  @doc false
  @spec entities() :: [Spark.Dsl.Entity.t()]
  def entities, do: @styles_section.entities

  @doc false
  @spec top_level?() :: boolean()
  def top_level?, do: false

  @doc false
  @spec name() :: atom()
  def name, do: @styles_section.name
end
