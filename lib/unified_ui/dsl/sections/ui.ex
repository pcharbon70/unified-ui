defmodule UnifiedUi.Dsl.Sections.Ui do
  @moduledoc """
  Canonical UI section definition used by the UnifiedUi DSL.

  This module exists for section-level introspection and compatibility.
  The extension currently composes equivalent section definitions directly.
  """

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
    describe: "Define initial component state"
  }

  @ui_section %Spark.Dsl.Section{
    name: :ui,
    describe: """
    Top-level UI definition section.
    """,
    schema: [
      id: [
        type: :atom,
        doc: "Optional unique identifier for this UI component.",
        required: false
      ],
      theme: [
        type: :atom,
        doc: "Optional theme to apply to this UI component.",
        required: false
      ]
    ],
    entities: [
      @state_entity,
      UnifiedUi.Dsl.Entities.Layouts.vbox_entity(),
      UnifiedUi.Dsl.Entities.Layouts.hbox_entity(),
      UnifiedUi.Dsl.Entities.Widgets.text_entity(),
      UnifiedUi.Dsl.Entities.Widgets.button_entity(),
      UnifiedUi.Dsl.Entities.Widgets.label_entity(),
      UnifiedUi.Dsl.Entities.Widgets.text_input_entity(),
      UnifiedUi.Dsl.Entities.DataViz.gauge_entity(),
      UnifiedUi.Dsl.Entities.DataViz.sparkline_entity(),
      UnifiedUi.Dsl.Entities.DataViz.bar_chart_entity(),
      UnifiedUi.Dsl.Entities.DataViz.line_chart_entity(),
      UnifiedUi.Dsl.Entities.Tables.table_entity(),
      UnifiedUi.Dsl.Entities.Navigation.menu_entity(),
      UnifiedUi.Dsl.Entities.Navigation.context_menu_entity(),
      UnifiedUi.Dsl.Entities.Navigation.tabs_entity(),
      UnifiedUi.Dsl.Entities.Navigation.tree_view_entity()
    ],
    top_level?: true
  }

  @doc false
  def section, do: @ui_section

  @doc false
  def entities, do: @ui_section.entities

  @doc false
  def top_level?, do: true

  @doc false
  def name, do: @ui_section.name
end
