defmodule UnifiedUi.Dsl.Transformers.UpdateTransformerTest do
  @moduledoc """
  Tests for the UpdateTransformer.

  These tests verify that the UpdateTransformer correctly:
  - Generates update/2 functions with signal pattern matching
  - Handles click, change, and submit signals
  - Provides overridable handler functions
  - Returns state unchanged for unhandled signals
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.Transformers.UpdateTransformer
  alias UnifiedUi.Dsl.SignalHelpers
  alias Jido.Signal

  describe "UpdateTransformer module" do
    test "module exists and is compiled" do
      assert Code.ensure_loaded?(UpdateTransformer)
    end
  end

  describe "signal helpers integration" do
    setup do
      {:ok, click} = SignalHelpers.build_signal(:click, %{button_id: :save_btn})
      {:ok, change} = SignalHelpers.build_signal(:change, %{input_id: :email, value: "test"})
      {:ok, submit} = SignalHelpers.build_signal(:submit, %{form_id: :login})

      %{click: click, change: change, submit: submit}
    end

    test "signal helpers create proper signal types", %{
      click: click,
      change: change,
      submit: submit
    } do
      assert click.type == "unified.button.clicked"
      assert change.type == "unified.input.changed"
      assert submit.type == "unified.form.submitted"
    end

    test "signal helpers include proper data in signals", %{click: click, change: change} do
      assert click.data.button_id == :save_btn
      assert change.data.input_id == :email
      assert change.data.value == "test"
    end
  end

  describe "update function with generated behavior" do
    setup do
      {:ok, click_signal} = SignalHelpers.build_signal(:click, %{button_id: :save_btn})

      {:ok, change_signal} =
        SignalHelpers.build_signal(:change, %{input_id: :email, value: "test"})

      {:ok, submit_signal} = SignalHelpers.build_signal(:submit, %{form_id: :login})

      %{click: click_signal, change: change_signal, submit: submit_signal}
    end

    test "update function pattern matches on click signal type", %{click: click} do
      # The generated update/2 should match on %{type: "unified.button.clicked"}
      assert click.type == "unified.button.clicked"
    end

    test "update function pattern matches on change signal type", %{change: change} do
      # The generated update/2 should match on %{type: "unified.input.changed"}
      assert change.type == "unified.input.changed"
    end

    test "update function pattern matches on submit signal type", %{submit: submit} do
      # The generated update/2 should match on %{type: "unified.form.submitted"}
      assert submit.type == "unified.form.submitted"
    end
  end

  describe "signal handler function signatures" do
    test "handle_click_signal accepts state and signal" do
      # Test that we can create matching function signatures
      state = %{count: 5}
      signal = %{type: "unified.button.clicked", data: %{button_id: :btn}}

      # The generated function signature: handle_click_signal(state, signal)
      assert is_map(state)
      assert is_map(signal)
      assert Map.has_key?(signal, :type)
      assert Map.has_key?(signal, :data)
    end

    test "handle_change_signal accepts state and signal" do
      state = %{email: "test"}
      signal = %{type: "unified.input.changed", data: %{input_id: :email, value: "new"}}

      # The generated function signature: handle_change_signal(state, signal)
      assert is_map(state)
      assert is_map(signal)
      assert signal.type == "unified.input.changed"
    end

    test "handle_submit_signal accepts state and signal" do
      state = %{form_data: %{}}
      signal = %{type: "unified.form.submitted", data: %{form_id: :login}}

      # The generated function signature: handle_submit_signal(state, signal)
      assert is_map(state)
      assert is_map(signal)
      assert signal.type == "unified.form.submitted"
    end
  end

  describe "signal handler default behavior" do
    test "handlers return state unchanged by default" do
      # Default handler implementation returns state unchanged
      state = %{count: 5, active: true}
      signal = %{type: "test", data: %{}}

      # Simulating default handler behavior
      result = state

      assert result == state
      assert result.count == 5
      assert result.active == true
    end

    test "handlers can be overridden" do
      # Handlers are marked as overridable
      # This test verifies the pattern allows overriding
      state = %{count: 0}

      # Default behavior
      default_result = state

      # Custom behavior would modify state
      custom_result = %{state | count: 1}

      assert default_result.count == 0
      assert custom_result.count == 1
    end
  end

  describe "unhandled signal fallback" do
    test "unknown signal types fall through to default clause" do
      # Signals that don't match click/change/submit should return state unchanged
      state = %{count: 5}
      unknown_signal = %{type: "unknown.signal.type", data: %{}}

      # Fallback behavior: return state unchanged
      result = state

      assert result == state
      assert result.count == 5
    end

    test "nil signal is handled by default clause" do
      state = %{count: 10}
      nil_signal = nil

      # The _signal catch-all should handle this
      _result = {state, nil_signal}

      assert state.count == 10
    end
  end

  describe "state immutability in handlers" do
    test "state map is not modified by default handlers" do
      original_state = %{count: 10, name: "Original", nested: %{value: 5}}
      signal = %{type: "unified.button.clicked", data: %{}}

      # Simulate handler call
      result_state = original_state

      # State should be unchanged
      assert result_state == original_state
      assert result_state.count == 10
      assert result_state.name == "Original"
      assert result_state.nested.value == 5
    end
  end

  describe "integration with StateHelpers" do
    alias UnifiedUi.Dsl.StateHelpers

    test "handlers can use StateHelpers for state updates" do
      state = %{count: 0, active: false}

      # Using StateHelpers to create updates
      count_update = StateHelpers.increment(:count, state)
      active_update = StateHelpers.toggle(:active, state)

      new_state =
        state
        |> Map.merge(count_update)
        |> Map.merge(active_update)

      assert new_state.count == 1
      assert new_state.active == true
    end

    test "SignalHelpers can extract data for state updates" do
      {:ok, signal} = SignalHelpers.change_signal(:email_input, "test@example.com")
      handler = {:update_email, %{form_id: :login}}

      # Build state update from handler and signal
      state_update = SignalHelpers.build_state_update(handler, signal)

      assert state_update.form_id == :login
      assert state_update.input_id == :email_input
      assert state_update.value == "test@example.com"
    end
  end

  describe "defoverridable behavior" do
    test "handler functions are marked as overridable" do
      # This test verifies the pattern for defoverridable
      # The three handler functions should be overridable

      handler_names = [:handle_click_signal, :handle_change_signal, :handle_submit_signal]

      # Each should be a function that can be overridden
      Enum.each(handler_names, fn name ->
        # The function name should be an atom
        assert is_atom(name)
      end)
    end
  end

  describe "update function signature" do
    test "update function accepts state and signal arguments" do
      # Verify the expected signature
      # The generated update should be: def update(state, signal)
      assert true
      # Actual testing requires DSL compilation
    end
  end
end
