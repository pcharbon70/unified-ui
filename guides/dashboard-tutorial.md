# Tutorial: Build A Dashboard

This tutorial walks through a compact metrics dashboard using implemented widgets.

## 1. Define the Screen

```elixir
defmodule MyApp.DashboardScreen do
  @behaviour UnifiedUi.ElmArchitecture
  use UnifiedUi.Dsl

  state cpu: 42, memory: 68, trend: [20, 35, 42, 55, 48], mode: :overview

  ui do
    vbox id: :dashboard, spacing: 1, padding: 1 do
      text "System Dashboard", style: [fg: :cyan, attrs: [:bold]]

      hbox spacing: 2 do
        gauge :cpu, value: state.cpu, min: 0, max: 100, label: "CPU"
        gauge :memory, value: state.memory, min: 0, max: 100, label: "Memory"
      end

      line_chart :trend, points: state.trend, height: 6

      hbox spacing: 1 do
        button "Refresh", on_click: :refresh
        button "Toggle Mode", on_click: :toggle_mode
      end
    end
  end

  @impl true
  def init(_opts), do: %{cpu: 42, memory: 68, trend: [20, 35, 42, 55, 48], mode: :overview}

  @impl true
  def update(state, %Jido.Signal{data: %{action: :refresh}}) do
    {:ok, %{state | cpu: 50, memory: 61, trend: [35, 42, 55, 48, 50]}}
  end

  def update(state, %Jido.Signal{data: %{action: :toggle_mode}}) do
    next = if state.mode == :overview, do: :detailed, else: :overview
    {:ok, %{state | mode: next}}
  end

  def update(state, _signal), do: {:ok, state}
end
```

## 2. Render It

```elixir
state = MyApp.DashboardScreen.init([])
iur = MyApp.DashboardScreen.view(state)
{:ok, _rendered} = UnifiedUi.Adapters.Terminal.render(iur)
```

## 3. Add Interactions

- wire adapter events through `*.Events.to_signal/2`
- send resulting signals to `update/2`
- re-render from the returned state

## 4. Extend It

- Add `table` for process rows
- Add `tabs` to split overview/detail views
- Move repeated styles to named styles
