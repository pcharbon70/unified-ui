defmodule UnifiedUi.Agent do
  @moduledoc """
  Runtime helpers for starting UI components as supervised processes.

  `UnifiedUi.Agent` provides a thin process runtime around modules that
  implement `UnifiedUi.ElmArchitecture`.
  """

  alias UnifiedUi.Agent.Server

  @registry UnifiedUi.AgentRegistry
  @supervisor UnifiedUi.AgentSupervisor

  @type component_id :: atom()
  @type signal :: term()

  @doc """
  Starts a component process for the given module and component id.

  Supported opts:
  - `:platforms` - list of platforms for adapter rendering (`[:terminal | :desktop | :web]`)
  - `:render_opts` - options forwarded to adapter rendering
  - any additional opts are passed to the component `init/1` callback
  """
  @spec start_component(module(), component_id(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_component(module, component_id, opts \\ [])
      when is_atom(module) and is_atom(component_id) and is_list(opts) do
    child_spec = {Server, module: module, component_id: component_id, opts: opts}

    DynamicSupervisor.start_child(@supervisor, child_spec)
  rescue
    _ -> {:error, :agent_runtime_not_started}
  catch
    :exit, _ -> {:error, :agent_runtime_not_started}
  end

  @doc """
  Stops a running component process by component id.
  """
  @spec stop_component(component_id()) :: :ok | {:error, term()}
  def stop_component(component_id) when is_atom(component_id) do
    with {:ok, pid} <- whereis(component_id),
         :ok <- DynamicSupervisor.terminate_child(@supervisor, pid) do
      :ok
    else
      {:error, _} = error -> error
      _ -> {:error, :stop_failed}
    end
  rescue
    _ -> {:error, :agent_runtime_not_started}
  catch
    :exit, _ -> {:error, :agent_runtime_not_started}
  end

  @doc """
  Sends a signal to a running component process.
  """
  @spec signal_component(component_id(), signal()) :: :ok | {:error, term()}
  def signal_component(component_id, signal) when is_atom(component_id) do
    with {:ok, pid} <- whereis(component_id) do
      GenServer.cast(pid, {:signal, signal})
      :ok
    end
  end

  @doc """
  Returns the current component model state.
  """
  @spec current_state(component_id()) :: {:ok, map()} | {:error, term()}
  def current_state(component_id) when is_atom(component_id) do
    with {:ok, pid} <- whereis(component_id) do
      GenServer.call(pid, :state)
    end
  end

  @doc """
  Returns the latest IUR value produced by the component.
  """
  @spec current_iur(component_id()) :: {:ok, term()} | {:error, term()}
  def current_iur(component_id) when is_atom(component_id) do
    with {:ok, pid} <- whereis(component_id) do
      GenServer.call(pid, :iur)
    end
  end

  @doc """
  Returns the latest adapter render results for the component.
  """
  @spec render_results(component_id()) :: {:ok, map()} | {:error, term()}
  def render_results(component_id) when is_atom(component_id) do
    with {:ok, pid} <- whereis(component_id) do
      GenServer.call(pid, :render_results)
    end
  end

  @doc """
  Looks up a component process by id.
  """
  @spec whereis(component_id()) :: {:ok, pid()} | {:error, :not_found}
  def whereis(component_id) when is_atom(component_id) do
    case Registry.lookup(@registry, component_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end
end

defmodule UnifiedUi.Agent.Server do
  @moduledoc false
  use GenServer

  alias UnifiedUi.Adapters.Coordinator

  @registry UnifiedUi.AgentRegistry

  defstruct [
    :module,
    :component_id,
    :model_state,
    :iur,
    platforms: [],
    render_opts: [],
    render_results: %{}
  ]

  @type t :: %__MODULE__{
          module: module(),
          component_id: atom(),
          model_state: map(),
          iur: term(),
          platforms: [atom()],
          render_opts: keyword(),
          render_results: map()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    module = Keyword.fetch!(opts, :module)
    component_id = Keyword.fetch!(opts, :component_id)
    server_opts = Keyword.get(opts, :opts, [])

    GenServer.start_link(__MODULE__, {module, component_id, server_opts},
      name: via_tuple(component_id)
    )
  end

  @impl true
  def init({module, component_id, opts}) do
    platforms = normalize_platforms(Keyword.get(opts, :platforms, []))
    render_opts = Keyword.get(opts, :render_opts, [])

    model_state = init_model_state(module, opts)
    {iur, render_results} = build_render_data(module, model_state, platforms, render_opts)

    {:ok,
     %__MODULE__{
       module: module,
       component_id: component_id,
       model_state: model_state,
       iur: iur,
       platforms: platforms,
       render_opts: render_opts,
       render_results: render_results
     }}
  end

  @impl true
  def handle_cast({:signal, signal}, %__MODULE__{} = state) do
    model_state = update_model_state(state.module, state.model_state, signal)

    {iur, render_results} =
      build_render_data(state.module, model_state, state.platforms, state.render_opts)

    {:noreply, %{state | model_state: model_state, iur: iur, render_results: render_results}}
  end

  @impl true
  def handle_call(:state, _from, %__MODULE__{} = state) do
    {:reply, {:ok, state.model_state}, state}
  end

  @impl true
  def handle_call(:iur, _from, %__MODULE__{} = state) do
    {:reply, {:ok, state.iur}, state}
  end

  @impl true
  def handle_call(:render_results, _from, %__MODULE__{} = state) do
    {:reply, {:ok, state.render_results}, state}
  end

  defp via_tuple(component_id) do
    {:via, Registry, {@registry, component_id}}
  end

  defp normalize_platforms(platforms) when is_list(platforms) do
    platforms
    |> Enum.filter(&(&1 in [:terminal, :desktop, :web]))
    |> Enum.uniq()
  end

  defp normalize_platforms(_), do: []

  defp init_model_state(module, opts) do
    if function_exported?(module, :init, 1) do
      module
      |> then(& &1.init(opts))
      |> normalize_model_state(%{})
    else
      %{}
    end
  rescue
    _ -> %{}
  end

  defp update_model_state(module, current_state, signal) do
    if function_exported?(module, :update, 2) do
      module
      |> then(& &1.update(current_state, signal))
      |> normalize_model_state(current_state)
    else
      current_state
    end
  rescue
    _ -> current_state
  end

  defp normalize_model_state(%{} = model_state, _fallback), do: model_state
  defp normalize_model_state({:ok, %{} = model_state}, _fallback), do: model_state
  defp normalize_model_state({:noreply, %{} = model_state}, _fallback), do: model_state
  defp normalize_model_state(_other, fallback), do: fallback

  defp build_render_data(module, model_state, platforms, render_opts) do
    iur = build_iur(module, model_state)

    render_results =
      case {platforms, iur} do
        {[], _} ->
          %{}

        {_, nil} ->
          %{}

        {platforms, iur} ->
          case Coordinator.render_on(iur, platforms, render_opts) do
            {:ok, results} -> results
            {:error, reason} -> %{error: reason}
          end
      end

    {iur, render_results}
  end

  defp build_iur(module, model_state) do
    if function_exported?(module, :view, 1) do
      module.view(model_state)
    else
      nil
    end
  rescue
    _ -> nil
  end
end
