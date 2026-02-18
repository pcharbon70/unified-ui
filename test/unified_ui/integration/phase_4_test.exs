defmodule UnifiedUi.Integration.Phase4Test do
  @moduledoc """
  Integration tests for Phase 4 of UnifiedUi.

  These tests verify that navigation widgets (Menu, ContextMenu, Tabs, TreeView)
  work correctly with the IUR system and all three platform adapters.

  Test Sections:
  - 4.3.1: Menu system with nested items
  - 4.3.2: Context menu triggering
  - 4.3.3: Tabs with content switching
  - 4.3.4: Tree view with expand/collapse
  - 4.3.5: Complex navigation UI
  """

  use ExUnit.Case, async: false

  alias UnifiedIUR.{Layouts, Widgets}
  alias UnifiedUi.Adapters.{Terminal, Desktop, Web}

  # ============================================================================
  # 4.3.1: Menu System Tests
  # ============================================================================

  describe "4.3.1 - Menu System" do
    test "Menu with items renders correctly" do
      menu = %Widgets.Menu{
        id: :file_menu,
        title: "File",
        position: :top,
        items: [
          %Widgets.MenuItem{label: "New", action: :new_file, shortcut: "Ctrl+N"},
          %Widgets.MenuItem{label: "Open", action: :open_file, shortcut: "Ctrl+O"},
          %Widgets.MenuItem{label: "Save", action: :save_file, shortcut: "Ctrl+S", disabled: true}
        ]
      }

      # Terminal renderer
      assert {:ok, terminal_state} = Terminal.render(menu)
      assert {:ok, _root} = UnifiedUi.Adapters.State.get_root(terminal_state)

      # Desktop renderer
      assert {:ok, desktop_state} = Desktop.render(menu)
      assert {:ok, _root} = UnifiedUi.Adapters.State.get_root(desktop_state)

      # Web renderer
      assert {:ok, web_state} = Web.render(menu)
      assert {:ok, _root} = UnifiedUi.Adapters.State.get_root(web_state)
    end

    test "Menu with nested submenu items" do
      menu = %Widgets.Menu{
        id: :main_menu,
        items: [
          %Widgets.MenuItem{
            label: "File",
            action: :file_menu,
            submenu: [
              %Widgets.MenuItem{label: "New", action: :new},
              %Widgets.MenuItem{label: "Open", action: :open}
            ]
          },
          %Widgets.MenuItem{
            label: "Edit",
            action: :edit_menu,
            submenu: [
              %Widgets.MenuItem{label: "Undo", action: :undo},
              %Widgets.MenuItem{label: "Redo", action: :redo}
            ]
          }
        ]
      }

      # Verify menu structure
      assert length(menu.items) == 2
      file_item = Enum.at(menu.items, 0)
      assert file_item.submenu != nil
      assert length(file_item.submenu) == 2

      # Terminal renderer
      assert {:ok, _state} = Terminal.render(menu)

      # Desktop renderer
      assert {:ok, _state} = Desktop.render(menu)

      # Web renderer
      assert {:ok, _state} = Web.render(menu)
    end

    test "Menu with icons and shortcuts displays correctly" do
      menu = %Widgets.Menu{
        id: :icon_menu,
        items: [
          %Widgets.MenuItem{
            label: "Save",
            action: :save,
            icon: :floppy,
            shortcut: "Ctrl+S"
          },
          %Widgets.MenuItem{
            label: "Print",
            action: :print,
            icon: :printer,
            shortcut: "Ctrl+P"
          }
        ]
      }

      # Verify item properties
      save_item = Enum.at(menu.items, 0)
      assert save_item.icon == :floppy
      assert save_item.shortcut == "Ctrl+S"

      # All renderers
      assert {:ok, _} = Terminal.render(menu)
      assert {:ok, _} = Desktop.render(menu)
      assert {:ok, _} = Web.render(menu)
    end
  end

  # ============================================================================
  # 4.3.2: Context Menu Tests
  # ============================================================================

  describe "4.3.2 - Context Menu" do
    test "Context menu with right-click trigger" do
      menu = %Widgets.ContextMenu{
        id: :text_context,
        trigger_on: :right_click,
        items: [
          %Widgets.MenuItem{label: "Copy", action: :copy},
          %Widgets.MenuItem{label: "Paste", action: :paste},
          %Widgets.MenuItem{label: "Cut", action: :cut}
        ]
      }

      assert menu.trigger_on == :right_click
      assert length(menu.items) == 3

      # All renderers
      assert {:ok, _} = Terminal.render(menu)
      assert {:ok, _} = Desktop.render(menu)
      assert {:ok, _} = Web.render(menu)
    end

    test "Context menu with long-press trigger" do
      menu = %Widgets.ContextMenu{
        id: :touch_context,
        trigger_on: :long_press,
        items: [
          %Widgets.MenuItem{label: "Select All", action: :select_all}
        ]
      }

      assert menu.trigger_on == :long_press

      # All renderers
      assert {:ok, _} = Terminal.render(menu)
      assert {:ok, _} = Desktop.render(menu)
      assert {:ok, _} = Web.render(menu)
    end

    test "Context menu with double-click trigger" do
      menu = %Widgets.ContextMenu{
        id: :double_click_context,
        trigger_on: :double_click,
        items: []
      }

      assert menu.trigger_on == :double_click

      # All renderers
      assert {:ok, _} = Terminal.render(menu)
      assert {:ok, _} = Desktop.render(menu)
      assert {:ok, _} = Web.render(menu)
    end
  end

  # ============================================================================
  # 4.3.3: Tabs System Tests
  # ============================================================================

  describe "4.3.3 - Tabs System" do
    test "Tabs with active tab selection" do
      tabs = %Widgets.Tabs{
        id: :main_tabs,
        active_tab: :home,
        position: :top,
        on_change: :tab_changed,
        tabs: [
          %Widgets.Tab{id: :home, label: "Home", content: %Widgets.Text{content: "Home Page"}},
          %Widgets.Tab{id: :about, label: "About", content: %Widgets.Text{content: "About Page"}},
          %Widgets.Tab{id: :contact, label: "Contact", content: %Widgets.Text{content: "Contact Page"}}
        ]
      }

      assert tabs.active_tab == :home
      assert length(tabs.tabs) == 3

      # All renderers
      assert {:ok, _} = Terminal.render(tabs)
      assert {:ok, _} = Desktop.render(tabs)
      assert {:ok, _} = Web.render(tabs)
    end

    test "Tabs with side position" do
      tabs = %Widgets.Tabs{
        id: :side_tabs,
        active_tab: :tab1,
        position: :left,
        tabs: [
          %Widgets.Tab{id: :tab1, label: "Section 1", content: %Widgets.Text{content: "Content 1"}},
          %Widgets.Tab{id: :tab2, label: "Section 2", content: %Widgets.Text{content: "Content 2"}}
        ]
      }

      assert tabs.position == :left

      # All renderers
      assert {:ok, _} = Terminal.render(tabs)
      assert {:ok, _} = Desktop.render(tabs)
      assert {:ok, _} = Web.render(tabs)
    end

    test "Tabs with icons" do
      tabs = %Widgets.Tabs{
        id: :icon_tabs,
        active_tab: :dashboard,
        tabs: [
          %Widgets.Tab{id: :dashboard, label: "Dashboard", icon: :chart},
          %Widgets.Tab{id: :settings, label: "Settings", icon: :gear},
          %Widgets.Tab{id: :profile, label: "Profile", icon: :user}
        ]
      }

      # Verify tab icons
      dashboard_tab = Enum.at(tabs.tabs, 0)
      assert dashboard_tab.icon == :chart

      # All renderers
      assert {:ok, _} = Terminal.render(tabs)
      assert {:ok, _} = Desktop.render(tabs)
      assert {:ok, _} = Web.render(tabs)
    end

    test "Tabs with disabled and closable tabs" do
      tabs = %Widgets.Tabs{
        id: :mixed_tabs,
        active_tab: :tab1,
        tabs: [
          %Widgets.Tab{id: :tab1, label: "Normal Tab"},
          %Widgets.Tab{id: :tab2, label: "Disabled Tab", disabled: true},
          %Widgets.Tab{id: :tab3, label: "Closable Tab", closable: true}
        ]
      }

      # Verify tab properties
      tab2 = Enum.at(tabs.tabs, 1)
      assert tab2.disabled == true

      tab3 = Enum.at(tabs.tabs, 2)
      assert tab3.closable == true

      # All renderers
      assert {:ok, _} = Terminal.render(tabs)
      assert {:ok, _} = Desktop.render(tabs)
      assert {:ok, _} = Web.render(tabs)
    end

    test "Tabs with nested content" do
      tabs = %Widgets.Tabs{
        id: :nested_tabs,
        active_tab: :form_tab,
        tabs: [
          %Widgets.Tab{
            id: :form_tab,
            label: "Form",
            content: %Layouts.VBox{
              spacing: 1,
              children: [
                %Widgets.Label{text: "Name:", for: :name_input},
                %Widgets.TextInput{id: :name_input, placeholder: "Enter name"},
                %Widgets.Button{label: "Submit", on_click: :submit}
              ]
            }
          }
        ]
      }

      # Verify nested structure
      form_tab = Enum.at(tabs.tabs, 0)
      assert %Layouts.VBox{} = form_tab.content
      assert length(form_tab.content.children) == 3

      # All renderers
      assert {:ok, _} = Terminal.render(tabs)
      assert {:ok, _} = Desktop.render(tabs)
      assert {:ok, _} = Web.render(tabs)
    end
  end

  # ============================================================================
  # 4.3.4: Tree View Tests
  # ============================================================================

  describe "4.3.4 - Tree View" do
    test "Tree view with simple structure" do
      tree = %Widgets.TreeView{
        id: :file_tree,
        root_nodes: [
          %Widgets.TreeNode{id: :src, label: "src"},
          %Widgets.TreeNode{id: :test, label: "test"}
        ]
      }

      assert length(tree.root_nodes) == 2

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end

    test "Tree view with nested nodes" do
      tree = %Widgets.TreeView{
        id: :project_tree,
        root_nodes: [
          %Widgets.TreeNode{
            id: :lib,
            label: "lib",
            expanded: true,
            children: [
              %Widgets.TreeNode{
                id: :my_app,
                label: "my_app",
                expanded: true,
                children: [
                  %Widgets.TreeNode{id: :app, label: "app.ex"},
                  %Widgets.TreeNode{id: :application, label: "application.ex"}
                ]
              }
            ]
          }
        ]
      }

      # Verify nested structure
      lib_node = Enum.at(tree.root_nodes, 0)
      assert lib_node.expanded == true
      assert length(lib_node.children) == 1

      my_app_node = Enum.at(lib_node.children, 0)
      assert length(my_app_node.children) == 2

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end

    test "Tree view with selection" do
      tree = %Widgets.TreeView{
        id: :selectable_tree,
        selected_node: :node2,
        on_select: :node_selected,
        root_nodes: [
          %Widgets.TreeNode{id: :node1, label: "Node 1"},
          %Widgets.TreeNode{id: :node2, label: "Node 2"},
          %Widgets.TreeNode{id: :node3, label: "Node 3"}
        ]
      }

      assert tree.selected_node == :node2
      assert tree.on_select == :node_selected

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end

    test "Tree view with toggle handlers" do
      tree = %Widgets.TreeView{
        id: :toggle_tree,
        on_toggle: :node_toggled,
        root_nodes: [
          %Widgets.TreeNode{
            id: :parent,
            label: "Parent",
            children: [
              %Widgets.TreeNode{id: :child, label: "Child"}
            ]
          }
        ]
      }

      assert tree.on_toggle == :node_toggled

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end

    test "Tree view with icons" do
      tree = %Widgets.TreeView{
        id: :icon_tree,
        root_nodes: [
          %Widgets.TreeNode{
            id: :folder,
            label: "My Folder",
            icon: :folder,
            icon_expanded: :folder_open,
            expanded: true,
            children: [
              %Widgets.TreeNode{id: :file, label: "file.txt", icon: :document}
            ]
          }
        ]
      }

      # Verify icons
      folder_node = Enum.at(tree.root_nodes, 0)
      assert folder_node.icon == :folder
      assert folder_node.icon_expanded == :folder_open

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end

    test "Tree view with non-selectable nodes" do
      tree = %Widgets.TreeView{
        id: :mixed_selectable,
        root_nodes: [
          %Widgets.TreeNode{id: :selectable, label: "Can Select", selectable: true},
          %Widgets.TreeNode{id: :readonly, label: "Read Only", selectable: false}
        ]
      }

      readonly_node = Enum.at(tree.root_nodes, 1)
      assert readonly_node.selectable == false

      # All renderers
      assert {:ok, _} = Terminal.render(tree)
      assert {:ok, _} = Desktop.render(tree)
      assert {:ok, _} = Web.render(tree)
    end
  end

  # ============================================================================
  # 4.3.5: Complex Navigation UI
  # ============================================================================

  describe "4.3.5 - Complex Navigation UI" do
    test "Full application layout with all navigation widgets" do
      ui = %Layouts.VBox{
        id: :app_layout,
        spacing: 1,
        children: [
          # Menu bar
          %Widgets.Menu{
            id: :menu_bar,
            position: :top,
            items: [
              %Widgets.MenuItem{label: "File", action: :file_menu},
              %Widgets.MenuItem{label: "Edit", action: :edit_menu},
              %Widgets.MenuItem{label: "View", action: :view_menu}
            ]
          },
          # Tabs container
          %Widgets.Tabs{
            id: :main_tabs,
            active_tab: :dashboard,
            tabs: [
              %Widgets.Tab{
                id: :dashboard,
                label: "Dashboard",
                content: %Widgets.Text{content: "Dashboard content"}
              },
              %Widgets.Tab{
                id: :files,
                label: "Files",
                content: %Widgets.TreeView{
                  id: :file_browser,
                  root_nodes: [
                    %Widgets.TreeNode{
                      id: :documents,
                      label: "Documents",
                      children: [
                        %Widgets.TreeNode{id: :doc1, label: "Report.txt"}
                      ]
                    }
                  ]
                }
              }
            ]
          },
          # Status bar
          %Widgets.Text{content: "Ready", id: :status}
        ]
      }

      # Verify structure
      assert length(ui.children) == 3

      menu = Enum.at(ui.children, 0)
      assert %Widgets.Menu{} = menu

      tabs = Enum.at(ui.children, 1)
      assert %Widgets.Tabs{} = tabs

      # All renderers
      assert {:ok, terminal_state} = Terminal.render(ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(terminal_state)

      assert {:ok, desktop_state} = Desktop.render(ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(desktop_state)

      assert {:ok, web_state} = Web.render(ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(web_state)
    end

    test "Split pane with tree and context menu" do
      ui = %Layouts.HBox{
        id: :split_view,
        spacing: 2,
        children: [
          # Left panel: tree view
          %Widgets.TreeView{
            id: :nav_tree,
            root_nodes: [
              %Widgets.TreeNode{
                id: :root,
                label: "Root",
                expanded: true,
                children: [
                  %Widgets.TreeNode{id: :branch1, label: "Branch 1"},
                  %Widgets.TreeNode{id: :branch2, label: "Branch 2"}
                ]
              }
            ]
          },
          # Right panel: content with context menu
          %Layouts.VBox{
            children: [
              %Widgets.Text{content: "Content area"},
              %Widgets.ContextMenu{
                id: :content_context,
                items: [
                  %Widgets.MenuItem{label: "Copy", action: :copy},
                  %Widgets.MenuItem{label: "Paste", action: :paste}
                ]
              }
            ]
          }
        ]
      }

      # Verify structure
      assert length(ui.children) == 2

      # All renderers
      assert {:ok, _} = Terminal.render(ui)
      assert {:ok, _} = Desktop.render(ui)
      assert {:ok, _} = Web.render(ui)
    end

    test "Tab bar with all navigation features combined" do
      ui = %Widgets.Tabs{
        id: :full_nav,
        active_tab: :home,
        position: :top,
        tabs: [
          %Widgets.Tab{
            id: :home,
            label: "Home",
            icon: :house,
            content: %Layouts.VBox{
              children: [
                %Widgets.Menu{
                  id: :home_menu,
                  items: [
                    %Widgets.MenuItem{label: "Refresh", action: :refresh}
                  ]
                },
                %Widgets.Text{content: "Home content"}
              ]
            }
          },
          %Widgets.Tab{
            id: :settings,
            label: "Settings",
            icon: :gear,
            closable: true,
            content: %Widgets.TreeView{
              id: :settings_tree,
              root_nodes: [
                %Widgets.TreeNode{
                  id: :general,
                  label: "General",
                  children: [
                    %Widgets.TreeNode{id: :appearance, label: "Appearance"}
                  ]
                }
              ]
            }
          }
        ]
      }

      # Verify complex nesting
      home_tab = Enum.at(ui.tabs, 0)
      assert %Layouts.VBox{} = home_tab.content

      settings_tab = Enum.at(ui.tabs, 1)
      assert settings_tab.closable == true
      assert %Widgets.TreeView{} = settings_tab.content

      # All renderers
      assert {:ok, _} = Terminal.render(ui)
      assert {:ok, _} = Desktop.render(ui)
      assert {:ok, _} = Web.render(ui)
    end
  end

  # ============================================================================
  # Cross-Platform Rendering Parity
  # ============================================================================

  describe "Cross-Platform Rendering" do
    test "All navigation widgets render on all platforms" do
      widgets = [
        %Widgets.Menu{id: :test_menu, items: [%Widgets.MenuItem{label: "Test"}]},
        %Widgets.ContextMenu{id: :test_ctx, items: []},
        %Widgets.Tabs{id: :test_tabs, tabs: [%Widgets.Tab{id: :t1, label: "T1"}]},
        %Widgets.TreeView{id: :test_tree, root_nodes: [%Widgets.TreeNode{id: :n1, label: "N1"}]}
      ]

      Enum.each(widgets, fn widget ->
        assert {:ok, _} = Terminal.render(widget)
        assert {:ok, _} = Desktop.render(widget)
        assert {:ok, _} = Web.render(widget)
      end)
    end

    test "Complex nested navigation renders on all platforms" do
      complex_ui = %Layouts.VBox{
        children: [
          %Widgets.Menu{
            id: :top_menu,
            items: [
              %Widgets.MenuItem{
                label: "File",
                submenu: [
                  %Widgets.MenuItem{label: "New", action: :new}
                ]
              }
            ]
          },
          %Widgets.Tabs{
            id: :main_tabs,
            active_tab: :tab1,
            tabs: [
              %Widgets.Tab{
                id: :tab1,
                label: "Tab 1",
                content: %Widgets.TreeView{
                  id: :tab1_tree,
                  root_nodes: [
                    %Widgets.TreeNode{
                      id: :root,
                      label: "Root",
                      children: [
                        %Widgets.TreeNode{id: :child1, label: "Child 1"}
                      ]
                    }
                  ]
                }
              }
            ]
          }
        ]
      }

      # All platforms should handle the complex nested structure
      assert {:ok, terminal_state} = Terminal.render(complex_ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(terminal_state)

      assert {:ok, desktop_state} = Desktop.render(complex_ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(desktop_state)

      assert {:ok, web_state} = Web.render(complex_ui)
      assert {:ok, _} = UnifiedUi.Adapters.State.get_root(web_state)
    end
  end
end
