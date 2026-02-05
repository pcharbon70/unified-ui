defmodule UnifiedUi.Dsl.IntegrationTest do
  @moduledoc """
  Integration tests for the UnifiedUi DSL.

  These tests verify that the DSL components work together correctly:
  - State entity definition and struct creation
  - DSL sections can be used together
  - State can be converted to maps for Elm Architecture
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.State

  describe "State entity integration" do
    test "State struct can be created with various attribute types" do
      # Integer attributes
      state = %State{attrs: [count: 0, total: 100]}
      assert Keyword.get(state.attrs, :count) == 0
      assert Keyword.get(state.attrs, :total) == 100

      # String attributes
      state = %State{attrs: [name: "Test", message: "Hello"]}
      assert Keyword.get(state.attrs, :name) == "Test"
      assert Keyword.get(state.attrs, :message) == "Hello"

      # Boolean attributes
      state = %State{attrs: [active: true, visible: false]}
      assert Keyword.get(state.attrs, :active) == true
      assert Keyword.get(state.attrs, :visible) == false
    end

    test "State struct with mixed attribute types" do
      state = %State{
        attrs: [
          count: 42,
          name: "Example",
          active: true,
          rate: 3.14,
          items: [1, 2, 3],
          metadata: %{key: "value"}
        ]
      }

      assert Keyword.get(state.attrs, :count) == 42
      assert Keyword.get(state.attrs, :name) == "Example"
      assert Keyword.get(state.attrs, :active) == true
      assert Keyword.get(state.attrs, :rate) == 3.14
      assert Keyword.get(state.attrs, :items) == [1, 2, 3]
      assert Keyword.get(state.attrs, :metadata) == %{key: "value"}
    end
  end

  describe "State to Elm Architecture map conversion" do
    test "State converts to map with atom keys" do
      state = %State{attrs: [count: 0, name: "Test", active: true]}
      state_map = Enum.into(state.attrs, %{})

      assert is_map(state_map)
      assert Map.get(state_map, :count) == 0
      assert Map.get(state_map, :name) == "Test"
      assert Map.get(state_map, :active) == true
    end

    test "Empty state converts to empty map" do
      state = %State{attrs: []}
      state_map = Enum.into(state.attrs, %{})

      assert state_map == %{}
    end

    test "State with nil attrs converts to empty map" do
      state = %State{attrs: nil}
      # Enum.into with nil would fail, so we handle it
      state_map = if state.attrs, do: Enum.into(state.attrs, %{}), else: %{}

      assert state_map == %{}
    end
  end

  describe "DSL standard signals integration" do
    test "standard_signals/0 returns expected signals" do
      signals = UnifiedUi.Signals.standard_signals()

      assert is_list(signals)
      assert :click in signals
      assert :change in signals
      assert :submit in signals
      assert :focus in signals
      assert :blur in signals
      assert :select in signals
    end

    test "Dsl.standard_signals delegates to Signals module" do
      signals_dsl = UnifiedUi.Dsl.standard_signals()
      signals_module = UnifiedUi.Signals.standard_signals()

      assert signals_dsl == signals_module
    end
  end

  describe "Signal type mapping" do
    test "signal_type/1 returns correct type string for standard signals" do
      assert UnifiedUi.Signals.signal_type(:click) == "unified.button.clicked"
      assert UnifiedUi.Signals.signal_type(:change) == "unified.input.changed"
      assert UnifiedUi.Signals.signal_type(:submit) == "unified.form.submitted"
      assert UnifiedUi.Signals.signal_type(:focus) == "unified.element.focused"
      assert UnifiedUi.Signals.signal_type(:blur) == "unified.element.blurred"
      assert UnifiedUi.Signals.signal_type(:select) == "unified.item.selected"
    end

    test "signal_type/1 returns error for unknown signals" do
      assert UnifiedUi.Signals.signal_type(:unknown) == {:error, :unknown_signal}
      assert UnifiedUi.Signals.signal_type(:custom) == {:error, :unknown_signal}
    end
  end

  describe "Signal creation integration" do
    test "create/2 generates valid Jido.Signal" do
      {:ok, signal} = UnifiedUi.Signals.create(:click, %{button_id: :test_btn})

      assert signal.type == "unified.button.clicked"
      assert signal.data == %{button_id: :test_btn}
      assert signal.source == "/unified_ui"
    end

    test "create/3 accepts custom source" do
      {:ok, signal} =
        UnifiedUi.Signals.create(:submit, %{form_id: :login}, source: "/my/app")

      assert signal.type == "unified.form.submitted"
      assert signal.source == "/my/app"
    end

    test "create!/2 raises on error" do
      assert_raise UnifiedUi.Errors.InvalidSignalError, ~r/Invalid signal name: :unknown/, fn ->
        UnifiedUi.Signals.create!(:unknown, %{})
      end
    end
  end

  describe "IUR Element protocol integration" do
    alias UnifiedUi.IUR.Layouts.VBox
    alias UnifiedUi.IUR.Widgets.Text
    alias UnifiedUi.IUR.Widgets.Button

    test "VBox with children returns children via protocol" do
      vbox = %VBox{
        children: [
          %Text{content: "Hello"},
          %Button{label: "Click me"}
        ]
      }

      children = UnifiedUi.IUR.Element.children(vbox)
      assert length(children) == 2
    end

    test "VBox metadata includes all properties" do
      vbox = %VBox{id: :main, spacing: 2, align: :center}
      metadata = UnifiedUi.IUR.Element.metadata(vbox)

      assert metadata.type == :vbox
      assert metadata.id == :main
      assert metadata.spacing == 2
      assert metadata.align == :center
    end

    test "Text widget returns empty children list" do
      text = %Text{content: "Hello"}
      assert UnifiedUi.IUR.Element.children(text) == []
    end

    test "Text widget metadata includes content" do
      text = %Text{content: "Test", id: :greeting}
      metadata = UnifiedUi.IUR.Element.metadata(text)

      assert metadata.type == :text
      assert metadata.id == :greeting
    end

    test "Button widget metadata includes label" do
      button = %Button{label: "Submit", id: :submit_btn}
      metadata = UnifiedUi.IUR.Element.metadata(button)

      assert metadata.type == :button
      assert metadata.label == "Submit"
      assert metadata.id == :submit_btn
    end
  end

  describe "End-to-end state flow" do
    test "State entity can flow through Elm Architecture pattern" do
      # 1. Define initial state
      initial_state = %State{attrs: [count: 0, max: 10]}

      # 2. Convert to map for Elm init
      init_map = Enum.into(initial_state.attrs, %{})

      # 3. Simulate update returning new state
      updated_map = Map.update!(init_map, :count, &(&1 + 1))

      # 4. Verify state transformation
      assert updated_map.count == 1
      assert updated_map.max == 10
    end
  end
end
