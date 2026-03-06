# Extensions

This guide covers the current extension path for **custom widgets**, **custom layouts**, and **custom renderers**.

As of `0.1.x`, external packages can define custom IUR widgets and custom renderers, but adding brand-new DSL entities to `use UnifiedUi.Dsl` still requires changes in UnifiedUi core (`Sections`, `IUR.Builder`, and renderers).

## Generate Extension Scaffold

Use the generator to create a complete extension scaffold (extension module + sample widget + sample renderer + optional test):

```bash
mix unified_ui.gen.extension MyApp.Extensions.Observability
```

## Creating Custom Widgets

### 1. Generate a widget scaffold

Use the built-in generator:

```bash
mix unified_ui.gen.widget MyApp.Widgets.StatusBadge
```

This creates:

- widget struct module under `lib/...`
- `UnifiedIUR.Element` protocol implementation
- optional test scaffold under `test/...`

### 2. Define the target struct + IUR protocol implementation

The generated shape looks like:

```elixir
defmodule MyApp.Widgets.StatusBadge do
  defstruct [:id, :label, :value, :style, visible: true]

  @type t :: %__MODULE__{
          id: atom() | nil,
          label: String.t() | nil,
          value: term(),
          style: UnifiedIUR.Style.t() | nil,
          visible: boolean()
        }
end

defimpl UnifiedIUR.Element, for: MyApp.Widgets.StatusBadge do
  def children(_widget), do: []

  def metadata(widget) do
    %{
      type: :status_badge,
      id: widget.id,
      label: widget.label,
      value: widget.value,
      visible: widget.visible,
      style: widget.style
    }
  end
end
```

### 3. (Core path) Define a DSL entity for the widget

If you are extending UnifiedUi core, create a Spark entity with the target struct:

```elixir
defmodule MyApp.Widgets.StatusBadge do
  defstruct [:id, :label, :value, :style, visible: true]
end

defmodule MyApp.Dsl.Entities.CustomWidgets do
  @status_badge_entity %Spark.Dsl.Entity{
    name: :status_badge,
    target: MyApp.Widgets.StatusBadge,
    args: [:id, :label, :value],
    schema: [
      id: [type: :atom, required: true],
      label: [type: :string, required: true],
      value: [type: :any, required: true],
      style: [type: :keyword_list, required: false],
      visible: [type: :boolean, required: false, default: true]
    ]
  }

  def status_badge_entity, do: @status_badge_entity
end
```

Then register the entity in DSL sections and add IUR builder support.

### 4. Use the widget in a screen

Until external DSL registration is available, compose custom widgets directly in `view/1`:

```elixir
defmodule MyApp.Widgets.StatusBadge do
  defstruct [:id, :label, :value, :style, visible: true]
end

defmodule MyApp.Screens.StatusScreen do
  @behaviour UnifiedUi.ElmArchitecture

  @impl true
  def init(_opts), do: %{status: :ok}

  @impl true
  def update(state, _signal), do: state

  @impl true
  def view(state) do
    %UnifiedIUR.Layouts.VBox{
      id: :root,
      spacing: 1,
      children: [
        %UnifiedIUR.Widgets.Text{content: "Service Health"},
        %MyApp.Widgets.StatusBadge{id: :service_status, label: "API", value: state.status}
      ]
    }
  end
end
```

### 5. Add renderer converters

Built-in renderers only convert known widget types. To render custom widgets, add converter clauses (core) or provide a custom renderer:

```elixir
defmodule MyApp.Widgets.StatusBadge do
  defstruct [:id, :label, :value, :style, visible: true]
end

defmodule MyApp.Adapters.TerminalWithStatusBadge do
  @behaviour UnifiedUi.Renderer

  alias MyApp.Widgets.StatusBadge
  alias UnifiedUi.Adapters.State
  alias UnifiedUi.Adapters.Terminal

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:terminal, config: opts)
    {:ok, State.put_root(renderer_state, convert_iur(iur_tree))}
  end

  @impl true
  def update(iur_tree, renderer_state, _opts \\ []) do
    {:ok, State.put_root(renderer_state, convert_iur(iur_tree))}
  end

  @impl true
  def destroy(_renderer_state), do: :ok

  defp convert_iur(%StatusBadge{label: label, value: value}) do
    %UnifiedIUR.Widgets.Text{content: "#{label}: #{inspect(value)}"}
    |> Terminal.convert_iur()
  end

defp convert_iur(other), do: Terminal.convert_iur(other)
end
```

