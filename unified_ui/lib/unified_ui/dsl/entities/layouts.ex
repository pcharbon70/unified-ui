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

  alias UnifiedUi.IUR.Layouts

  @doc """
  VBox (vertical box) layout entity for arranging children top-to-bottom.

  ## Children

  Accepts nested widget and layout entities within a `do` block.

  ## Options

  * `:id` - Unique identifier for the layout (optional)
  * `:spacing` - Space between children (integer, default: 0)
  * `:padding` - Internal padding around all children (integer, optional)
  * `:align_items` - Horizontal (cross-axis) alignment of children
  * `:justify_content` - Vertical (main-axis) distribution of children
  * `:style` - Inline style as keyword list (optional)
  * `:visible` - Whether the layout is visible (default: true)

  ## Alignment Values

  For `align_items` (horizontal alignment):
  * `:start` - Children align to the left
  * `:center` - Children are horizontally centered
  * `:end` - Children align to the right
  * `:stretch` - Children stretch to fill the width

  For `justify_content` (vertical distribution):
  * `:start` - Children start at the top
  * `:center` - Children are vertically centered
  * `:end` - Children end at the bottom
  * `:stretch` - Children stretch to fill the height
  * `:space_between` - Space distributed between children
  * `:space_around` - Space distributed around children

  ## Examples

      vbox do
        text "Title"
        text "Subtitle"
      end

      vbox spacing: 2, align_items: :center do
        button "OK"
        button "Cancel"
      end

      vbox padding: 1 do
        text "Padded content"
      end

  """
  @vbox_entity %Spark.Dsl.Entity{
    name: :vbox,
    target: Layouts.VBox,
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
    entities: [],
    describe: """
    A vertical box layout that arranges children top to bottom.

    VBox is the most common layout for stacking widgets vertically.
    Children can be other layouts or widgets.
    """
  }

  @doc """
  HBox (horizontal box) layout entity for arranging children left-to-right.

  ## Children

  Accepts nested widget and layout entities within a `do` block.

  ## Options

  * `:id` - Unique identifier for the layout (optional)
  * `:spacing` - Space between children (integer, default: 0)
  * `:padding` - Internal padding around all children (integer, optional)
  * `:align_items` - Vertical (cross-axis) alignment of children
  * `:justify_content` - Horizontal (main-axis) distribution of children
  * `:style` - Inline style as keyword list (optional)
  * `:visible` - Whether the layout is visible (default: true)

  ## Alignment Values

  For `align_items` (vertical alignment):
  * `:start` - Children align to the top
  * `:center` - Children are vertically centered
  * `:end` - Children align to the bottom
  * `:stretch` - Children stretch to fill the height

  For `justify_content` (horizontal distribution):
  * `:start` - Children start at the left
  * `:center` - Children are horizontally centered
  * `:end` - Children end at the right
  * `:stretch` - Children stretch to fill the width
  * `:space_between` - Space distributed between children
  * `:space_around` - Space distributed around children

  ## Examples

      hbox do
        text "Label:"
        text_input :name
      end

      hbox spacing: 2, align_items: :center do
        button "OK"
        button "Cancel"
      end

      hbox justify_content: :space_between do
        text "Left"
        text "Right"
      end

  """
  @hbox_entity %Spark.Dsl.Entity{
    name: :hbox,
    target: Layouts.HBox,
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
    entities: [],
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
