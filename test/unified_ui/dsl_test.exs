defmodule UnifiedUi.DslTest do
  @moduledoc """
  Tests for the UnifiedUi.Dsl module.
  """

  use ExUnit.Case, async: false

  alias UnifiedIUR.{Layouts, Widgets}
  alias UnifiedUi.Dsl

  describe "DSL module compilation" do
    test "DSL module exists and is loadable" do
      assert Code.ensure_loaded?(Dsl)
    end

    test "DSL module has correct metadata" do
      {:module, _} = Code.ensure_loaded(Dsl)
      # __using__ is a macro, not a function, so it won't be in function_exported?
      # Just check that standard_signals delegate exists
      assert function_exported?(Dsl, :standard_signals, 0)
    end
  end

  describe "module fixtures using UnifiedUi.Dsl" do
    test "supports nested layout and widget DSL macros in a compiled module" do
      module = unique_fixture_module(:basic_layout)

      compile_fixture(
        module,
        """
        vbox do
          id :root
          spacing 1
          text "Hello", id: :hello

          hbox do
            id :row
            button "Go", id: :go_btn, on_click: :go
          end
        end
        """
      )

      assert function_exported?(module, :view, 1)

      assert %Layouts.VBox{id: :root, spacing: 1, children: [title, row]} = module.view(%{})
      assert %Widgets.Text{id: :hello, content: "Hello"} = title
      assert %Layouts.HBox{id: :row, children: [button]} = row
      assert %Widgets.Button{id: :go_btn, label: "Go", on_click: :go} = button
    end

    test "supports tab content and recursive tree nodes in compiled modules" do
      module = unique_fixture_module(:navigation)

      compile_fixture(
        module,
        """
        vbox do
          id :nav_root

          tabs :workspace_tabs do
            active_tab :home

            tab :home, "Home" do
              text "Home content", id: :home_text
            end
          end

          tree_view :project_tree do
            selected_node :root

            tree_node :root, "root"
          end
        end
        """
      )

      assert function_exported?(module, :view, 1)

      assert %Layouts.VBox{id: :nav_root, children: [tabs, tree]} = module.view(%{})

      assert %Widgets.Tabs{id: :workspace_tabs, active_tab: :home, tabs: [home_tab]} = tabs

      assert %Widgets.Tab{id: :home, label: "Home", content: [home_text]} = home_tab
      assert %Widgets.Text{id: :home_text} = home_text

      assert %Widgets.TreeView{id: :project_tree, selected_node: :root, root_nodes: [root_node]} =
               tree

      assert %Widgets.TreeNode{id: :root, label: "root", children: nil} = root_node
    end
  end

  describe "standard_signals" do
    test "standard_signals returns expected list" do
      signals = Dsl.standard_signals()
      assert is_list(signals)
      assert :click in signals
      assert :change in signals
      assert :submit in signals
    end
  end

  defp unique_fixture_module(tag) do
    Module.concat([UnifiedUi, DslFixture, tag, :"M#{System.unique_integer([:positive])}"])
  end

  defp compile_fixture(module, body) do
    source = """
    defmodule #{inspect(module)} do
      @behaviour UnifiedUi.ElmArchitecture
      use UnifiedUi.Dsl

      #{body}
    end
    """

    Code.compile_string(source)
    module
  end
end
