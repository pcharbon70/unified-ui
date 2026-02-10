defmodule UnifiedUi.Adapters.TerminalTest do
  @moduledoc """
  Tests for UnifiedUi.Adapters.Terminal
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Adapters.Terminal
  alias UnifiedUi.Adapters.State
  alias UnifiedUi.IUR.Widgets
  alias UnifiedUi.IUR.Layouts
  alias UnifiedUi.IUR.Style

  describe "render/2" do
    test "renders a simple text widget" do
      iur = %Widgets.Text{content: "Hello, World!"}

      assert {:ok, state} = Terminal.render(iur)
      assert State.platform?(state, :terminal)
      assert {:ok, _root} = State.get_root(state)
    end

    test "renders a tree with multiple widgets" do
      iur = %Layouts.VBox{
        children: [
          %Widgets.Text{content: "Title"},
          %Widgets.Button{label: "Click Me"}
        ]
      }

      assert {:ok, state} = Terminal.render(iur)
      assert {:ok, _root} = State.get_root(state)
    end

    test "accepts render options" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Terminal.render(iur, window_title: "My App")
      assert State.get_config(state, :window_title) == "My App"
    end
  end

  describe "update/3" do
    test "updates an existing render state" do
      iur = %Widgets.Text{content: "Original"}

      assert {:ok, state} = Terminal.render(iur)

      updated_iur = %Widgets.Text{content: "Updated"}
      assert {:ok, updated_state} = Terminal.update(updated_iur, state)
      assert {:ok, _root} = State.get_root(updated_state)
    end
  end

  describe "destroy/1" do
    test "cleans up renderer state" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Terminal.render(iur)
      assert :ok = Terminal.destroy(state)
    end
  end

  describe "convert_iur/2 - Text widget" do
    test "converts text widget to TermUI text node" do
      text = %Widgets.Text{content: "Hello"}

      result = Terminal.convert_iur(text)

      # Result should be a TermUI text node
      assert result != nil
    end

    test "converts text with style" do
      text = %Widgets.Text{
        content: "Styled",
        style: %Style{fg: :cyan, attrs: [:bold]}
      }

      result = Terminal.convert_iur(text)

      assert result != nil
    end

    test "converts text with nil content" do
      text = %Widgets.Text{content: nil}

      result = Terminal.convert_iur(text)

      assert result != nil
    end

    test "skips invisible text" do
      text = %Widgets.Text{content: "Hidden", visible: false}

      result = Terminal.convert_iur(text)

      assert result == nil
    end
  end

  describe "convert_iur/2 - Button widget" do
    test "converts button widget" do
      button = %Widgets.Button{label: "Submit", on_click: :submit}

      result = Terminal.convert_iur(button)

      assert result != nil
    end

    test "converts disabled button" do
      button = %Widgets.Button{
        label: "Disabled",
        on_click: :noop,
        disabled: true
      }

      result = Terminal.convert_iur(button)

      assert result != nil
    end

    test "converts button with style" do
      button = %Widgets.Button{
        label: "Styled",
        on_click: :click,
        style: %Style{fg: :green}
      }

      result = Terminal.convert_iur(button)

      assert result != nil
    end

    test "converts button with nil label" do
      button = %Widgets.Button{label: nil, on_click: :noop}

      result = Terminal.convert_iur(button)

      assert result != nil
    end
  end

  describe "convert_iur/2 - Label widget" do
    test "converts label widget" do
      label = %Widgets.Label{text: "Email:", for: :email_input}

      result = Terminal.convert_iur(label)

      assert result != nil
    end

    test "converts label without for reference" do
      label = %Widgets.Label{text: "Just text"}

      result = Terminal.convert_iur(label)

      assert result != nil
    end

    test "converts label with style" do
      label = %Widgets.Label{
        text: "Styled Label",
        for: :input,
        style: %Style{fg: :yellow}
      }

      result = Terminal.convert_iur(label)

      assert result != nil
    end
  end

  describe "convert_iur/2 - TextInput widget" do
    test "converts text input with value" do
      input = %Widgets.TextInput{id: :email, value: "test@example.com"}

      result = Terminal.convert_iur(input)

      assert result != nil
    end

    test "converts text input with placeholder" do
      input = %Widgets.TextInput{
        id: :email,
        placeholder: "user@example.com"
      }

      result = Terminal.convert_iur(input)

      assert result != nil
    end

    test "converts password input" do
      input = %Widgets.TextInput{id: :password, type: :password}

      result = Terminal.convert_iur(input)

      assert result != nil
    end

    test "converts email input" do
      input = %Widgets.TextInput{id: :email, type: :email}

      result = Terminal.convert_iur(input)

      assert result != nil
    end

    test "converts disabled input" do
      input = %Widgets.TextInput{id: :name, disabled: true}

      result = Terminal.convert_iur(input)

      assert result != nil
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

      result = Terminal.convert_iur(vbox)

      assert result != nil
    end

    test "converts vbox with spacing" do
      vbox = %Layouts.VBox{
        spacing: 2,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Terminal.convert_iur(vbox)

      assert result != nil
    end

    test "converts vbox with padding" do
      vbox = %Layouts.VBox{
        padding: 1,
        children: [%Widgets.Text{content: "Padded"}]
      }

      result = Terminal.convert_iur(vbox)

      assert result != nil
    end

    test "converts vbox with alignment" do
      vbox = %Layouts.VBox{
        align_items: :center,
        children: [%Widgets.Text{content: "Centered"}]
      }

      result = Terminal.convert_iur(vbox)

      assert result != nil
    end

    test "converts vbox with style" do
      vbox = %Layouts.VBox{
        style: %Style{fg: :cyan},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Terminal.convert_iur(vbox)

      assert result != nil
    end

    test "converts empty vbox" do
      vbox = %Layouts.VBox{children: []}

      result = Terminal.convert_iur(vbox)

      assert result != nil
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

      result = Terminal.convert_iur(hbox)

      assert result != nil
    end

    test "converts hbox with spacing" do
      hbox = %Layouts.HBox{
        spacing: 2,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Terminal.convert_iur(hbox)

      assert result != nil
    end

    test "converts hbox with style" do
      hbox = %Layouts.HBox{
        style: %Style{bg: :blue},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Terminal.convert_iur(hbox)

      assert result != nil
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

      result = Terminal.convert_iur(iur)

      assert result != nil
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

      result = Terminal.convert_iur(iur)

      assert result != nil
    end
  end

  describe "integration tests" do
    test "renders a complete form" do
      iur = %Layouts.VBox{
        spacing: 1,
        children: [
          %Widgets.Label{text: "Email:", for: :email},
          %Widgets.TextInput{id: :email, placeholder: "user@example.com"},
          %Widgets.Label{text: "Password:", for: :password},
          %Widgets.TextInput{id: :password, type: :password},
          %Widgets.Button{label: "Submit", on_click: :submit_form}
        ]
      }

      assert {:ok, state} = Terminal.render(iur)
      assert {:ok, _root} = State.get_root(state)
    end

    test "renders a complex UI with all widget types" do
      iur = %Layouts.VBox{
        spacing: 1,
        children: [
          %Widgets.Text{content: "Welcome", style: %Style{fg: :cyan, attrs: [:bold]}},
          %Layouts.HBox{
            spacing: 2,
            children: [
              %Widgets.Button{label: "OK", on_click: :ok},
              %Widgets.Button{label: "Cancel", on_click: :cancel}
            ]
          }
        ]
      }

      assert {:ok, state} = Terminal.render(iur)
      assert {:ok, _root} = State.get_root(state)
    end
  end
end
