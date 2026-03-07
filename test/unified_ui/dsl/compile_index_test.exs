defmodule UnifiedUi.Dsl.CompileIndexTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Transformer
  alias UnifiedUi.Dsl.CompileIndex
  alias UnifiedUi.Dsl.Transformers.PrecomputeTransformer

  describe "build/1" do
    test "collects section entities and flattens nested children" do
      nested_child = %{name: :text, attrs: %{id: :child_text}}

      widget = %{
        name: :button,
        attrs: %{id: :save_btn, on_click: :save},
        entities: [nested_child]
      }

      layout = %{name: :vbox, attrs: %{id: :root_layout}, entities: [widget]}
      state = %{attrs: [count: 0]}

      dsl_state = %{
        :widgets => %{entities: [widget]},
        :layouts => %{entities: [layout]},
        [:ui] => %{entities: [layout]},
        [:ui, :state] => %{entities: [state]}
      }

      index = CompileIndex.build(dsl_state)

      assert index.widgets == [widget]
      assert index.layouts == [layout]
      assert index.ui == [layout]
      assert index.state == [state]

      assert layout in index.flat
      assert widget in index.flat
      assert nested_child in index.flat
    end

    test "falls back to nested ui map for state entities" do
      state = %{attrs: [count: 1, ready: true]}

      dsl_state = %{
        ui: %{
          entities: [%{name: :vbox, attrs: %{id: :root}}],
          state: %{entities: [state]}
        }
      }

      index = CompileIndex.build(dsl_state)

      assert index.state == [state]
      assert [%{name: :vbox}] = index.ui
    end
  end

  describe "persist/1 and get/1" do
    test "stores and retrieves compile index from dsl persist data" do
      dsl_state = %{
        widgets: %{entities: [%{name: :button, attrs: %{id: :save_btn}}]}
      }

      indexed_dsl_state = CompileIndex.persist(dsl_state)

      expected_index = CompileIndex.build(dsl_state)

      assert Transformer.get_persisted(indexed_dsl_state, :unified_ui_compile_index) ==
               expected_index

      assert CompileIndex.get(indexed_dsl_state) == expected_index
    end
  end

  describe "PrecomputeTransformer" do
    test "persists compile index during transformer pass" do
      dsl_state = %{
        :widgets => %{entities: [%{name: :button, attrs: %{id: :save_btn}}]},
        [:ui] => %{entities: [%{name: :vbox, attrs: %{id: :root}}]}
      }

      assert {:ok, indexed_dsl_state} = PrecomputeTransformer.transform(dsl_state)

      assert %{} = Transformer.get_persisted(indexed_dsl_state, :unified_ui_compile_index)
      assert CompileIndex.get(indexed_dsl_state) == CompileIndex.build(dsl_state)
    end
  end
end
