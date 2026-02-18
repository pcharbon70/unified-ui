defmodule UnifiedUi.Adapters.DesktopTest do
  @moduledoc """
  Tests for UnifiedUi.Adapters.Desktop
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Adapters.Desktop
  alias UnifiedUi.Adapters.State
  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Layouts
  alias UnifiedIUR.Style

  describe "render/2" do
    test "renders a simple text widget" do
      iur = %Widgets.Text{content: "Hello, World!"}

      assert {:ok, state} = Desktop.render(iur)
      assert State.platform?(state, :desktop)
      assert {:ok, _root} = State.get_root(state)
    end

    test "renders a tree with multiple widgets" do
      iur = %Layouts.VBox{
        children: [
          %Widgets.Text{content: "Title"},
          %Widgets.Button{label: "Click Me"}
        ]
      }

      assert {:ok, state} = Desktop.render(iur)
      assert {:ok, _root} = State.get_root(state)
    end

    test "accepts render options" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Desktop.render(iur, window_title: "My App")
      assert State.get_config(state, :window_title) == "My App"
    end
  end

  describe "update/3" do
    test "updates an existing render state" do
      iur = %Widgets.Text{content: "Original"}

      assert {:ok, state} = Desktop.render(iur)

      updated_iur = %Widgets.Text{content: "Updated"}
      assert {:ok, updated_state} = Desktop.update(updated_iur, state)
      assert {:ok, _root} = State.get_root(updated_state)
    end
  end

  describe "destroy/1" do
    test "cleans up renderer state" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Desktop.render(iur)
      assert :ok = Desktop.destroy(state)
    end
  end

  describe "convert_iur/2 - Text widget" do
    test "converts text widget to DesktopUi label" do
      text = %Widgets.Text{content: "Hello"}

      result = Desktop.convert_iur(text)

      # Result should be a DesktopUi widget map
      assert result.type == :label
      assert result.props[:text] == "Hello"
    end

    test "converts text with style" do
      text = %Widgets.Text{
        content: "Styled",
        style: %Style{fg: :cyan, attrs: [:bold]}
      }

      result = Desktop.convert_iur(text)

      assert result.type == :label
      assert result.props[:color] == :cyan
      assert result.props[:font_style] == :bold
    end

    test "converts text with nil content" do
      text = %Widgets.Text{content: nil}

      result = Desktop.convert_iur(text)

      assert result.type == :label
      assert result.props[:text] == ""
    end

    test "skips invisible text" do
      text = %Widgets.Text{content: "Hidden", visible: false}

      result = Desktop.convert_iur(text)

      assert result == nil
    end
  end

  describe "convert_iur/2 - Button widget" do
    test "converts button widget" do
      button = %Widgets.Button{label: "Submit", on_click: :submit}

      result = Desktop.convert_iur(button)

      assert result.type == :button
      assert result.props[:label] == "Submit"
    end

    test "converts disabled button" do
      button = %Widgets.Button{
        label: "Disabled",
        on_click: :noop,
        disabled: true
      }

      result = Desktop.convert_iur(button)

      assert result.type == :button
      assert result.props[:disabled] == true
    end

    test "converts button with style" do
      button = %Widgets.Button{
        label: "Styled",
        on_click: :click,
        style: %Style{fg: :green}
      }

      result = Desktop.convert_iur(button)

      assert result.type == :button
      assert result.props[:color] == :green
    end

    test "converts button with nil label" do
      button = %Widgets.Button{label: nil, on_click: :noop}

      result = Desktop.convert_iur(button)

      assert result.type == :button
    end

    test "converts button with id" do
      button = %Widgets.Button{
        label: "Click",
        on_click: :click,
        id: :my_button
      }

      result = Desktop.convert_iur(button)

      assert result.type == :button
      assert result.id == :my_button
    end
  end

  describe "convert_iur/2 - Label widget" do
    test "converts label widget" do
      label = %Widgets.Label{text: "Email:", for: :email_input}

      result = Desktop.convert_iur(label)

      assert result.type == :label
      assert result.props[:text] == "Email:"
      assert result.label_for == :email_input
    end

    test "converts label without for reference" do
      label = %Widgets.Label{text: "Just text"}

      result = Desktop.convert_iur(label)

      assert result.type == :label
      assert result.props[:text] == "Just text"
      refute Map.has_key?(result, :label_for)
    end

    test "converts label with style" do
      label = %Widgets.Label{
        text: "Styled Label",
        for: :input,
        style: %Style{fg: :yellow}
      }

      result = Desktop.convert_iur(label)

      assert result.type == :label
      assert result.props[:color] == :yellow
    end
  end

  describe "convert_iur/2 - TextInput widget" do
    test "converts text input with value" do
      input = %Widgets.TextInput{id: :email, value: "test@example.com"}

      result = Desktop.convert_iur(input)

      # Should be a tagged tuple with label widget and metadata
      assert {:text_input, widget, metadata} = result
      assert widget.type == :label
      assert metadata.id == :email
      assert metadata.value == "test@example.com"
    end

    test "converts text input with placeholder" do
      input = %Widgets.TextInput{
        id: :email,
        placeholder: "user@example.com"
      }

      result = Desktop.convert_iur(input)

      assert {:text_input, _widget, metadata} = result
      assert metadata.placeholder == "user@example.com"
    end

    test "converts password input" do
      input = %Widgets.TextInput{id: :password, type: :password}

      result = Desktop.convert_iur(input)

      assert {:text_input, _widget, metadata} = result
      assert metadata.type == :password
    end

    test "converts email input" do
      input = %Widgets.TextInput{id: :email, type: :email}

      result = Desktop.convert_iur(input)

      assert {:text_input, _widget, metadata} = result
      assert metadata.type == :email
    end

    test "converts disabled input" do
      input = %Widgets.TextInput{id: :name, disabled: true}

      result = Desktop.convert_iur(input)

      assert {:text_input, _widget, metadata} = result
      assert metadata.disabled == true
    end
  end

  describe "convert_iur/2 - VBox layout" do
    test "converts vbox with children" do
      vbox = %Layouts.VBox{
        children: [
          %Widgets.Text{content: "First"},
          %Widgets.Text{content: "Second"}
        ]
      }

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.props[:direction] == :vbox
      assert length(result.children) == 2
    end

    test "converts vbox with spacing" do
      vbox = %Layouts.VBox{
        spacing: 10,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.props[:spacing] == 10
    end

    test "converts vbox with padding" do
      vbox = %Layouts.VBox{
        padding: 16,
        children: [%Widgets.Text{content: "Padded"}]
      }

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.props[:padding] == 16
    end

    test "converts vbox with alignment" do
      vbox = %Layouts.VBox{
        align_items: :center,
        children: [%Widgets.Text{content: "Centered"}]
      }

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.props[:align] == :center
    end

    test "converts vbox with style" do
      vbox = %Layouts.VBox{
        style: %Style{fg: :cyan},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.props[:color] == :cyan
    end

    test "converts empty vbox" do
      vbox = %Layouts.VBox{children: []}

      result = Desktop.convert_iur(vbox)

      assert result.type == :container
      assert result.children == []
    end
  end

  describe "convert_iur/2 - HBox layout" do
    test "converts hbox with children" do
      hbox = %Layouts.HBox{
        children: [
          %Widgets.Text{content: "Left"},
          %Widgets.Text{content: "Right"}
        ]
      }

      result = Desktop.convert_iur(hbox)

      assert result.type == :container
      assert result.props[:direction] == :hbox
      assert length(result.children) == 2
    end

    test "converts hbox with spacing" do
      hbox = %Layouts.HBox{
        spacing: 20,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Desktop.convert_iur(hbox)

      assert result.type == :container
      assert result.props[:spacing] == 20
    end

    test "converts hbox with style" do
      hbox = %Layouts.HBox{
        style: %Style{bg: :blue},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Desktop.convert_iur(hbox)

      assert result.type == :container
      assert result.props[:background] == :blue
    end
  end

  describe "nested layouts" do
    test "converts nested vbox and hbox" do
      iur = %Layouts.VBox{
        children: [
          %Widgets.Text{content: "Title"},
          %Layouts.HBox{
            children: [
              %Widgets.Text{content: "Left"},
              %Widgets.Text{content: "Right"}
            ]
          },
          %Widgets.Button{label: "Submit"}
        ]
      }

      result = Desktop.convert_iur(iur)

      assert result.type == :container
      assert result.props[:direction] == :vbox
      assert length(result.children) == 3
    end

    test "converts deeply nested layouts" do
      iur = %Layouts.VBox{
        children: [
          %Layouts.HBox{
            children: [
              %Layouts.VBox{
                children: [
                  %Widgets.Text{content: "Deep"}
                ]
              }
            ]
          }
        ]
      }

      result = Desktop.convert_iur(iur)

      assert result.type == :container
      # Should have nested structure
      assert length(result.children) == 1
    end
  end

  describe "integration tests" do
    test "renders a complete form" do
      iur = %Layouts.VBox{
        spacing: 8,
        children: [
          %Widgets.Label{text: "Email:", for: :email},
          %Widgets.TextInput{id: :email, placeholder: "user@example.com"},
          %Widgets.Label{text: "Password:", for: :password},
          %Widgets.TextInput{id: :password, type: :password},
          %Widgets.Button{label: "Submit", on_click: :submit_form}
        ]
      }

      assert {:ok, state} = Desktop.render(iur)
      assert {:ok, root} = State.get_root(state)
      assert root.type == :container
    end

    test "renders a complex UI with all widget types" do
      iur = %Layouts.VBox{
        spacing: 8,
        children: [
          %Widgets.Text{content: "Welcome", style: %Style{fg: :cyan, attrs: [:bold]}},
          %Layouts.HBox{
            spacing: 16,
            children: [
              %Widgets.Button{label: "OK", on_click: :ok},
              %Widgets.Button{label: "Cancel", on_click: :cancel}
            ]
          }
        ]
      }

      assert {:ok, state} = Desktop.render(iur)
      assert {:ok, root} = State.get_root(state)
      assert root.type == :container
    end
  end
end
