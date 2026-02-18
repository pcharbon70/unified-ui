defmodule UnifiedUi.AgentTest do
  use ExUnit.Case, async: false

  alias UnifiedUi.Agent

  defmodule CounterComponent do
    @behaviour UnifiedUi.ElmArchitecture

    @impl true
    def init(_opts), do: %{count: 0}

    @impl true
    def update(state, %{type: "inc", data: %{delta: delta}}) when is_integer(delta) do
      %{state | count: state.count + delta}
    end

    def update(state, %{type: "inc"}) do
      %{state | count: state.count + 1}
    end

    def update(state, _signal), do: state

    @impl true
    def view(state) do
      %UnifiedIUR.Widgets.Text{
        id: :counter_text,
        content: Integer.to_string(state.count)
      }
    end
  end

  describe "component lifecycle" do
    test "start_component/3 starts a supervised process addressable by id" do
      component_id = :counter_component_lifecycle
      assert {:ok, pid} = Agent.start_component(CounterComponent, component_id)

      on_exit(fn ->
        Agent.stop_component(component_id)
      end)

      assert Process.alive?(pid)
      assert {:ok, ^pid} = Agent.whereis(component_id)
      assert {:ok, %{count: 0}} = Agent.current_state(component_id)

      assert {:ok, %UnifiedIUR.Widgets.Text{id: :counter_text, content: "0"}} =
               Agent.current_iur(component_id)
    end

    test "signal_component/2 updates model state through component update/2" do
      component_id = :counter_component_signal
      assert {:ok, _pid} = Agent.start_component(CounterComponent, component_id)

      on_exit(fn ->
        Agent.stop_component(component_id)
      end)

      assert :ok = Agent.signal_component(component_id, %{type: "inc", data: %{delta: 3}})
      # Allow cast processing.
      Process.sleep(20)

      assert {:ok, %{count: 3}} = Agent.current_state(component_id)
      assert {:ok, %UnifiedIUR.Widgets.Text{content: "3"}} = Agent.current_iur(component_id)
    end

    test "stop_component/1 terminates and unregisters the component" do
      component_id = :counter_component_stop
      assert {:ok, _pid} = Agent.start_component(CounterComponent, component_id)
      assert {:ok, _pid} = Agent.whereis(component_id)

      assert :ok = Agent.stop_component(component_id)
      assert {:error, :not_found} = Agent.whereis(component_id)
    end
  end
end
