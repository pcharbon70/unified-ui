defmodule UnifiedUi.Dsl.Sections.Layouts do
  @moduledoc """
  Canonical layouts section definition used by the UnifiedUi DSL.
  """

  @layouts_section %Spark.Dsl.Section{
    name: :layouts,
    describe: """
    Layout entity definitions.
    """,
    schema: [],
    entities: [
      UnifiedUi.Dsl.Entities.Layouts.vbox_entity(),
      UnifiedUi.Dsl.Entities.Layouts.hbox_entity()
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
