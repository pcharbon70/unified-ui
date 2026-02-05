defmodule UnifiedUi.Dsl.Extension do
  @moduledoc """
  The Spark DSL Extension for UnifiedUi.

  This extension defines the DSL constructs for building multi-platform user interfaces.
  It provides sections for UI definitions, widgets, layouts, styles, and signals.

  ## Usage

  To use the UnifiedUi DSL in your module:

  ```elixir
  defmodule MyApp.MyScreen do
    use UnifiedUi.Dsl

    ui do
      vbox style: [padding: 2] do
        text "Welcome to MyApp!"
        button "Click me", on_click: fn -> {:button_clicked, %{}} end
      end
    end
  end
  ```

  ## DSL Structure

  The DSL is organized into sections:

  * `:ui` - Top-level section for UI definitions
  * `:widgets` - Widget entity definitions (text, button, label, text_input, etc.)
  * `:layouts` - Layout entity definitions (vbox, hbox, grid, etc.)
  * `:styles` - Style and theme definitions
  * `:signals` - Signal type definitions for inter-component communication

  ## Sections

  ### UI Section

  The `ui` section is the top-level entry point for defining UIs.
  It can contain layouts and widgets.

  ### Widgets Section

  The `widgets` section contains individual widget definitions.
  Widgets are the basic building blocks of a UI (text, buttons, inputs, etc.).

  ### Layouts Section

  The `layouts` section contains layout containers that arrange widgets.
  Layouts can contain other layouts and widgets.

  ### Styles Section

  The `styles` section defines visual styling options.
  Styles include colors, fonts, spacing, and other visual properties.

  ### Signals Section

  The `signals` section defines signal types for inter-component communication.
  Signals are used with the JidoSignal library for agent-based communication.

  """

  # Entity for state definition in UI section
  @state_entity %Spark.Dsl.Entity{
    name: :state,
    target: UnifiedUi.Dsl.State,
    args: [:attrs],
    schema: [
      attrs: [
        type: :keyword_list,
        doc: "Initial state as keyword list with atom keys",
        required: true
      ]
    ],
    describe: "Define the initial state for the component"
  }

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
    entities: [@state_entity]
  }

  @widgets_section %Spark.Dsl.Section{
    name: :widgets,
    describe: """
    The widgets section contains widget entity definitions.

    Widgets are the basic building blocks of a user interface.
    Each widget represents a UI element like text, buttons, or inputs.
    """,
    schema: [],
    entities: [
      UnifiedUi.Dsl.Entities.Widgets.button_entity(),
      UnifiedUi.Dsl.Entities.Widgets.text_entity(),
      UnifiedUi.Dsl.Entities.Widgets.label_entity(),
      UnifiedUi.Dsl.Entities.Widgets.text_input_entity()
    ]
  }

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

  @signals_section %Spark.Dsl.Section{
    name: :signals,
    describe: """
    The signals section contains signal type definitions.

    Signals are used for inter-component communication via the JidoSignal library.
    They represent events that occur when users interact with UI elements.
    """,
    schema: [
      name: [
        type: :atom,
        doc: "The name of the signal type.",
        required: true
      ],
      payload: [
        type: :keyword_list,
        doc: "The payload schema for the signal.",
        required: false
      ],
      description: [
        type: :string,
        doc: "Human-readable description of the signal.",
        required: false
      ]
    ],
    entities: [
      # Custom signal entities will be added in future phases
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@ui_section, @widgets_section, @layouts_section, @styles_section, @signals_section],
    transformers: [
      UnifiedUi.Dsl.Transformers.InitTransformer,
      UnifiedUi.Dsl.Transformers.UpdateTransformer,
      UnifiedUi.Dsl.Transformers.ViewTransformer
    ],
    verifiers: []
end
