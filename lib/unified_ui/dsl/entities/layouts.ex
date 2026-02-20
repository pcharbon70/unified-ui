defmodule UnifiedUi.Dsl.Entities.Layouts do
  @moduledoc """
  Spark DSL Entity definitions for layout containers.

  This module defines the DSL entities for the foundational layouts:
  vbox (vertical box) and hbox (horizontal box).

  Each entity specifies:
  - Nested entity types (children)
  - Optional options (schema)
  - Target struct for storing the parsed DSL data
  - Documentation for users

  ## Usage

  These entities are automatically available when using `UnifiedUi.Dsl`:

    defmodule MyApp.MyScreen do
      use UnifiedUi.Dsl

      ui do
        vbox do
          text "Welcome"
          hbox do
            button "OK"
            button "Cancel"
          end
        end
      end
    end

  ## Nesting

  Layouts can contain other layouts and widgets, creating complex
  hierarchical UI structures.
  """

  alias UnifiedIUR.Layouts
  alias UnifiedUi.Dsl.Entities.{DataViz, Navigation, Tables, Widgets}

  @layout_children [
    Widgets.button_entity(),
    Widgets.text_entity(),
    Widgets.label_entity(),
    Widgets.text_input_entity(),
    DataViz.gauge_entity(),
    DataViz.sparkline_entity(),
    DataViz.bar_chart_entity(),
    DataViz.line_chart_entity(),
    Tables.table_entity(),
    Navigation.menu_entity(),
    Navigation.context_menu_entity(),
    Navigation.tabs_entity(),
    Navigation.tree_view_entity()
  ]

  @vbox_entity %Spark.Dsl.Entity{
    name: :vbox,
    target: Layouts.VBox,
    recursive_as: :children,
    args: [],
    schema: [
      id: [
        type: :atom,
        doc: "Unique identifier for the layout.",
        required: false
      ],
      spacing: [
        type: :integer,
        doc: "Space between children.",
        required: false,
        default: 0
      ],
      padding: [
        type: :integer,
        doc: "Internal padding around all children.",
        required: false
      ],
      align_items: [
        type: {:one_of, [:start, :center, :end, :stretch]},
        doc: "Horizontal (cross-axis) alignment of children.",
        required: false
      ],
      justify_content: [
        type: {:one_of, [:start, :center, :end, :stretch, :space_between, :space_around]},
        doc: "Vertical (main-axis) distribution of children.",
        required: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the layout is visible.",
        required: false,
        default: true
      ]
    ],
    entities: [
      children: @layout_children
    ],
    describe: """
    A vertical box layout that arranges children top to bottom.

    VBox is the most common layout for stacking widgets vertically.
    Children can be other layouts or widgets.
    """
  }

  @hbox_entity %Spark.Dsl.Entity{
    name: :hbox,
    target: Layouts.HBox,
    recursive_as: :children,
    args: [],
    schema: [
      id: [
        type: :atom,
        doc: "Unique identifier for the layout.",
        required: false
      ],
      spacing: [
        type: :integer,
        doc: "Space between children.",
        required: false,
        default: 0
      ],
      padding: [
        type: :integer,
        doc: "Internal padding around all children.",
        required: false
      ],
      align_items: [
        type: {:one_of, [:start, :center, :end, :stretch]},
        doc: "Vertical (cross-axis) alignment of children.",
        required: false
      ],
      justify_content: [
        type: {:one_of, [:start, :center, :end, :stretch, :space_between, :space_around]},
        doc: "Horizontal (main-axis) distribution of children.",
        required: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the layout is visible.",
        required: false,
        default: true
      ]
    ],
    entities: [
      children: @layout_children
    ],
    describe: """
    A horizontal box layout that arranges children left to right.

    HBox is commonly used for form rows, button bars, and any
    horizontal arrangement of widgets. Children can be other layouts
    or widgets.
    """
  }

  @doc false
  def vbox_entity, do: @vbox_entity

  @doc false
  def hbox_entity, do: @hbox_entity
end
