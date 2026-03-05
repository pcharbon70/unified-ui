# DSL Reference

This reference documents the currently implemented UnifiedUi DSL sections and entities.

## Module Setup

```elixir
defmodule MyApp.CounterScreen do
  @behaviour UnifiedUi.ElmArchitecture
  use UnifiedUi.Dsl

  state count: 0

  ui do
    vbox spacing: 1 do
      text "Count: #{state.count}"
      button "Increment", on_click: :increment
    end
  end
end
```

## Sections

- `state`: Declares initial state keys and defaults used by `init/1` and `update/2`.
- `ui`: Top-level visual declaration.
- `styles`: Named style definitions (resolved via `style_ref`).
- `signals`: Signal type declarations for intent/event modeling.

## Layout Entities

### `vbox`

Vertical container. Common options:

- `id`
- `spacing`
- `padding`
- `align_items`
- `justify_content`
- `style`
- `visible`

### `hbox`

Horizontal container with the same common layout options as `vbox`.

## Core Widget Entities

### `text`

- Required: text content argument
- Common options: `id`, `style`, `visible`

### `button`

- Required: label argument
- Common options: `id`, `on_click`, `disabled`, `style`, `visible`

`on_click` accepts:

- atom: `:submit`
- tuple: `{:submit, %{form: :login}}`
- MFA tuple: `{MyModule, :handle_submit, []}`

### `label`

- Required: `for`, text content
- Common options: `id`, `style`, `visible`

### `text_input`

- Required: `id`
- Options: `type`, `placeholder`, `value`, `on_change`, `on_submit`, `disabled`, `style`, `visible`

## Data Visualization Widgets

- `gauge`
- `sparkline`
- `bar_chart`
- `line_chart`

## Data + Navigation Widgets

- `table` with nested `column`
- `menu` with nested `menu_item`
- `context_menu` with nested `menu_item`
- `tabs` with nested `tab`
- `tree_view` with nested `tree_node`

## Validation

UnifiedUi runs compile-time verifiers for:

- unique IDs
- layout structure correctness
- signal handler structure
- style references
- state references

## Output Model

DSL declarations are transformed into `UnifiedIUR` structs and then rendered through terminal, desktop, or web adapters.
