defmodule UnifiedUi.IUR.IntegrationTest do
  @moduledoc """
  Integration tests for IUR (Intermediate UI Representation) and Signals.

  These tests verify that:
  - IUR elements can be created with signal handlers
  - Signal payloads are correctly structured
  - UI tree traversal works with signals
  - Element metadata includes signal information
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.IUR.Layouts.VBox
  alias UnifiedUi.IUR.Layouts.HBox
  alias UnifiedUi.IUR.Widgets.Text
  alias UnifiedUi.IUR.Widgets.Button
  alias UnifiedUi.Signals

  describe "IUR elements with signal handlers" do
    test "Button widget can hold on_click signal handler" do
      handler = fn -> {:button_clicked, %{id: :test_btn}} end
      button = %Button{label: "Click me", on_click: handler}

      assert button.on_click == handler
      assert is_function(button.on_click)
    end

    test "Button signal handler can be invoked" do
      handler = fn -> {:save, %{timestamp: DateTime.utc_now()}} end
      button = %Button{label: "Save", on_click: handler}

      result = button.on_click.()

      assert elem(result, 0) == :save
      assert is_map(elem(result, 1))
    end
  end

  describe "Signal payload structure" do
    test "create/2 generates valid signal payload" do
      {:ok, signal} = Signals.create(:click, %{button_id: :submit, x: 100, y: 200})

      assert signal.type == "unified.button.clicked"
      assert signal.data.button_id == :submit
      assert signal.data.x == 100
      assert signal.data.y == 200
    end

    test "signal payload can be nested" do
      {:ok, signal} =
        Signals.create(:change, %{form: %{field: :email, value: "test@example.com"}})

      assert signal.type == "unified.input.changed"
      assert signal.data.form.field == :email
      assert signal.data.form.value == "test@example.com"
    end

    test "signal payload can be empty" do
      {:ok, signal} = Signals.create(:blur, %{})

      assert signal.type == "unified.element.blurred"
      assert signal.data == %{}
    end
  end

  describe "UI tree traversal with signals" do
    test "VBox children can be traversed via protocol" do
      button1 = %Button{label: "OK", on_click: fn -> {:ok, %{}} end}
      button2 = %Button{label: "Cancel", on_click: fn -> {:cancel, %{}} end}
      vbox = %VBox{children: [button1, button2]}

      children = UnifiedUi.IUR.Element.children(vbox)

      assert length(children) == 2
      assert hd(children).label == "OK"
    end

    test "Nested layouts can be traversed" do
      inner_box = %VBox{
        children: [
          %Text{content: "Inner"},
          %Button{label: "Inner Button", on_click: fn -> :inner end}
        ]
      }

      outer_box = %VBox{
        children: [
          %Text{content: "Outer"},
          inner_box
        ]
      }

      children = UnifiedUi.IUR.Element.children(outer_box)
      assert length(children) == 2

      inner_children = UnifiedUi.IUR.Element.children(Enum.at(children, 1))
      assert length(inner_children) == 2
    end

    test "HBox can contain VBox and vice versa" do
      vbox = %VBox{children: [%Text{content: "V1"}, %Text{content: "V2"}]}
      hbox = %HBox{children: [%Text{content: "H1"}, vbox]}

      children = UnifiedUi.IUR.Element.children(hbox)
      assert length(children) == 2

      vbox_children = UnifiedUi.IUR.Element.children(Enum.at(children, 1))
      assert length(vbox_children) == 2
    end
  end

  describe "Element metadata with signal information" do
    test "Button metadata includes on_click handler" do
      handler = fn -> {:click, %{}} end
      button = %Button{label: "Test", on_click: handler, id: :test_btn}

      metadata = UnifiedUi.IUR.Element.metadata(button)

      assert metadata.type == :button
      assert metadata.label == "Test"
      assert metadata.on_click == handler
      assert metadata.id == :test_btn
    end

    test "Button without on_click has nil in metadata" do
      button = %Button{label: "No Handler", id: :no_handler}

      metadata = UnifiedUi.IUR.Element.metadata(button)

      assert metadata.type == :button
      assert metadata.on_click == nil
    end

    test "Layout metadata includes spacing and align" do
      vbox = %VBox{id: :main, spacing: 2, align: :center}

      metadata = UnifiedUi.IUR.Element.metadata(vbox)

      assert metadata.type == :vbox
      assert metadata.spacing == 2
      assert metadata.align == :center
    end
  end

  describe "Signal creation from UI elements" do
    test "Can create signal from button click" do
      button = %Button{label: "Submit", id: :submit_btn}
      {:ok, signal} = Signals.create(:click, %{button_id: button.id})

      assert signal.type == "unified.button.clicked"
      assert signal.data.button_id == :submit_btn
    end

    test "Can create signal with custom source from UI element" do
      {:ok, signal} = Signals.create(:click, %{element: :button}, source: "/my/app/screen")

      assert signal.source == "/my/app/screen"
    end

    test "Can create signal with subject from UI context" do
      {:ok, signal} = Signals.create(:change, %{value: "test"}, subject: "user_input")

      assert signal.subject == "user_input"
    end
  end

  describe "Signal type mapping" do
    test "signal_type/1 returns type for standard signal atoms" do
      assert Signals.signal_type(:click) == "unified.button.clicked"
      assert Signals.signal_type(:change) == "unified.input.changed"
      assert Signals.signal_type(:submit) == "unified.form.submitted"
    end

    test "signal_type/1 returns error for unknown signals" do
      assert Signals.signal_type(:unknown) == {:error, :unknown_signal}
      assert Signals.signal_type(:invalid) == {:error, :unknown_signal}
    end
  end

  describe "Complete UI tree with signals" do
    test "Build complete form UI with signal handlers" do
      form = %VBox{
        id: :login_form,
        spacing: 1,
        children: [
          %Text{content: "Login", id: :title},
          %HBox{
            children: [
              %Text{content: "Username:"}
              # TextInput would go here in Phase 2
            ]
          },
          %HBox{
            children: [
              %Button{
                label: "Login",
                id: :login_btn,
                on_click: fn -> {:login, %{}} end
              },
              %Button{
                label: "Cancel",
                id: :cancel_btn,
                on_click: fn -> {:cancel, %{}} end
              }
            ]
          }
        ]
      }

      # Verify structure
      assert length(UnifiedUi.IUR.Element.children(form)) == 3

      # Verify metadata
      metadata = UnifiedUi.IUR.Element.metadata(form)
      assert metadata.type == :vbox
      assert metadata.id == :login_form
      assert metadata.spacing == 1

      # Traverse to buttons
      button_row = Enum.at(UnifiedUi.IUR.Element.children(form), 2)
      buttons = UnifiedUi.IUR.Element.children(button_row)

      assert length(buttons) == 2
      login_btn = Enum.at(buttons, 0)
      assert login_btn.on_click != nil
    end
  end

  describe "Signal round-trip from UI element" do
    test "Create signal, verify type, and recreate" do
      button = %Button{label: "Test", id: :test_btn}

      # Create signal from button
      {:ok, signal} = Signals.create(:click, %{button_id: button.id, x: 10, y: 20})

      # Verify signal type
      assert signal.type == "unified.button.clicked"

      # Verify we can extract the button_id back
      assert signal.data.button_id == :test_btn
      assert signal.data.x == 10
      assert signal.data.y == 20
    end
  end
end
