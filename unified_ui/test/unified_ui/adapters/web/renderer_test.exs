defmodule UnifiedUi.Adapters.WebTest do
  @moduledoc """
  Tests for UnifiedUi.Adapters.Web
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Adapters.Web
  alias UnifiedUi.Adapters.State
  alias UnifiedUi.IUR.Widgets
  alias UnifiedUi.IUR.Layouts
  alias UnifiedUi.IUR.Style

  describe "render/2" do
    test "renders a simple text widget" do
      iur = %Widgets.Text{content: "Hello, World!"}

      assert {:ok, state} = Web.render(iur)
      assert State.platform?(state, :web)
      assert {:ok, root} = State.get_root(state)
      assert root =~ "Hello, World!"
      assert root =~ "<span"
    end

    test "renders a tree with multiple widgets" do
      iur = %Layouts.VBox{
        children: [
          %Widgets.Text{content: "Title"},
          %Widgets.Button{label: "Click Me"}
        ]
      }

      assert {:ok, state} = Web.render(iur)
      assert {:ok, root} = State.get_root(state)
      assert root =~ "Title"
      assert root =~ "Click Me"
    end

    test "accepts render options" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Web.render(iur, window_title: "My App")
      assert State.get_config(state, :window_title) == "My App"
    end
  end

  describe "update/3" do
    test "updates an existing render state" do
      iur = %Widgets.Text{content: "Original"}

      assert {:ok, state} = Web.render(iur)

      updated_iur = %Widgets.Text{content: "Updated"}
      assert {:ok, updated_state} = Web.update(updated_iur, state)
      assert {:ok, _root} = State.get_root(updated_state)
    end
  end

  describe "destroy/1" do
    test "cleans up renderer state" do
      iur = %Widgets.Text{content: "Test"}

      assert {:ok, state} = Web.render(iur)
      assert :ok = Web.destroy(state)
    end
  end

  describe "convert_iur/2 - Text widget" do
    test "converts text widget to HTML span" do
      text = %Widgets.Text{content: "Hello"}

      result = Web.convert_iur(text)

      assert result =~ ~r/<span[^>]*>Hello<\/span>/
    end

    test "converts text with style" do
      text = %Widgets.Text{
        content: "Styled",
        style: %Style{fg: :cyan, attrs: [:bold]}
      }

      result = Web.convert_iur(text)

      assert result =~ "color: cyan"
      assert result =~ "font-weight: bold"
      assert result =~ "<span"
    end

    test "converts text with nil content" do
      text = %Widgets.Text{content: nil}

      result = Web.convert_iur(text)

      assert result =~ ~r/<span[^>]*><\/span>/
    end

    test "skips invisible text" do
      text = %Widgets.Text{content: "Hidden", visible: false}

      result = Web.convert_iur(text)

      assert result == ""
    end

    test "escapes HTML in text content" do
      text = %Widgets.Text{content: "<script>alert('xss')</script>"}

      result = Web.convert_iur(text)

      assert result =~ "&lt;script&gt;"
      refute result =~ "<script>"
    end
  end

  describe "convert_iur/2 - Button widget" do
    test "converts button widget to HTML button" do
      button = %Widgets.Button{label: "Submit", on_click: :submit}

      result = Web.convert_iur(button)

      assert result =~ ~r/<button[^>]*>Submit<\/button>/
      assert result =~ "phx-click=\"submit\""
    end

    test "converts button with underscore event to kebab-case" do
      button = %Widgets.Button{label: "Save", on_click: :save_form}

      result = Web.convert_iur(button)

      assert result =~ "phx-click=\"save-form\""
    end

    test "converts disabled button" do
      button = %Widgets.Button{
        label: "Disabled",
        on_click: :noop,
        disabled: true
      }

      result = Web.convert_iur(button)

      assert result =~ "disabled=\"true\""
    end

    test "converts button with style" do
      button = %Widgets.Button{
        label: "Styled",
        on_click: :click,
        style: %Style{fg: :green}
      }

      result = Web.convert_iur(button)

      assert result =~ "color: green"
    end

    test "converts button with nil label" do
      button = %Widgets.Button{label: nil, on_click: :noop}

      result = Web.convert_iur(button)

      assert result =~ ~r/<button[^>]*><\/button>/
    end

    test "converts button with id" do
      button = %Widgets.Button{
        label: "Click",
        on_click: :click,
        id: :my_button
      }

      result = Web.convert_iur(button)

      assert result =~ "id=\"my_button\""
    end
  end

  describe "convert_iur/2 - Label widget" do
    test "converts label widget to HTML label" do
      label = %Widgets.Label{text: "Email:", for: :email_input}

      result = Web.convert_iur(label)

      assert result =~ ~r/<label[^>]*for="email_input"[^>]*>Email:<\/label>/
    end

    test "converts label without for reference" do
      label = %Widgets.Label{text: "Just text"}

      result = Web.convert_iur(label)

      assert result =~ ~r/<label[^>]*>Just text<\/label>/
      refute result =~ "for="
    end

    test "converts label with style" do
      label = %Widgets.Label{
        text: "Styled Label",
        for: :input,
        style: %Style{fg: :yellow}
      }

      result = Web.convert_iur(label)

      assert result =~ "color: yellow"
    end
  end

  describe "convert_iur/2 - TextInput widget" do
    test "converts text input with value" do
      input = %Widgets.TextInput{id: :email, value: "test@example.com"}

      result = Web.convert_iur(input)

      assert result =~ ~r/<input[^>]*\/>/
      assert result =~ "id=\"email\""
      assert result =~ "value=\"test@example.com\""
    end

    test "converts text input with placeholder" do
      input = %Widgets.TextInput{
        id: :email,
        placeholder: "user@example.com"
      }

      result = Web.convert_iur(input)

      assert result =~ "placeholder=\"user@example.com\""
    end

    test "converts password input" do
      input = %Widgets.TextInput{id: :password, type: :password}

      result = Web.convert_iur(input)

      assert result =~ "type=\"password\""
    end

    test "converts email input" do
      input = %Widgets.TextInput{id: :email, type: :email}

      result = Web.convert_iur(input)

      assert result =~ "type=\"email\""
    end

    test "converts disabled input" do
      input = %Widgets.TextInput{id: :name, disabled: true}

      result = Web.convert_iur(input)

      assert result =~ "disabled=\"true\""
    end

    test "converts input with phx-change binding" do
      input = %Widgets.TextInput{
        id: :query,
        on_change: :update_query
      }

      result = Web.convert_iur(input)

      assert result =~ "phx-change=\"update-query\""
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

      result = Web.convert_iur(vbox)

      assert result =~ "display: flex"
      assert result =~ "flex-direction: column"
      assert result =~ "First"
      assert result =~ "Second"
    end

    test "converts vbox with spacing" do
      vbox = %Layouts.VBox{
        spacing: 10,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Web.convert_iur(vbox)

      assert result =~ "gap: 10px"
    end

    test "converts vbox with padding" do
      vbox = %Layouts.VBox{
        padding: 16,
        children: [%Widgets.Text{content: "Padded"}]
      }

      result = Web.convert_iur(vbox)

      assert result =~ "padding: 16px"
    end

    test "converts vbox with alignment" do
      vbox = %Layouts.VBox{
        align_items: :center,
        children: [%Widgets.Text{content: "Centered"}]
      }

      result = Web.convert_iur(vbox)

      assert result =~ "align-items: center"
    end

    test "converts vbox with style" do
      vbox = %Layouts.VBox{
        style: %Style{bg: :lightgray},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Web.convert_iur(vbox)

      assert result =~ "background-color: lightgray"
    end

    test "converts empty vbox" do
      vbox = %Layouts.VBox{children: []}

      result = Web.convert_iur(vbox)

      assert result =~ ~r/<div[^>]*><\/div>/
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

      result = Web.convert_iur(hbox)

      assert result =~ "display: flex"
      assert result =~ "flex-direction: row"
      assert result =~ "Left"
      assert result =~ "Right"
    end

    test "converts hbox with spacing" do
      hbox = %Layouts.HBox{
        spacing: 20,
        children: [%Widgets.Text{content: "A"}]
      }

      result = Web.convert_iur(hbox)

      assert result =~ "gap: 20px"
    end

    test "converts hbox with style" do
      hbox = %Layouts.HBox{
        style: %Style{fg: :white, bg: :blue},
        children: [%Widgets.Text{content: "Styled"}]
      }

      result = Web.convert_iur(hbox)

      assert result =~ "background-color: blue"
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

      result = Web.convert_iur(iur)

      assert result =~ "flex-direction: column"
      assert result =~ "flex-direction: row"
      assert result =~ "Title"
      assert result =~ "Left"
      assert result =~ "Right"
      assert result =~ "Submit"
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

      result = Web.convert_iur(iur)

      assert result =~ "Deep"
      # Should have nested divs
      assert (result |> String.split("<div") |> length()) > 3
    end
  end

  describe "integration tests" do
    test "renders a complete form" do
      iur = %Layouts.VBox{
        spacing: 8,
        children: [
          %Widgets.Label{text: "Email:", for: :email},
          %Widgets.TextInput{id: :email, type: :email, placeholder: "user@example.com"},
          %Widgets.Label{text: "Password:", for: :password},
          %Widgets.TextInput{id: :password, type: :password},
          %Widgets.Button{label: "Submit", on_click: :submit_form}
        ]
      }

      assert {:ok, state} = Web.render(iur)
      assert {:ok, root} = State.get_root(state)
      assert root =~ "Email:"
      assert root =~ "type=\"email\""
      assert root =~ "type=\"password\""
      assert root =~ "phx-click=\"submit-form\""
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

      assert {:ok, state} = Web.render(iur)
      assert {:ok, root} = State.get_root(state)
      assert root =~ "Welcome"
      assert root =~ "font-weight: bold"
      assert root =~ "color: cyan"
      assert root =~ "phx-click=\"ok\""
      assert root =~ "phx-click=\"cancel\""
    end
  end
end
