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
      assert_component_stopped(component_id)
    end
  end

  describe "error paths" do
    test "returns :not_found for unknown component ids" do
      component_id = :missing_component

      assert {:error, :not_found} = Agent.whereis(component_id)
      assert {:error, :not_found} = Agent.signal_component(component_id, %{type: "inc"})
      assert {:error, :not_found} = Agent.current_state(component_id)
      assert {:error, :not_found} = Agent.current_iur(component_id)
      assert {:error, :not_found} = Agent.render_results(component_id)
      assert {:error, :not_found} = Agent.stop_component(component_id)
    end

    test "start_component/3 returns already_started when component id is reused" do
      component_id = :counter_component_duplicate
      assert {:ok, pid} = Agent.start_component(CounterComponent, component_id)

      on_exit(fn ->
        Agent.stop_component(component_id)
      end)

      assert {:error, {:already_started, ^pid}} =
               Agent.start_component(CounterComponent, component_id)
    end

    test "start_component/3 returns runtime_not_started when runtime supervisor is stopped" do
      with_runtime_child_stopped(UnifiedUi.AgentSupervisor, fn ->
        assert {:error, :agent_runtime_not_started} =
                 Agent.start_component(CounterComponent, :runtime_down_start)
      end)
    end

    test "stop_component/1 returns runtime_not_started when registry is stopped" do
      with_runtime_child_stopped(UnifiedUi.AgentRegistry, fn ->
        assert {:error, :agent_runtime_not_started} = Agent.stop_component(:runtime_down_stop)
      end)
    end
  end

  defp assert_component_stopped(component_id, attempts \\ 20)

  defp assert_component_stopped(_component_id, 0) do
    flunk("component is still registered after stop_component/1")
  end

  defp assert_component_stopped(component_id, attempts) do
    case Agent.whereis(component_id) do
      {:error, :not_found} ->
        :ok

      {:ok, _pid} ->
        Process.sleep(10)
        assert_component_stopped(component_id, attempts - 1)
    end
  end

  defp with_runtime_child_stopped(child_id, fun) do
    assert :ok = Supervisor.terminate_child(UnifiedUi.Supervisor, child_id)

    try do
      fun.()
    after
      assert {:ok, _pid} = Supervisor.restart_child(UnifiedUi.Supervisor, child_id)
    end
  end
end