## Creating Custom Layouts

### 1. Define a custom layout target struct + protocol implementation

Custom layouts should expose children through `UnifiedIUR.Element` so renderers can traverse the tree:

```elixir
defmodule MyApp.Layouts.Flow do
  defstruct [
    :id,
    :gap,
    :direction,
    :style,
    children: [],
    visible: true
  ]

  @type t :: %__MODULE__{
          id: atom() | nil,
          gap: non_neg_integer() | nil,
          direction: :horizontal | :vertical,
          style: UnifiedIUR.Style.t() | nil,
          children: [term()],
          visible: boolean()
        }
end

defimpl UnifiedIUR.Element, for: MyApp.Layouts.Flow do
  def children(layout), do: layout.children

  def metadata(layout) do
    %{
      type: :flow,
      id: layout.id,
      gap: layout.gap,
      direction: layout.direction,
      visible: layout.visible,
      style: layout.style
    }
  end
end
```

### 2. (Core path) Define a DSL entity for the layout

For core integration, define a Spark entity with recursive children support:

```elixir
defmodule MyApp.Layouts.Flow do
  defstruct [:id, :gap, :direction, :style, children: [], visible: true]
end

defmodule MyApp.Dsl.Entities.CustomLayouts do
  @flow_entity %Spark.Dsl.Entity{
    name: :flow,
    target: MyApp.Layouts.Flow,
    recursive_as: :children,
    args: [],
    schema: [
      id: [type: :atom, required: false],
      gap: [type: :non_neg_integer, required: false, default: 1],
      direction: [type: {:one_of, [:horizontal, :vertical]}, required: false, default: :horizontal],
      style: [type: :keyword_list, required: false],
      visible: [type: :boolean, required: false, default: true]
    ],
    entities: [
      children: [
        UnifiedUi.Dsl.Entities.Layouts.vbox_entity(),
        UnifiedUi.Dsl.Entities.Layouts.hbox_entity(),
        UnifiedUi.Dsl.Entities.Widgets.text_entity(),
        UnifiedUi.Dsl.Entities.Widgets.button_entity()
      ]
    ]
  }

  def flow_entity, do: @flow_entity
end
```

Then wire it into DSL sections and `UnifiedUi.IUR.Builder.build_entity/2`.

### 3. Implement the layout algorithm

Keep layout logic pure and testable (inputs in, positioned output out):

```elixir
defmodule MyApp.Layouts.FlowAlgorithm do
  @spec place([{atom(), non_neg_integer()}], :horizontal | :vertical, non_neg_integer()) ::
          [{atom(), non_neg_integer()}]
  def place(items, direction, gap \\ 1)

  def place(items, :horizontal, gap) do
    items
    |> Enum.map_reduce(0, fn {id, width}, cursor ->
      {{id, cursor}, cursor + width + gap}
    end)
    |> elem(0)
  end

  def place(items, :vertical, gap) do
    items
    |> Enum.map_reduce(0, fn {id, height}, cursor ->
      {{id, cursor}, cursor + height + gap}
    end)
    |> elem(0)
  end
end
```

### 4. Add renderer support

Built-in renderers only know built-in layout structs. Add a converter for your layout in a custom renderer (or core renderer patch):

