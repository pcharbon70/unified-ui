defmodule UnifiedUi.IURTest do
  use ExUnit.Case

  alias UnifiedUi.IUR.{Element, Style, Widgets, Layouts}

  describe "Style" do
    test "creates a new style from keyword list" do
      style = Style.new(fg: :blue, bg: :white, attrs: [:bold])
      assert style.fg == :blue
      assert style.bg == :white
      assert style.attrs == [:bold]
      assert style.padding == nil
    end

    test "new/0 creates empty style" do
      style = Style.new()
      assert style.fg == nil
      assert style.bg == nil
      assert style.attrs == []
    end

    test "merge/2 combines styles with later values overriding" do
      style1 = Style.new(fg: :blue, padding: 2, attrs: [:bold])
      style2 = Style.new(fg: :red, margin: 1, attrs: [:underline])

      merged = Style.merge(style1, style2)

      # overridden
      assert merged.fg == :red
      assert merged.bg == nil
      # from style1
      assert merged.padding == 2
      # from style2
      assert merged.margin == 1
      # combined
      assert [:bold, :underline] = merged.attrs
    end

    test "merge/2 handles nil styles" do
      style = Style.new(fg: :blue)

      assert Style.merge(nil, style) == style
      assert Style.merge(style, nil) == style
      assert Style.merge(nil, nil) == Style.new()
    end

    test "merge_many/1 combines list of styles" do
      styles = [
        Style.new(fg: :blue, padding: 1),
        Style.new(bg: :white, attrs: [:bold]),
        Style.new(fg: :red, margin: 2)
      ]

      merged = Style.merge_many(styles)

      assert merged.fg == :red
      assert merged.bg == :white
      assert merged.padding == 1
      assert merged.margin == 2
      assert merged.attrs == [:bold]
    end

    test "merge_many/1 handles empty list" do
      assert Style.merge_many([]) == Style.new()
    end

    test "merge_many/1 skips nil styles" do
      styles = [
        Style.new(fg: :blue),
        nil,
        Style.new(bg: :white)
      ]

      merged = Style.merge_many(styles)
      assert merged.fg == :blue
      assert merged.bg == :white
    end
  end

  describe "Widgets.Text" do
    test "creates a text widget with content" do
      text = %Widgets.Text{content: "Hello, World!"}
      assert text.content == "Hello, World!"
      assert text.id == nil
      assert text.style == nil
    end

    test "creates a text widget with id and style" do
      style = %Style{fg: :blue, attrs: [:bold]}
      text = %Widgets.Text{content: "Error!", id: :error_msg, style: style}

      assert text.content == "Error!"
      assert text.id == :error_msg
      assert text.style == style
    end
  end

  describe "Widgets.Button" do
    test "creates a button with label and on_click" do
      button = %Widgets.Button{label: "Submit", on_click: :submit}
      assert button.label == "Submit"
      assert button.on_click == :submit
      assert button.disabled == false
      assert button.style == nil
    end

    test "creates a disabled button" do
      button = %Widgets.Button{label: "Disabled", on_click: :noop, disabled: true}
      assert button.disabled == true
    end

    test "creates a button with tuple on_click" do
      button = %Widgets.Button{label: "Save", on_click: {:save, %{data: "value"}}}
      assert button.on_click == {:save, %{data: "value"}}
    end

    test "creates a button with visible false" do
      button = %Widgets.Button{label: "Hidden", on_click: :noop, visible: false}
      assert button.visible == false
    end
  end

  describe "Widgets.Label" do
    test "creates a label with for and text" do
      label = %Widgets.Label{for: :email_input, text: "Email:"}
      assert label.for == :email_input
      assert label.text == "Email:"
      assert label.id == nil
      assert label.style == nil
    end

    test "creates a label with id and style" do
      style = %Style{fg: :cyan, attrs: [:bold]}
      label = %Widgets.Label{for: :password, text: "Password:", id: :pwd_label, style: style}

      assert label.for == :password
      assert label.text == "Password:"
      assert label.id == :pwd_label
      assert label.style == style
    end

    test "creates a label with visible option" do
      label = %Widgets.Label{for: :test, text: "Test", visible: false}
      assert label.visible == false
    end
  end

  describe "Widgets.TextInput" do
    test "creates a text_input with id" do
      input = %Widgets.TextInput{id: :email}
      assert input.id == :email
      assert input.value == nil
      assert input.placeholder == nil
      assert input.type == nil
      assert input.on_change == nil
      assert input.on_submit == nil
      assert input.disabled == nil
      assert input.visible == true
    end

    test "creates a text_input with all options" do
      input = %Widgets.TextInput{
        id: :email,
        value: "test@example.com",
        placeholder: "user@example.com",
        type: :email,
        on_change: :email_changed,
        on_submit: :form_submit,
        disabled: false,
        visible: true
      }

      assert input.id == :email
      assert input.value == "test@example.com"
      assert input.placeholder == "user@example.com"
      assert input.type == :email
      assert input.on_change == :email_changed
      assert input.on_submit == :form_submit
      assert input.disabled == false
      assert input.visible == true
    end

    test "creates a password input" do
      input = %Widgets.TextInput{id: :password, type: :password}
      assert input.type == :password
    end

    test "creates a number input" do
      input = %Widgets.TextInput{id: :age, type: :number}
      assert input.type == :number
    end

    test "creates a text_input with placeholder only" do
      input = %Widgets.TextInput{id: :search, placeholder: "Search..."}
      assert input.id == :search
      assert input.placeholder == "Search..."
    end

    test "creates a disabled text_input" do
      input = %Widgets.TextInput{id: :readonly, disabled: true}
      assert input.disabled == true
    end

    test "creates a text_input with initial value" do
      input = %Widgets.TextInput{id: :name, value: "John Doe"}
      assert input.value == "John Doe"
    end
  end

  describe "Layouts.VBox" do
    test "creates an empty VBox" do
      vbox = %Layouts.VBox{}
      assert vbox.children == []
      assert vbox.spacing == 0
      assert vbox.align == nil
      assert vbox.id == nil
    end

    test "creates a VBox with children" do
      text = %Widgets.Text{content: "Title"}
      button = %Widgets.Button{label: "OK", on_click: :ok}

      vbox = %Layouts.VBox{children: [text, button], spacing: 1, align: :center}

      assert vbox.children == [text, button]
      assert vbox.spacing == 1
      assert vbox.align == :center
    end
  end

  describe "Layouts.HBox" do
    test "creates an empty HBox" do
      hbox = %Layouts.HBox{}
      assert hbox.children == []
      assert hbox.spacing == 0
      assert hbox.align == nil
      assert hbox.id == nil
    end

    test "creates an HBox with children" do
      label = %Widgets.Text{content: "Name:"}
      button = %Widgets.Button{label: "Submit", on_click: :submit}

      hbox = %Layouts.HBox{children: [label, button], spacing: 2, align: :center}

      assert hbox.children == [label, button]
      assert hbox.spacing == 2
      assert hbox.align == :center
    end
  end

  describe "Element protocol for Text" do
    test "children/1 returns empty list for text" do
      text = %Widgets.Text{content: "Hello"}
      assert Element.children(text) == []
    end

    test "metadata/1 returns text properties" do
      text = %Widgets.Text{content: "Hello", id: :greeting}
      metadata = Element.metadata(text)

      assert metadata.type == :text
      assert metadata.id == :greeting
    end

    test "metadata/1 includes style when present" do
      style = %Style{fg: :blue}
      text = %Widgets.Text{content: "Hi", style: style}
      metadata = Element.metadata(text)

      assert metadata.style == style
    end

    test "metadata/1 excludes id when nil" do
      text = %Widgets.Text{content: "Hello"}
      metadata = Element.metadata(text)

      refute Map.has_key?(metadata, :id)
      assert metadata.type == :text
    end

    test "metadata/1 includes visible field" do
      text = %Widgets.Text{content: "Hidden", visible: false}
      metadata = Element.metadata(text)

      assert metadata.visible == false
    end
  end

  describe "Element protocol for Label" do
    test "children/1 returns empty list for label" do
      label = %Widgets.Label{for: :input, text: "Label:"}
      assert Element.children(label) == []
    end

    test "metadata/1 returns label properties" do
      label = %Widgets.Label{for: :email, text: "Email:", id: :email_label}
      metadata = Element.metadata(label)

      assert metadata.type == :label
      assert metadata.for == :email
      assert metadata.text == "Email:"
      assert metadata.id == :email_label
    end

    test "metadata/1 includes style when present" do
      style = %Style{fg: :cyan}
      label = %Widgets.Label{for: :test, text: "Test:", style: style}
      metadata = Element.metadata(label)

      assert metadata.style == style
    end

    test "metadata/1 includes visible field" do
      label = %Widgets.Label{for: :test, text: "Test:", visible: false}
      metadata = Element.metadata(label)

      assert metadata.visible == false
    end
  end

  describe "Element protocol for TextInput" do
    test "children/1 returns empty list for text_input" do
      input = %Widgets.TextInput{id: :email}
      assert Element.children(input) == []
    end

    test "metadata/1 returns text_input properties" do
      input = %Widgets.TextInput{
        id: :email,
        value: "test@example.com",
        placeholder: "user@example.com",
        type: :email
      }

      metadata = Element.metadata(input)

      assert metadata.type == :text_input
      assert metadata.id == :email
      assert metadata.value == "test@example.com"
      assert metadata.placeholder == "user@example.com"
      assert metadata.input_type == :email
    end

    test "metadata/1 includes on_change when present" do
      input = %Widgets.TextInput{id: :test, on_change: :changed}
      metadata = Element.metadata(input)

      assert metadata.on_change == :changed
    end

    test "metadata/1 includes on_submit when present" do
      input = %Widgets.TextInput{id: :test, on_submit: :submitted}
      metadata = Element.metadata(input)

      assert metadata.on_submit == :submitted
    end

    test "metadata/1 includes disabled field" do
      input = %Widgets.TextInput{id: :test, disabled: true}
      metadata = Element.metadata(input)

      assert metadata.disabled == true
    end

    test "metadata/1 includes visible field" do
      input = %Widgets.TextInput{id: :test, visible: false}
      metadata = Element.metadata(input)

      assert metadata.visible == false
    end

    test "metadata/1 includes style when present" do
      style = %Style{fg: :blue}
      input = %Widgets.TextInput{id: :test, style: style}
      metadata = Element.metadata(input)

      assert metadata.style == style
    end
  end

  describe "Element protocol for Button" do
    test "children/1 returns empty list for button" do
      button = %Widgets.Button{label: "Click Me"}
      assert Element.children(button) == []
    end

    test "metadata/1 returns button properties" do
      button = %Widgets.Button{
        label: "Submit",
        on_click: :submit,
        disabled: false,
        id: :submit_btn
      }

      metadata = Element.metadata(button)

      assert metadata.type == :button
      assert metadata.label == "Submit"
      assert metadata.on_click == :submit
      assert metadata.disabled == false
      assert metadata.id == :submit_btn
    end

    test "metadata/1 includes style when present" do
      style = %Style{bg: :blue}
      button = %Widgets.Button{label: "OK", style: style}
      metadata = Element.metadata(button)

      assert metadata.style == style
    end
  end

  describe "Element protocol for VBox" do
    test "children/1 returns child elements" do
      text = %Widgets.Text{content: "A"}
      button = %Widgets.Button{label: "B", on_click: :b}

      vbox = %Layouts.VBox{children: [text, button]}
      assert Element.children(vbox) == [text, button]
    end

    test "metadata/1 returns vbox properties" do
      vbox = %Layouts.VBox{id: :main, spacing: 2, align: :center}
      metadata = Element.metadata(vbox)

      assert metadata.type == :vbox
      assert metadata.id == :main
      assert metadata.spacing == 2
      assert metadata.align == :center
    end

    test "metadata/1 excludes nil id" do
      vbox = %Layouts.VBox{spacing: 1}
      metadata = Element.metadata(vbox)

      refute Map.has_key?(metadata, :id)
      assert metadata.spacing == 1
    end
  end

  describe "Element protocol for HBox" do
    test "children/1 returns child elements" do
      text = %Widgets.Text{content: "Label:"}
      button = %Widgets.Button{label: "Submit", on_click: :submit}

      hbox = %Layouts.HBox{children: [text, button]}
      assert Element.children(hbox) == [text, button]
    end

    test "metadata/1 returns hbox properties" do
      hbox = %Layouts.HBox{id: :form_row, spacing: 2, align: :center}
      metadata = Element.metadata(hbox)

      assert metadata.type == :hbox
      assert metadata.id == :form_row
      assert metadata.spacing == 2
      assert metadata.align == :center
    end
  end

  describe "Element protocol fallback" do
    # Note: Protocols must explicitly implement for Any or specific types.
    # The Any fallback implementation in element.ex provides graceful handling
    # for types that implement the protocol but weren't explicitly defined.
    test "protocol works for implemented types" do
      # Verify protocol works for types we explicitly implemented
      text = %Widgets.Text{content: "test"}
      assert is_list(Element.children(text))
      assert is_map(Element.metadata(text))
    end
  end

  describe "Nested layouts" do
    test "can create nested layout structure" do
      text = %Widgets.Text{content: "Title"}
      button = %Widgets.Button{label: "OK", on_click: :ok}

      inner_hbox = %Layouts.HBox{
        id: :button_row,
        children: [button],
        spacing: 1
      }

      vbox = %Layouts.VBox{
        id: :main,
        children: [text, inner_hbox],
        spacing: 2
      }

      # Traverse the structure
      assert Element.children(vbox) == [text, inner_hbox]
      assert Element.children(inner_hbox) == [button]
      assert Element.children(text) == []
      assert Element.children(button) == []
    end

    test "metadata works for nested structure" do
      button = %Widgets.Button{label: "Cancel", on_click: :cancel}
      hbox = %Layouts.HBox{children: [button]}
      vbox = %Layouts.VBox{children: [hbox]}

      vbox_meta = Element.metadata(vbox)
      assert vbox_meta.type == :vbox

      hbox_meta = Element.metadata(hbox)
      assert hbox_meta.type == :hbox

      button_meta = Element.metadata(button)
      assert button_meta.type == :button
    end
  end
end
