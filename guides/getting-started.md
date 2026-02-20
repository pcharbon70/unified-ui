# Getting Started

This guide shows the shortest path to building and rendering a UnifiedUi screen.

## 1. Add Dependencies

Add UnifiedUi and its runtime dependencies to your project:

```elixir
defp deps do
  [
    {:unified_ui, "~> 0.1"},
    {:jido_signal, "~> 1.0"},
    {:spark, "~> 1.0"}
  ]
end
```

## 2. Define a Screen Module

Create a module that uses `UnifiedUi.Dsl` and implements Elm callbacks:

```elixir
defmodule MyApp.CounterScreen do
  @behaviour UnifiedUi.ElmArchitecture
  use UnifiedUi.Dsl

  state count: 0

  ui do
    vbox spacing: 1 do
      text "Counter"
      text_input :name, placeholder: "Name"
      hbox spacing: 1 do
        button "Increment", on_click: :increment
        button "Decrement", on_click: :decrement
      end
    end
  end

  @impl true
  def init(_opts), do: %{count: 0}

  @impl true
  def update(state, %Jido.Signal{data: %{action: :increment}}) do
    {:ok, %{state | count: state.count + 1}}
  end

  def update(state, %Jido.Signal{data: %{action: :decrement}}) do
    {:ok, %{state | count: state.count - 1}}
  end

  def update(state, _signal), do: {:ok, state}
end
```

## 3. Build IUR and Render

Use one of the platform adapters to render the resulting IUR tree:

```elixir
{:ok, state} =
  MyApp.CounterScreen.init([])
  |> MyApp.CounterScreen.view()
  |> UnifiedUi.Adapters.Terminal.render()
```

## 4. Handle Events

Map raw adapter events into normalized signals:

```elixir
signal =
  UnifiedUi.Adapters.Terminal.Events.to_signal(
    :button_click,
    %{id: :increment_button, action: :increment}
  )

{:ok, next_state} = MyApp.CounterScreen.update(state, signal)
```

## Next Steps

- Review the full widget list in `guides/widget-reference.md`.
- Add styles with the `styles` section and inline style keywords.
- Use the coordinator when rendering to multiple platforms at once.
