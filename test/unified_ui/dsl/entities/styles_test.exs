defmodule UnifiedUi.Dsl.Entities.StylesTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.Entities.Styles

  test "style_entity/0 defines style schema and target" do
    entity = Styles.style_entity()

    assert entity.name == :style
    assert entity.target == UnifiedUi.Dsl.Style
    assert entity.args == [:name]

    assert Keyword.get(entity.schema[:name], :required) == true
    assert Keyword.get(entity.schema[:extends], :required) == false
    assert Keyword.get(entity.schema[:attributes], :default) == []
    assert entity.describe =~ "named style"
  end
end
