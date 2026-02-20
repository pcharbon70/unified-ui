defmodule UnifiedUi.Dsl.Entities.LayoutsTest do
  @moduledoc """
  Tests for the layout DSL entities.

  These tests verify that:
  - All layout entities are defined correctly
  - Layout entities create the correct target structs
  - Layout options are validated properly
  - Required arguments are enforced
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.Entities.Layouts, as: LayoutEntities
  alias UnifiedIUR.Layouts

  describe "vbox_entity/0" do
    test "returns a valid Spark.Dsl.Entity" do
      entity = LayoutEntities.vbox_entity()

      assert %Spark.Dsl.Entity{name: :vbox} = entity
      assert entity.target == Layouts.VBox
    end

    test "has no positional args (children via do block)" do
      entity = LayoutEntities.vbox_entity()
      assert entity.args == []
    end

    test "has optional id option" do
      entity = LayoutEntities.vbox_entity()

      id_schema = Keyword.get(entity.schema, :id)
      assert id_schema != nil
      assert Keyword.get(id_schema, :required) == false
    end

    test "has spacing option with default" do
      entity = LayoutEntities.vbox_entity()

      spacing_schema = Keyword.get(entity.schema, :spacing)
      assert spacing_schema != nil
      assert Keyword.get(spacing_schema, :default) == 0
    end

    test "has padding option" do
      entity = LayoutEntities.vbox_entity()

      padding_schema = Keyword.get(entity.schema, :padding)
      assert padding_schema != nil
      assert Keyword.get(padding_schema, :required) == false
    end

    test "has align_items option with correct values" do
      entity = LayoutEntities.vbox_entity()

      align_items_schema = Keyword.get(entity.schema, :align_items)
      assert align_items_schema != nil

      assert {:one_of, [:start, :center, :end, :stretch]} = Keyword.get(align_items_schema, :type)
    end

    test "has justify_content option with correct values" do
      entity = LayoutEntities.vbox_entity()

      justify_content_schema = Keyword.get(entity.schema, :justify_content)
      assert justify_content_schema != nil

      assert {:one_of, [:start, :center, :end, :stretch, :space_between, :space_around]} =
               Keyword.get(justify_content_schema, :type)
    end

    test "has style option" do
      entity = LayoutEntities.vbox_entity()

      style_schema = Keyword.get(entity.schema, :style)
      assert style_schema != nil
      assert Keyword.get(style_schema, :type) == :keyword_list
    end

    test "has visible option with default" do
      entity = LayoutEntities.vbox_entity()

      visible_schema = Keyword.get(entity.schema, :visible)
      assert visible_schema != nil
      assert Keyword.get(visible_schema, :default) == true
    end
  end

  describe "hbox_entity/0" do
    test "returns a valid Spark.Dsl.Entity" do
      entity = LayoutEntities.hbox_entity()

      assert %Spark.Dsl.Entity{name: :hbox} = entity
      assert entity.target == Layouts.HBox
    end

    test "has no positional args (children via do block)" do
      entity = LayoutEntities.hbox_entity()
      assert entity.args == []
    end

    test "has optional id option" do
      entity = LayoutEntities.hbox_entity()

      id_schema = Keyword.get(entity.schema, :id)
      assert id_schema != nil
      assert Keyword.get(id_schema, :required) == false
    end

    test "has spacing option with default" do
      entity = LayoutEntities.hbox_entity()

      spacing_schema = Keyword.get(entity.schema, :spacing)
      assert spacing_schema != nil
      assert Keyword.get(spacing_schema, :default) == 0
    end

    test "has padding option" do
      entity = LayoutEntities.hbox_entity()

      padding_schema = Keyword.get(entity.schema, :padding)
      assert padding_schema != nil
      assert Keyword.get(padding_schema, :required) == false
    end

    test "has align_items option with correct values" do
      entity = LayoutEntities.hbox_entity()

      align_items_schema = Keyword.get(entity.schema, :align_items)
      assert align_items_schema != nil

      assert {:one_of, [:start, :center, :end, :stretch]} = Keyword.get(align_items_schema, :type)
    end

    test "has justify_content option with correct values" do
      entity = LayoutEntities.hbox_entity()

      justify_content_schema = Keyword.get(entity.schema, :justify_content)
      assert justify_content_schema != nil

      assert {:one_of, [:start, :center, :end, :stretch, :space_between, :space_around]} =
               Keyword.get(justify_content_schema, :type)
    end

    test "has style option" do
      entity = LayoutEntities.hbox_entity()

      style_schema = Keyword.get(entity.schema, :style)
      assert style_schema != nil
      assert Keyword.get(style_schema, :type) == :keyword_list
    end

    test "has visible option with default" do
      entity = LayoutEntities.hbox_entity()

      visible_schema = Keyword.get(entity.schema, :visible)
      assert visible_schema != nil
      assert Keyword.get(visible_schema, :default) == true
    end
  end

  describe "IUR Layout Structs" do
    test "VBox struct can be created with all fields" do
      vbox = %Layouts.VBox{
        id: :main,
        children: [],
        spacing: 2,
        align_items: :center,
        justify_content: :space_between,
        padding: 1,
        style: %UnifiedIUR.Style{fg: :blue},
        visible: true
      }

      assert vbox.id == :main
      assert vbox.spacing == 2
      assert vbox.align_items == :center
      assert vbox.justify_content == :space_between
      assert vbox.padding == 1
      assert match?(%UnifiedIUR.Style{}, vbox.style)
      assert vbox.visible == true
    end

    test "VBox struct has correct defaults" do
      vbox = %Layouts.VBox{}

      assert vbox.id == nil
      assert vbox.children == []
      assert vbox.spacing == 0
      assert vbox.align_items == nil
      assert vbox.justify_content == nil
      assert vbox.padding == nil
      assert vbox.style == nil
      assert vbox.visible == true
    end

    test "HBox struct can be created with all fields" do
      hbox = %Layouts.HBox{
        id: :row,
        children: [],
        spacing: 3,
        align_items: :center,
        justify_content: :space_around,
        padding: 2,
        style: %UnifiedIUR.Style{bg: :white},
        visible: true
      }

      assert hbox.id == :row
      assert hbox.spacing == 3
      assert hbox.align_items == :center
      assert hbox.justify_content == :space_around
      assert hbox.padding == 2
      assert match?(%UnifiedIUR.Style{}, hbox.style)
      assert hbox.visible == true
    end

    test "HBox struct has correct defaults" do
      hbox = %Layouts.HBox{}

      assert hbox.id == nil
      assert hbox.children == []
      assert hbox.spacing == 0
      assert hbox.align_items == nil
      assert hbox.justify_content == nil
      assert hbox.padding == nil
      assert hbox.style == nil
      assert hbox.visible == true
    end

    test "VBox supports all align_items values" do
      for align <- [:start, :center, :end, :stretch] do
        vbox = %Layouts.VBox{align_items: align}
        assert vbox.align_items == align
      end
    end

    test "VBox supports all justify_content values" do
      for justify <- [:start, :center, :end, :stretch, :space_between, :space_around] do
        vbox = %Layouts.VBox{justify_content: justify}
        assert vbox.justify_content == justify
      end
    end

    test "HBox supports all align_items values" do
      for align <- [:start, :center, :end, :stretch] do
        hbox = %Layouts.HBox{align_items: align}
        assert hbox.align_items == align
      end
    end

    test "HBox supports all justify_content values" do
      for justify <- [:start, :center, :end, :stretch, :space_between, :space_around] do
        hbox = %Layouts.HBox{justify_content: justify}
        assert hbox.justify_content == justify
      end
    end
  end

  describe "Entity Descriptions" do
    test "vbox_entity has a description" do
      entity = LayoutEntities.vbox_entity()
      assert is_binary(entity.describe)
      assert String.length(entity.describe) > 0
    end

    test "hbox_entity has a description" do
      entity = LayoutEntities.hbox_entity()
      assert is_binary(entity.describe)
      assert String.length(entity.describe) > 0
    end
  end

  describe "Entity Args" do
    test "vbox_entity has no positional args" do
      entity = LayoutEntities.vbox_entity()
      assert entity.args == []
    end

    test "hbox_entity has no positional args" do
      entity = LayoutEntities.hbox_entity()
      assert entity.args == []
    end
  end
end