```elixir
defmodule MyApp.Layouts.Flow do
  defstruct [:id, :gap, :direction, :style, children: [], visible: true]
end

defmodule MyApp.Adapters.TerminalWithFlow do
  @behaviour UnifiedUi.Renderer

  alias MyApp.Layouts.Flow
  alias UnifiedUi.Adapters.State
  alias UnifiedUi.Adapters.Terminal

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:terminal, config: opts)
    {:ok, State.put_root(renderer_state, convert_iur(iur_tree))}
  end

  @impl true
  def update(iur_tree, renderer_state, _opts \\ []) do
    {:ok, State.put_root(renderer_state, convert_iur(iur_tree))}
  end

  @impl true
  def destroy(_renderer_state), do: :ok

  defp convert_iur(%Flow{direction: direction, children: children}) do
    rendered_children =
      children
      |> Enum.map(&convert_iur/1)
      |> Enum.reject(&is_nil/1)

    TermUI.Component.Helpers.stack(direction, rendered_children)
  end

defp convert_iur(other), do: Terminal.convert_iur(other)
end
```

## Creating Custom Renderers

### 1. Implement the renderer behavior

Custom renderers implement `UnifiedUi.Renderer` (`render/2`, `update/3`, `destroy/1`) and manage a `UnifiedUi.Adapters.State` value.

```elixir
defmodule MyApp.Adapters.InstrumentedTerminal do
  @behaviour UnifiedUi.Renderer

  alias UnifiedUi.Adapters.State
  alias UnifiedUi.Adapters.Terminal

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:terminal, config: opts)
    root = convert_iur(iur_tree)

    {:ok,
     renderer_state
     |> State.put_root(root)
     |> State.put_metadata(:last_iur, iur_tree)}
  end

  @impl true
  def update(iur_tree, renderer_state, _opts \\ []) do
    if State.get_metadata(renderer_state, :last_iur) == iur_tree do
      {:ok, renderer_state}
    else
      {:ok,
       renderer_state
       |> State.put_root(convert_iur(iur_tree))
       |> State.put_metadata(:last_iur, iur_tree)
       |> State.bump_version()}
    end
  end

  @impl true
  def destroy(_renderer_state), do: :ok

  defp convert_iur(iur_element), do: Terminal.convert_iur(iur_element)
end
```

### 2. Add custom widget conversion

Extend your renderer with explicit conversion clauses for custom widgets, then fall back to a base renderer for built-in types.

```elixir
defmodule MyApp.Widgets.StatusBadge do
  defstruct [:id, :label, :value, :style, visible: true]
end

defmodule MyApp.Adapters.InstrumentedTerminal do
  alias MyApp.Widgets.StatusBadge
  alias UnifiedIUR.Widgets
  alias UnifiedUi.Adapters.Terminal

  defp convert_iur(%StatusBadge{label: label, value: value}) do
    %Widgets.Text{content: "#{label}: #{inspect(value)}"}
    |> Terminal.convert_iur()
  end

  defp convert_iur(other), do: Terminal.convert_iur(other)
end
```

### 3. Handle events and map them to update/2

Renderers should normalize platform events into `Jido.Signal` and pass them to component `update/2`.

```elixir
defmodule MyApp.Adapters.TerminalEventLoop do
  alias UnifiedUi.Adapters.Terminal.Events

  @spec handle_event(module(), map(), Events.event_type(), map()) ::
          {:ok, map()} | {:error, term()}
  def handle_event(screen_module, state, event_type, payload) do
    with {:ok, signal} <- Events.to_signal(event_type, payload) do
      {:ok, screen_module.update(state, signal)}
    end
  end
end
```

### 4. Keep renderer contracts testable

- assert `render/2` returns `{:ok, %UnifiedUi.Adapters.State{}}`
- assert `update/3` is stable for unchanged trees and bumps version on changes
- assert custom-widget conversion clauses produce expected platform nodes
- assert event payloads are normalized via `*.Events.to_signal/3`

## Validation Checklist

- `mix unified_ui.gen.widget ...` produces compiling modules
- `UnifiedIUR.Element.metadata/1` returns correct `:type` and metadata
- renderer output contains expected custom-widget representation
- update cycles (`render/2` then `update/3`) keep custom widget behavior stable
- custom layout metadata includes `:type` and layout properties
- custom layout algorithm has deterministic, unit-testable output
- custom renderer converts custom layout nodes and nested children
- custom renderer callbacks satisfy `UnifiedUi.Renderer` behavior
- event ingress path (`to_signal` -> `update/2`) is covered by tests
