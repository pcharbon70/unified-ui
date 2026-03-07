defmodule UnifiedUi.Integration.Phase5Test do
  @moduledoc """
  Focused integration tests for Phase 5 production-readiness scenarios.

  Covered sections:
  - 5.8.1: complete application flow from DSL module to rendered output
  - 5.8.2: multi-platform concurrent rendering
  - 5.8.3: signal communication across component update cycle
  - 5.8.4: state persistence and recovery pattern
  - 5.8.5: error handling and recovery behavior
  """

  use ExUnit.Case, async: false

  alias UnifiedIUR.Layouts.VBox
  alias UnifiedIUR.Widgets.{Button, Text}
  alias UnifiedUi.Adapters.Coordinator
  alias UnifiedUi.Adapters.State
  alias UnifiedUi.Agent
  alias UnifiedUi.Signals

  test "5.8.1 complete application flow: DSL module produces rendered UI state" do
    counter_screen = compile_counter_screen_module()
    component_id = :phase5_complete_app_flow

    assert {:ok, _pid} =
             Agent.start_component(counter_screen, component_id, platforms: [:terminal])

    on_exit(fn ->
      _ = Agent.stop_component(component_id)
    end)

    assert {:ok, %{count: 0}} = Agent.current_state(component_id)

    assert {:ok, %VBox{id: :root, children: children}} = Agent.current_iur(component_id)
    assert Enum.any?(children, &match?(%Text{id: :title}, &1))
    assert Enum.any?(children, &match?(%Button{id: :increment_button}, &1))

    assert {:ok, render_results} = Agent.render_results(component_id)
    assert {:ok, terminal_state} = Map.fetch!(render_results, :terminal)
    assert {:ok, _render_tree} = State.get_root(terminal_state)
  end

  test "5.8.2 and 5.8.3 multi-platform rendering and signal dispatch work together" do
    counter_screen = compile_counter_screen_module()
    component_id = :phase5_multi_platform_signals

    assert {:ok, _pid} =
             Agent.start_component(counter_screen, component_id,
               platforms: [:terminal, :desktop, :web]
             )

    on_exit(fn ->
      _ = Agent.stop_component(component_id)
    end)

    increment_signal =
      Signals.create!(:click, %{widget_id: :increment_button, action: :increment})

    assert :ok = Agent.signal_component(component_id, increment_signal)
    Process.sleep(25)

    assert {:ok, %{count: 1}} = Agent.current_state(component_id)

    assert {:ok, iur} = Agent.current_iur(component_id)

    assert {:ok, concurrent_results} =
             Coordinator.concurrent_render(iur, [:terminal, :desktop, :web])

    assert Enum.all?([:terminal, :desktop, :web], fn platform ->
             match?({:ok, _}, Map.fetch!(concurrent_results, platform))
           end)
  end

  test "5.8.4 and 5.8.5 state persistence pattern and recovery from invalid input" do
    counter_screen = compile_counter_screen_module()
    component_id = :phase5_persistence_and_recovery
    missing_component_id = :phase5_missing_component

    assert {:ok, _pid} =
             Agent.start_component(counter_screen, component_id, platforms: [:terminal])

    assert :ok =
             Agent.signal_component(
               component_id,
               Signals.create!(:click, %{widget_id: :increment_button, action: :increment})
             )

    Process.sleep(25)
    assert {:ok, persisted_state} = Agent.current_state(component_id)
    assert persisted_state == %{count: 1}

    assert :ok = Agent.stop_component(component_id)

    assert {:ok, _pid} =
             Agent.start_component(counter_screen, component_id, persisted_state: persisted_state)

    on_exit(fn ->
      _ = Agent.stop_component(component_id)
    end)

    assert {:ok, %{count: 1}} = Agent.current_state(component_id)
    assert {:error, :not_found} = Agent.signal_component(missing_component_id, %{type: "invalid"})

    assert :ok = Agent.signal_component(component_id, %{type: "invalid.signal", data: %{}})
    Process.sleep(25)
    assert {:ok, %{count: 1}} = Agent.current_state(component_id)

    assert :ok =
             Agent.signal_component(
               component_id,
               Signals.create!(:click, %{widget_id: :increment_button, action: :increment})
             )

    Process.sleep(25)
    assert {:ok, %{count: 2}} = Agent.current_state(component_id)
  end

  defp compile_counter_screen_module do
    module =
      Module.concat([
        UnifiedUi,
        Integration,
        Phase5CounterScreen,
        :"M#{System.unique_integer([:positive])}"
      ])

    source = """
    defmodule #{inspect(module)} do
      @behaviour UnifiedUi.ElmArchitecture
      use UnifiedUi.Dsl

      vbox do
        id :root
        spacing 1
        text "Phase 5 Counter", id: :title
        button "Increment", id: :increment_button, on_click: :increment
        button "Reset", id: :reset_button, on_click: :reset
      end

      @impl true
      def init(opts) do
        case Keyword.get(opts, :persisted_state) do
          %{} = persisted -> persisted
          _ -> %{count: 0}
        end
      end

      @impl true
      def update(state, %{type: "unified.button.clicked", data: %{action: :increment}}) do
        %{state | count: state.count + 1}
      end

      def update(_state, %{type: "unified.button.clicked", data: %{action: :reset}}) do
        %{count: 0}
      end

      def update(state, _signal), do: state
    end
    """

    Code.compile_string(source)
    module
  end
end
