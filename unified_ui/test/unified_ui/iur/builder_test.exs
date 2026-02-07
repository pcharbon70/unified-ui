defmodule UnifiedUi.IUR.BuilderTest do
  @moduledoc """
  Tests for the IUR.Builder module.

  These tests verify that the Builder correctly:
  - Converts DSL entities to IUR structs
  - Handles nested structures recursively
  - Applies style resolution
  - Validates IUR tree structures
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.IUR.{Builder, Style, Widgets, Layouts}

  describe "build_button/2" do
    test "builds button with label only" do
      entity = %{name: :button, attrs: %{label: "Click Me"}}

      result = Builder.build_button(entity, :dsl_state)

      assert %Widgets.Button{} = result
      assert result.label == "Click Me"
      assert result.on_click == nil
      assert result.id == nil
      assert result.disabled == false
      assert result.visible == true
      assert result.style == nil
    end

    test "builds button with all options" do
      entity = %{
        name: :button,
        attrs: %{
          label: "Save",
          id: :save_btn,
          on_click: :save,
          disabled: true,
          visible: false,
          style: [fg: :blue, attrs: [:bold]]
        }
      }

      result = Builder.build_button(entity, :dsl_state)

      assert result.label == "Save"
      assert result.id == :save_btn
      assert result.on_click == :save
      assert result.disabled == true
      assert result.visible == false
      assert %Style{} = result.style
      assert result.style.fg == :blue
      assert result.style.attrs == [:bold]
    end

    test "builds button with tuple on_click" do
      entity = %{
        name: :button,
        attrs: %{
          label: "Submit",
          on_click: {:submit, %{form_id: :login}}
        }
      }

      result = Builder.build_button(entity, :dsl_state)

      assert result.on_click == {:submit, %{form_id: :login}}
    end
  end

  describe "build_text/2" do
    test "builds text with content only" do
      entity = %{name: :text, attrs: %{content: "Hello"}}

      result = Builder.build_text(entity, :dsl_state)

      assert %Widgets.Text{} = result
      assert result.content == "Hello"
      assert result.id == nil
      assert result.visible == true
      assert result.style == nil
    end

    test "builds text with all options" do
      entity = %{
        name: :text,
        attrs: %{
          content: "Welcome",
          id: :greeting,
          visible: true,
          style: [fg: :green, attrs: [:bold]]
        }
      }

      result = Builder.build_text(entity, :dsl_state)

      assert result.content == "Welcome"
      assert result.id == :greeting
      assert result.style.fg == :green
    end
  end

  describe "build_label/2" do
    test "builds label with required fields" do
      entity = %{name: :label, attrs: %{for: :email_input, text: "Email:"}}

      result = Builder.build_label(entity, :dsl_state)

      assert %Widgets.Label{} = result
      assert result.for == :email_input
      assert result.text == "Email:"
      assert result.id == nil
      assert result.visible == true
    end

    test "builds label with all options" do
      entity = %{
        name: :label,
        attrs: %{
          for: :password,
          text: "Password:",
          id: :pwd_label,
          style: [fg: :cyan]
        }
      }

      result = Builder.build_label(entity, :dsl_state)

      assert result.for == :password
      assert result.text == "Password:"
      assert result.id == :pwd_label
      assert result.style.fg == :cyan
    end
  end

  describe "build_text_input/2" do
    test "builds text_input with id only" do
      entity = %{name: :text_input, attrs: %{id: :email}}

      result = Builder.build_text_input(entity, :dsl_state)

      assert %Widgets.TextInput{} = result
      assert result.id == :email
      assert result.value == nil
      assert result.placeholder == nil
      assert result.type == :text
      assert result.disabled == false
      assert result.visible == true
    end

    test "builds text_input with all options" do
      entity = %{
        name: :text_input,
        attrs: %{
          id: :email,
          value: "test@example.com",
          placeholder: "user@example.com",
          type: :email,
          on_change: :email_changed,
          on_submit: :submit_form,
          disabled: false,
          style: [fg: :white]
        }
      }

      result = Builder.build_text_input(entity, :dsl_state)

      assert result.id == :email
      assert result.value == "test@example.com"
      assert result.placeholder == "user@example.com"
      assert result.type == :email
      assert result.on_change == :email_changed
      assert result.on_submit == :submit_form
      assert result.style.fg == :white
    end

    test "builds password input" do
      entity = %{
        name: :text_input,
        attrs: %{id: :password, type: :password}
      }

      result = Builder.build_text_input(entity, :dsl_state)

      assert result.type == :password
    end
  end

  describe "build_vbox/2" do
    test "builds vbox with no children" do
      entity = %{name: :vbox, attrs: %{}, entities: []}

      result = Builder.build_vbox(entity, :dsl_state)

      assert %Layouts.VBox{} = result
      assert result.children == []
      assert result.spacing == 0
      assert result.align_items == nil
      assert result.visible == true
    end

    test "builds vbox with options" do
      entity = %{
        name: :vbox,
        attrs: %{
          id: :main,
          spacing: 2,
          align_items: :center,
          justify_content: :center,
          padding: 1
        },
        entities: []
      }

      result = Builder.build_vbox(entity, :dsl_state)

      assert result.id == :main
      assert result.spacing == 2
      assert result.align_items == :center
      assert result.justify_content == :center
      assert result.padding == 1
    end

    test "builds vbox with style" do
      entity = %{
        name: :vbox,
        attrs: %{style: [bg: :blue]},
        entities: []
      }

      result = Builder.build_vbox(entity, :dsl_state)

      assert %Style{} = result.style
      assert result.style.bg == :blue
    end
  end

  describe "build_hbox/2" do
    test "builds hbox with no children" do
      entity = %{name: :hbox, attrs: %{}, entities: []}

      result = Builder.build_hbox(entity, :dsl_state)

      assert %Layouts.HBox{} = result
      assert result.children == []
      assert result.spacing == 0
    end

    test "builds hbox with options" do
      entity = %{
        name: :hbox,
        attrs: %{
          id: :row,
          spacing: 3,
          align_items: :start
        },
        entities: []
      }

      result = Builder.build_hbox(entity, :dsl_state)

      assert result.id == :row
      assert result.spacing == 3
      assert result.align_items == :start
    end
  end

  describe "build_children/2" do
    test "builds children from entity list" do
      text_entity = %{name: :text, attrs: %{content: "Hello"}}
      button_entity = %{name: :button, attrs: %{label: "Click"}}

      parent = %{entities: [text_entity, button_entity]}

      result = Builder.build_children(parent, :dsl_state)

      assert length(result) == 2
      assert %Widgets.Text{} = Enum.at(result, 0)
      assert %Widgets.Button{} = Enum.at(result, 1)
    end

    test "handles empty entity list" do
      parent = %{entities: []}

      result = Builder.build_children(parent, :dsl_state)

      assert result == []
    end

    test "handles nil entities" do
      parent = %{entities: nil}

      result = Builder.build_children(parent, :dsl_state)

      assert result == []
    end
  end

  describe "build_style/2" do
    test "returns nil for nil style" do
      assert Builder.build_style(nil, :dsl_state) == nil
    end

    test "returns nil for empty keyword list" do
      assert Builder.build_style([], :dsl_state) == nil
    end

    test "builds style from keyword list" do
      result = Builder.build_style([fg: :blue, bg: :white], :dsl_state)

      assert %Style{} = result
      assert result.fg == :blue
      assert result.bg == :white
      assert result.attrs == []
    end

    test "builds style with text attributes" do
      result = Builder.build_style([fg: :red, attrs: [:bold, :underline]], :dsl_state)

      assert result.fg == :red
      assert result.attrs == [:bold, :underline]
    end

    test "returns existing Style struct" do
      style = Style.new(fg: :green)
      result = Builder.build_style(style, :dsl_state)

      assert result == style
    end
  end

  describe "build_entity/2" do
    test "dispatches to correct builder for button" do
      entity = %{name: :button, attrs: %{label: "Click"}}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Widgets.Button{label: "Click"} = result
    end

    test "dispatches to correct builder for text" do
      entity = %{name: :text, attrs: %{content: "Hello"}}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Widgets.Text{content: "Hello"} = result
    end

    test "dispatches to correct builder for label" do
      entity = %{name: :label, attrs: %{for: :input, text: "Label:"}}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Widgets.Label{} = result
    end

    test "dispatches to correct builder for text_input" do
      entity = %{name: :text_input, attrs: %{id: :email}}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Widgets.TextInput{id: :email} = result
    end

    test "dispatches to correct builder for vbox" do
      entity = %{name: :vbox, attrs: %{}, entities: []}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Layouts.VBox{} = result
    end

    test "dispatches to correct builder for hbox" do
      entity = %{name: :hbox, attrs: %{}, entities: []}

      result = Builder.build_entity(entity, :dsl_state)

      assert %Layouts.HBox{} = result
    end

    test "returns nil for unknown entity type" do
      entity = %{name: :unknown, attrs: %{}}

      result = Builder.build_entity(entity, :dsl_state)

      assert result == nil
    end
  end

  describe "validate/1" do
    test "validates button with label" do
      button = %Widgets.Button{label: "Click"}
      assert Builder.validate(button) == :ok
    end

    test "rejects button without label" do
      button = %Widgets.Button{label: nil}
      assert Builder.validate(button) == {:error, :missing_label}
    end

    test "validates text with content" do
      text = %Widgets.Text{content: "Hello"}
      assert Builder.validate(text) == :ok
    end

    test "rejects text without content" do
      text = %Widgets.Text{content: nil}
      assert Builder.validate(text) == {:error, :missing_content}
    end

    test "validates label - label fields are optional in struct" do
      # Label struct defines :for and :text as optional (in the [] part of defstruct)
      # So the validation should accept nil values since they're struct-defined defaults
      label = %Widgets.Label{}
      assert Builder.validate(label) == :ok
    end

    test "validates text_input - id is optional in struct" do
      # TextInput struct defines :id as optional (in the [] part of defstruct)
      # So the validation should accept nil values since they're struct-defined defaults
      input = %Widgets.TextInput{}
      assert Builder.validate(input) == :ok
    end

    test "validates vbox with valid children" do
      vbox = %Layouts.VBox{children: [%Widgets.Text{content: "Hello"}]}
      assert Builder.validate(vbox) == :ok
    end

    test "validates hbox with valid children" do
      hbox = %Layouts.HBox{children: [%Widgets.Button{label: "Click"}]}
      assert Builder.validate(hbox) == :ok
    end

    test "rejects vbox with invalid children" do
      vbox = %Layouts.VBox{children: [%Widgets.Text{content: nil}]}
      assert Builder.validate(vbox) == {:error, :missing_content}
    end

    test "validates empty layouts" do
      vbox = %Layouts.VBox{children: []}
      hbox = %Layouts.HBox{children: []}

      assert Builder.validate(vbox) == :ok
      assert Builder.validate(hbox) == :ok
    end
  end

  describe "validate_children/1" do
    test "returns :ok for empty list" do
      assert Builder.validate_children([]) == :ok
    end

    test "returns :ok for all valid children" do
      children = [
        %Widgets.Text{content: "Hello"},
        %Widgets.Button{label: "Click"}
      ]

      assert Builder.validate_children(children) == :ok
    end

    test "returns error for invalid child" do
      children = [
        %Widgets.Text{content: "Hello"},
        %Widgets.Button{label: nil}
      ]

      assert Builder.validate_children(children) == {:error, :missing_label}
    end
  end

  describe "integration: nested structures" do
    test "builds vbox with text and button children" do
      text_entity = %{name: :text, attrs: %{content: "Welcome"}}
      button_entity = %{name: :button, attrs: %{label: "Start"}}

      vbox_entity = %{
        name: :vbox,
        attrs: %{spacing: 1},
        entities: [text_entity, button_entity]
      }

      result = Builder.build_vbox(vbox_entity, :dsl_state)

      assert %Layouts.VBox{} = result
      assert result.spacing == 1
      assert length(result.children) == 2

      assert %Widgets.Text{content: "Welcome"} = Enum.at(result.children, 0)
      assert %Widgets.Button{label: "Start"} = Enum.at(result.children, 1)
    end

    test "builds deeply nested structure" do
      # vbox -> hbox -> button
      button_entity = %{name: :button, attrs: %{label: "Click"}}
      hbox_entity = %{name: :hbox, attrs: %{spacing: 1}, entities: [button_entity]}
      vbox_entity = %{name: :vbox, attrs: %{}, entities: [hbox_entity]}

      result = Builder.build_vbox(vbox_entity, :dsl_state)

      assert %Layouts.VBox{} = result
      assert [%Layouts.HBox{}] = result.children

      hbox = hd(result.children)
      assert [%Widgets.Button{}] = hbox.children
    end

    test "builds mixed content structure" do
      # vbox with text, hbox with buttons, and another text
      button1 = %{name: :button, attrs: %{label: "OK"}}
      button2 = %{name: :button, attrs: %{label: "Cancel"}}
      hbox = %{name: :hbox, attrs: %{spacing: 2}, entities: [button1, button2]}

      text1 = %{name: :text, attrs: %{content: "Title"}}
      text2 = %{name: :text, attrs: %{content: "Footer"}}

      vbox = %{
        name: :vbox,
        attrs: %{spacing: 1},
        entities: [text1, hbox, text2]
      }

      result = Builder.build_vbox(vbox, :dsl_state)

      assert length(result.children) == 3
      assert %Widgets.Text{content: "Title"} = Enum.at(result.children, 0)
      assert %Layouts.HBox{} = Enum.at(result.children, 1)
      assert %Widgets.Text{content: "Footer"} = Enum.at(result.children, 2)

      hbox = Enum.at(result.children, 1)
      assert length(hbox.children) == 2
    end
  end

  describe "integration: styles" do
    test "applies styles to widgets" do
      entity = %{
        name: :text,
        attrs: %{
          content: "Styled",
          style: [fg: :red, bg: :white, attrs: [:bold]]
        }
      }

      result = Builder.build_text(entity, :dsl_state)

      assert %Style{} = result.style
      assert result.style.fg == :red
      assert result.style.bg == :white
      assert result.style.attrs == [:bold]
    end

    test "applies styles to layouts" do
      entity = %{
        name: :vbox,
        attrs: %{style: [padding: 2, margin: 1]},
        entities: []
      }

      result = Builder.build_vbox(entity, :dsl_state)

      assert %Style{} = result.style
      assert result.style.padding == 2
      assert result.style.margin == 1
    end

    test "handles nil styles correctly" do
      entity = %{name: :text, attrs: %{content: "Plain"}}

      result = Builder.build_text(entity, :dsl_state)

      assert result.style == nil
    end
  end
end
