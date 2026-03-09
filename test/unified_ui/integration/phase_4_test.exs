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
  - 4.3.5: Keyboard navigation signals
  - 4.3.6: Complex navigation UI
  """

  use ExUnit.Case, async: false

  alias UnifiedUi.Dsl.Style, as: DslStyle
  alias UnifiedUi.Dsl.Theme, as: DslTheme
  alias UnifiedIUR.{Layouts, Widgets}
  alias UnifiedUi.Adapters.{Terminal, Desktop, Web}
  alias UnifiedUi.IUR.Builder

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
          %Widgets.Tab{
            id: :contact,
            label: "Contact",
            content: %Widgets.Text{content: "Contact Page"}
          }
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
          %Widgets.Tab{
            id: :tab1,
            label: "Section 1",
            content: %Widgets.Text{content: "Content 1"}
          },
          %Widgets.Tab{
            id: :tab2,
            label: "Section 2",
            content: %Widgets.Text{content: "Content 2"}
          }
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
  # 4.3.5: Keyboard Navigation
  # ============================================================================

  describe "4.3.5 - Keyboard Navigation" do
    test "navigation keys map to normalized actions across adapters" do
      adapter_platforms = [
        {Terminal.Events, :terminal},
        {Desktop.Events, :desktop},
        {Web.Events, :web}
      ]

      Enum.each(adapter_platforms, fn {events_module, platform} ->
        assert {:ok, signal} = events_module.navigation_key(:main_tabs, :right)
        assert signal.type == "unified.key.pressed"
        assert signal.data.widget_id == :main_tabs
        assert signal.data.key == :right
        assert signal.data.action == :navigate_right
        assert signal.data.platform == platform
      end)
    end

    test "activation and dismiss keys map consistently for navigation widgets" do
      adapter_platforms = [
        {Terminal.Events, :terminal},
        {Desktop.Events, :desktop},
        {Web.Events, :web}
      ]

      Enum.each(adapter_platforms, fn {events_module, platform} ->
        assert {:ok, activate_signal} = events_module.navigation_key(:main_menu, :enter)
        assert activate_signal.data.action == :activate
        assert activate_signal.data.platform == platform

        assert {:ok, dismiss_signal} = events_module.navigation_key(:context_menu, :escape)
        assert dismiss_signal.data.action == :dismiss
        assert dismiss_signal.data.platform == platform
      end)
    end
  end

  # ============================================================================
  # 4.3.6: Complex Navigation UI
  # ============================================================================

  describe "4.3.6 - Complex Navigation UI" do
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
  # 4.4: Dialog and Feedback Widgets
  # ============================================================================

  describe "4.4 - Dialog and Feedback Widgets" do
    test "Dialog with nested content and close signal" do
      dialog = %Widgets.Dialog{
        id: :settings_dialog,
        title: "Settings",
        content: %Layouts.VBox{
          spacing: 1,
          children: [
            %Widgets.Text{content: "Update settings"},
            %Widgets.TextInput{id: :name, placeholder: "Name"}
          ]
        },
        on_close: :close_settings,
        buttons: [
          %Widgets.DialogButton{label: "Cancel", action: :close_settings, role: :cancel},
          %Widgets.DialogButton{label: "Save", action: :save_settings, role: :confirm}
        ]
      }

      assert dialog.on_close == :close_settings
      assert length(dialog.buttons) == 2

      assert {:ok, _} = Terminal.render(dialog)
      assert {:ok, _} = Desktop.render(dialog)
      assert {:ok, _} = Web.render(dialog)
    end

    test "Modal behavior marks background as blocked across adapters" do
      modal_dialog = %Widgets.Dialog{
        id: :blocking_dialog,
        title: "Blocking Dialog",
        content: "Modal content",
        modal: true
      }

      non_modal_dialog = %Widgets.Dialog{
        id: :non_blocking_dialog,
        title: "Non-Blocking Dialog",
        content: "Overlay content",
        modal: false
      }

      assert {:dialog, _node, terminal_modal_meta} = Terminal.convert_iur(modal_dialog)
      assert terminal_modal_meta.blocks_background == true

      assert {:dialog, _node, terminal_non_modal_meta} = Terminal.convert_iur(non_modal_dialog)
      assert terminal_non_modal_meta.blocks_background == false

      assert {:dialog, desktop_modal_widget, desktop_modal_meta} =
               Desktop.convert_iur(modal_dialog)

      assert desktop_modal_meta.blocks_background == true
      assert desktop_modal_widget.props[:blocks_background] == true

      assert {:dialog, desktop_non_modal_widget, desktop_non_modal_meta} =
               Desktop.convert_iur(non_modal_dialog)

      assert desktop_non_modal_meta.blocks_background == false
      assert desktop_non_modal_widget.props[:blocks_background] == false

      modal_html = Web.convert_iur(modal_dialog)
      non_modal_html = Web.convert_iur(non_modal_dialog)

      assert modal_html =~ "data-blocks-background=\"true\""
      assert non_modal_html =~ "data-blocks-background=\"false\""
    end

    test "Alert dialog severity metadata is preserved" do
      alert = %Widgets.AlertDialog{
        id: :delete_alert,
        title: "Delete Item",
        message: "This action cannot be undone.",
        severity: :warning,
        on_confirm: :confirm_delete,
        on_cancel: :cancel_delete
      }

      assert alert.severity == :warning
      assert alert.on_confirm == :confirm_delete
      assert alert.on_cancel == :cancel_delete

      assert {:ok, _} = Terminal.render(alert)
      assert {:ok, _} = Desktop.render(alert)
      assert {:ok, _} = Web.render(alert)
    end

    test "Toast auto-dismiss metadata is generated when duration is positive" do
      toast = %Widgets.Toast{
        id: :save_toast,
        message: "Saved successfully",
        severity: :success,
        duration: 1500,
        on_dismiss: :dismiss_save_toast
      }

      assert toast.duration == 1500
      assert toast.on_dismiss == :dismiss_save_toast

      assert {:toast, _node, terminal_meta} = Terminal.convert_iur(toast)
      assert terminal_meta.auto_dismiss == true
      assert is_integer(terminal_meta.dismiss_at)

      assert {:toast, desktop_widget, desktop_meta} = Desktop.convert_iur(toast)
      assert desktop_widget.props[:auto_dismiss] == true
      assert is_integer(desktop_widget.props[:dismiss_at])
      assert desktop_meta.auto_dismiss == true
      assert is_integer(desktop_meta.dismiss_at)

      web_html = Web.convert_iur(toast)
      assert web_html =~ "data-auto-dismiss=\"true\""
      assert web_html =~ "data-dismiss-at=\""
    end

    test "Toast duration 0 disables auto-dismiss" do
      persistent_toast = %Widgets.Toast{
        id: :persistent_toast,
        message: "Requires manual dismiss",
        duration: 0
      }

      assert {:toast, _node, terminal_meta} = Terminal.convert_iur(persistent_toast)
      assert terminal_meta.auto_dismiss == false
      assert terminal_meta.dismiss_at == nil

      assert {:toast, desktop_widget, desktop_meta} = Desktop.convert_iur(persistent_toast)
      assert desktop_widget.props[:auto_dismiss] == false
      refute Keyword.has_key?(desktop_widget.props, :dismiss_at)
      assert desktop_meta.auto_dismiss == false
      assert desktop_meta.dismiss_at == nil

      web_html = Web.convert_iur(persistent_toast)
      assert web_html =~ "data-auto-dismiss=\"false\""
      refute web_html =~ "data-dismiss-at=\""
    end

    test "All dialog widgets render on all platforms" do
      widgets = [
        %Widgets.Dialog{
          id: :dialog_a,
          title: "Dialog",
          content: "Body",
          buttons: [%Widgets.DialogButton{label: "OK", action: :ok}]
        },
        %Widgets.AlertDialog{
          id: :alert_a,
          title: "Alert",
          message: "Attention",
          severity: :error
        },
        %Widgets.Toast{id: :toast_a, message: "Done", duration: 1000}
      ]

      Enum.each(widgets, fn widget ->
        assert {:ok, _} = Terminal.render(widget)
        assert {:ok, _} = Desktop.render(widget)
        assert {:ok, _} = Web.render(widget)
      end)
    end
  end

  # ============================================================================
  # 4.5: Input Widgets
  # ============================================================================

  describe "4.5 - Input Widgets" do
    test "PickList renders with options and selection metadata" do
      pick_list = %Widgets.PickList{
        id: :country_select,
        options: [
          %Widgets.PickListOption{value: "us", label: "United States"},
          %Widgets.PickListOption{value: "ca", label: "Canada"}
        ],
        selected: "ca",
        searchable: true,
        on_select: :country_selected
      }

      assert {:pick_list, _terminal_node, terminal_meta} = Terminal.convert_iur(pick_list)
      assert terminal_meta.id == :country_select
      assert terminal_meta.selected == "ca"
      assert terminal_meta.searchable == true
      assert terminal_meta.on_select == :country_selected

      assert {:pick_list, desktop_widget, desktop_meta} = Desktop.convert_iur(pick_list)
      assert desktop_widget.type == :pick_list
      assert desktop_meta.selected == "ca"

      web_html = Web.convert_iur(pick_list)
      assert web_html =~ ~s(id="country_select")
      assert web_html =~ ~s(data-searchable="true")
      assert web_html =~ "Canada"
      assert web_html =~ ~s(phx-change="country-selected")
    end

    test "FormBuilder renders fields and submit metadata" do
      form_builder = %Widgets.FormBuilder{
        id: :profile_form,
        fields: [
          %Widgets.FormField{
            name: :email,
            type: :email,
            label: "Email",
            required: true,
            placeholder: "user@example.com"
          },
          %Widgets.FormField{name: :newsletter, type: :checkbox, label: "Subscribe"}
        ],
        action: :save_profile,
        on_submit: :profile_saved,
        submit_label: "Save Profile"
      }

      assert {:form_builder, _terminal_node, terminal_meta} = Terminal.convert_iur(form_builder)
      assert terminal_meta.id == :profile_form
      assert terminal_meta.on_submit == :profile_saved

      assert {:form_builder, desktop_widget, desktop_meta} = Desktop.convert_iur(form_builder)
      assert desktop_widget.type == :form_builder
      assert desktop_meta.submit_label == "Save Profile"

      web_html = Web.convert_iur(form_builder)
      assert web_html =~ ~s(<form)
      assert web_html =~ ~s(id="profile_form")
      assert web_html =~ ~s(phx-submit="profile-saved")
      assert web_html =~ ~s(type="email")
      assert web_html =~ ~s(required="true")
      assert web_html =~ "Save Profile"
    end

    test "All input widgets render on all platforms" do
      widgets = [
        %Widgets.PickList{
          id: :status_select,
          options: [
            %Widgets.PickListOption{value: :open, label: "Open"},
            %Widgets.PickListOption{value: :closed, label: "Closed"}
          ],
          allow_clear: true
        },
        %Widgets.FormBuilder{
          id: :task_form,
          fields: [
            %Widgets.FormField{name: :title, type: :text, required: true},
            %Widgets.FormField{
              name: :priority,
              type: :select,
              options: [{"low", "Low"}, {"high", "High"}]
            }
          ]
        }
      ]

      Enum.each(widgets, fn widget ->
        assert {:ok, _} = Terminal.render(widget)
        assert {:ok, _} = Desktop.render(widget)
        assert {:ok, _} = Web.render(widget)
      end)
    end
  end

  # ============================================================================
  # 4.11: Theming and Form Integration
  # ============================================================================

  describe "4.11 - Theming and Form Integration" do
    test "theme switching updates themed styles and renders on all platforms" do
      module =
        compile_phase4_fixture("""
        vbox do
          pick_list :theme, [{:light, "Light"}, {:dark, "Dark"}], on_select: :theme_changed
        end
        """)

      dsl_state = themed_dsl_state()
      light_state = module.init([]) |> Map.put(:theme, :light)
      light_iur = Builder.build(dsl_state, light_state)

      assert %Layouts.VBox{children: [%Widgets.Text{style: %UnifiedIUR.Style{fg: :black}}]} =
               light_iur

      signal = %{type: "unified.input.changed", data: %{widget_id: :theme, value: "dark"}}
      dark_state = module.update(light_state, signal)

      assert dark_state.theme == "dark"

      dark_iur = Builder.build(dsl_state, dark_state)

      assert %Layouts.VBox{children: [%Widgets.Text{style: %UnifiedIUR.Style{fg: :white}}]} =
               dark_iur

      assert {:ok, _} = Terminal.render(dark_iur)
      assert {:ok, _} = Desktop.render(dark_iur)
      assert {:ok, _} = Web.render(dark_iur)
    end

    test "form_builder submission populates validation metadata end-to-end" do
      module =
        compile_phase4_fixture("""
        vbox do
          form_builder :profile_form, [
            %{name: :email, type: :email, required: true},
            %{name: :age, type: :number, required: true},
            %{name: :country, type: :select, options: [{:us, "United States"}, {:ca, "Canada"}]}
          ],
            on_submit: :profile_saved
        end
        """)

      state = module.init([])

      invalid_signal = %{
        type: "unified.form.submitted",
        data: %{form_id: :profile_form, data: %{email: "bad", age: "abc", country: :xx}}
      }

      invalid_state = module.update(state, invalid_signal)

      assert invalid_state.profile_form_valid == false
      assert invalid_state.profile_form_errors.email == [:invalid_email]
      assert invalid_state.profile_form_errors.age == [:invalid_number]
      assert invalid_state.profile_form_errors.country == [:invalid_option]

      valid_signal = %{
        type: "unified.form.submitted",
        data: %{
          form_id: :profile_form,
          data: %{email: "user@example.com", age: "42", country: :ca}
        }
      }

      valid_state = module.update(invalid_state, valid_signal)

      assert valid_state.profile_form_valid == true
      assert valid_state.profile_form_errors == %{}
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

  defp compile_phase4_fixture(body) do
    module =
      Module.concat([
        UnifiedUi,
        Integration,
        Phase4Fixture,
        :"M#{System.unique_integer([:positive])}"
      ])

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

  defp themed_dsl_state do
    light_text = %DslStyle{name: :light_text, attributes: [fg: :black]}
    dark_text = %DslStyle{name: :dark_text, attributes: [fg: :white]}
    light_theme = %DslTheme{name: :light, styles: [text: :light_text]}
    dark_theme = %DslTheme{name: :dark, styles: [text: :dark_text]}

    %{
      [:ui] => %{
        entities: [
          %{
            name: :vbox,
            attrs: %{},
            entities: [
              %{name: :text, attrs: %{content: "Theme Aware", style: :text}}
            ]
          }
        ]
      },
      :styles => %{entities: [light_text, dark_text, light_theme, dark_theme]},
      persist: %{module: __MODULE__}
    }
  end
end
