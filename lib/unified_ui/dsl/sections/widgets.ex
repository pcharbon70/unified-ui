defmodule UnifiedUi.Dsl.Sections.Widgets do
  @moduledoc """
  Canonical widgets section definition used by the UnifiedUi DSL.
  """

  @widgets_section %Spark.Dsl.Section{
    name: :widgets,
    describe: """
    Widget entity definitions.
    """,
    schema: [],
    entities: [
      UnifiedUi.Dsl.Entities.Widgets.button_entity(),
      UnifiedUi.Dsl.Entities.Widgets.text_entity(),
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
