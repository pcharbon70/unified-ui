# Extensions

This guide covers the current extension path for **custom widgets**.

As of `0.1.x`, external packages can define custom IUR widgets and custom renderers, but adding brand-new DSL entities to `use UnifiedUi.Dsl` still requires changes in UnifiedUi core (`Sections`, `IUR.Builder`, and renderers).

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

## Validation Checklist

- `mix unified_ui.gen.widget ...` produces compiling modules
- `UnifiedIUR.Element.metadata/1` returns correct `:type` and metadata
- renderer output contains expected custom-widget representation
- update cycles (`render/2` then `update/3`) keep custom widget behavior stable
