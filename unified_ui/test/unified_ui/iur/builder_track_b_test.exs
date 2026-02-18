defmodule UnifiedUi.IUR.BuilderTrackBTest do
  use ExUnit.Case, async: true

  alias UnifiedUi.IUR.Builder
  alias UnifiedIUR.Widgets

  describe "Track B builder coverage" do
    test "build/1 skips non-render entities and selects first buildable entity" do
      dsl_state = %{
        [:ui] => %{
          entities: [
            %{name: :state, attrs: %{attrs: [count: 0]}},
            %{name: :gauge, attrs: %{id: :cpu, value: 72, min: 0, max: 100}}
          ]
        }
      }

      assert %Widgets.Gauge{id: :cpu, value: 72} = Builder.build(dsl_state)
    end

    test "builds data visualization entities" do
      gauge =
        Builder.build_entity(
          %{name: :gauge, attrs: %{id: :cpu, value: 72, min: 0, max: 100}},
          %{}
        )

      sparkline =
        Builder.build_entity(
          %{name: :sparkline, attrs: %{id: :mem, data: [1, 2, 3], show_dots: true}},
          %{}
        )

      bar_chart =
        Builder.build_entity(
          %{name: :bar_chart, attrs: %{id: :sales, data: [{"Mon", 1}], orientation: :vertical}},
          %{}
        )

      line_chart =
        Builder.build_entity(
          %{name: :line_chart, attrs: %{id: :latency, data: [{"P99", 30}], show_dots: true}},
          %{}
        )

      assert %Widgets.Gauge{id: :cpu, value: 72, min: 0, max: 100} = gauge
      assert %Widgets.Sparkline{id: :mem, data: [1, 2, 3], show_dots: true} = sparkline
      assert %Widgets.BarChart{id: :sales, orientation: :vertical} = bar_chart
      assert %Widgets.LineChart{id: :latency, show_dots: true} = line_chart
    end

    test "builds table with nested column entities" do
      table_entity = %{
        name: :table,
        attrs: %{id: :users, data: [%{id: 1, name: "Alice"}], sort_direction: :desc},
        entities: [
          %{
            name: :columns,
            entities: [
              %{name: :column, attrs: %{key: :id, header: "ID", align: :right, width: 4}},
              %{name: :column, attrs: %{key: :name, header: "Name", sortable: true}}
            ]
          }
        ]
      }

      table = Builder.build_entity(table_entity, %{})

      assert %Widgets.Table{id: :users, sort_direction: :desc} = table
      assert [%Widgets.Column{key: :id}, %Widgets.Column{key: :name}] = table.columns

      [id_col, name_col] = table.columns
      assert id_col.header == "ID"
      assert id_col.align == :right
      assert id_col.width == 4
      assert name_col.header == "Name"
      assert name_col.sortable == true
    end

    test "builds navigation entities and nested collections" do
      menu =
        Builder.build_entity(
          %{
            name: :menu,
            attrs: %{id: :main_menu, title: "Main", position: :top},
            entities: [
              %{
                name: :menu_items,
                entities: [
                  %{name: :menu_item, attrs: %{label: "Open", action: :open}},
                  %{name: :menu_item, attrs: %{label: "Save", action: :save}}
                ]
              }
            ]
          },
          %{}
        )

      context_menu =
        Builder.build_entity(
          %{
            name: :context_menu,
            attrs: %{id: :editor_context, trigger_on: :right_click},
            entities: [
              %{
                name: :items,
                entities: [
                  %{name: :menu_item, attrs: %{label: "Copy", action: :copy}},
                  %{name: :menu_item, attrs: %{label: "Paste", action: :paste}}
                ]
              }
            ]
          },
          %{}
        )

      tabs =
        Builder.build_entity(
          %{
            name: :tabs,
            attrs: %{id: :workspace_tabs, active_tab: :home, on_change: :tab_changed},
            entities: [
              %{
                name: :tabs,
                entities: [
                  %{name: :tab, attrs: %{id: :home, label: "Home"}},
                  %{name: :tab, attrs: %{id: :files, label: "Files"}}
                ]
              }
            ]
          },
          %{}
        )

      tree_view =
        Builder.build_entity(
          %{
            name: :tree_view,
            attrs: %{id: :project_tree, selected_node: :readme, on_select: :node_selected},
            entities: [
              %{
                name: :root_nodes,
                entities: [
                  %{name: :tree_node, attrs: %{id: :readme, label: "README.md"}},
                  %{name: :tree_node, attrs: %{id: :mix, label: "mix.exs"}}
                ]
              }
            ]
          },
          %{}
        )

      assert %Widgets.Menu{id: :main_menu, title: "Main", position: :top} = menu
      assert [%Widgets.MenuItem{label: "Open"}, %Widgets.MenuItem{label: "Save"}] = menu.items

      assert %Widgets.ContextMenu{id: :editor_context, trigger_on: :right_click} = context_menu

      assert [%Widgets.MenuItem{label: "Copy"}, %Widgets.MenuItem{label: "Paste"}] =
               context_menu.items

      assert %Widgets.Tabs{id: :workspace_tabs, active_tab: :home, on_change: :tab_changed} = tabs

      assert [%Widgets.Tab{id: :home, label: "Home"}, %Widgets.Tab{id: :files, label: "Files"}] =
               tabs.tabs

      assert %Widgets.TreeView{
               id: :project_tree,
               selected_node: :readme,
               on_select: :node_selected
             } = tree_view

      assert [%Widgets.TreeNode{id: :readme, label: "README.md"}, %Widgets.TreeNode{id: :mix}] =
               tree_view.root_nodes
    end
  end
end
