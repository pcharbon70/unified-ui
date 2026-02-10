defprotocol UnifiedUi.IUR.Element do
  @moduledoc """
  Protocol for accessing properties of Intermediate UI Representation elements.

  The IUR (Intermediate UI Representation) is a tree of platform-agnostic
  structs that represent UI elements. This protocol provides polymorphic
  access to the structure of these elements, allowing renderers to
  traverse and inspect the UI tree without knowing the specific types.

  ## Protocol Functions

  * `children/1` - Returns a list of child elements for tree traversal
  * `metadata/1` - Returns a map of element properties (id, style, etc.)

  ## Example

  ```elixir
  # For a layout with children
  vbox = %UnifiedUi.IUR.Layouts.VBox{
    children: [%Text{content: "Hello"}],
    id: :container
  }

  UnifiedUi.IUR.Element.children(vbox)
  # => [%UnifiedUi.IUR.Widgets.Text{content: "Hello", ...}]

  UnifiedUi.IUR.Element.metadata(vbox)
  # => %{id: :container, type: :vbox}
  ```

  ## Implementing for Custom Elements

  Custom widgets and layouts should implement this protocol to work
  with the rendering system:

  ```elixir
  defimpl UnifiedUi.IUR.Element, for: MyCustomWidget do
    def children(_widget), do: []
    def metadata(widget), do: %{id: widget.id, type: :custom}
  end
  ```

  ## Renderer Contract

  Platform-specific renderers (Terminal, Desktop, Web) should:
  1. Use `children/1` to traverse the UI tree
  2. Use `metadata/1` to access element properties
  3. Not depend on specific struct implementations
  """

  @doc """
  Returns the list of child elements for this UI element.

  For widgets, this is typically an empty list.
  For layouts, this returns the contained widgets and nested layouts.

  ## Examples

      iex> Element.children(%Text{content: "Hi"})
      []

      iex> Element.children(%VBox{children: [%Text{}, %Button{}]})
      [%Text{...}, %Button{...}]
  """
  @spec children(t()) :: [t()]
  def children(element)

  @doc """
  Returns a map of metadata about this element.

  The metadata map should include:
  * `:id` - The element's identifier (if present)
  * `:type` - The element type (e.g., `:text`, `:button`, `:vbox`)
  * Additional keys as needed for rendering

  ## Examples

      iex> Element.metadata(%Text{id: :greeting})
      %{id: :greeting, type: :text}

      iex> Element.metadata(%VBox{id: :main, spacing: 1})
      %{id: :main, type: :vbox, spacing: 1}
  """
  @spec metadata(t()) :: map()
  def metadata(element)
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Text do
  import UnifiedUi.IUR.ElementHelpers

  def children(_text), do: []

  def metadata(text) do
    build_metadata(%{type: :text, visible: text.visible}, id: text.id, style: text.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Button do
  import UnifiedUi.IUR.ElementHelpers

  def children(_button), do: []

  def metadata(button) do
    %{
      type: :button,
      label: button.label,
      on_click: button.on_click,
      disabled: button.disabled,
      visible: button.visible
    }
    |> build_metadata(id: button.id, style: button.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Label do
  import UnifiedUi.IUR.ElementHelpers

  def children(_label), do: []

  def metadata(label) do
    %{type: :label, for: label.for, text: label.text, visible: label.visible}
    |> build_metadata(id: label.id, style: label.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.TextInput do
  import UnifiedUi.IUR.ElementHelpers

  def children(_input), do: []

  def metadata(input) do
    %{
      type: :text_input,
      id: input.id,
      value: input.value,
      placeholder: input.placeholder,
      input_type: input.type,
      on_change: input.on_change,
      on_submit: input.on_submit,
      disabled: input.disabled,
      visible: input.visible
    }
    |> build_metadata(style: input.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Layouts.VBox do
  import UnifiedUi.IUR.ElementHelpers

  def children(vbox), do: vbox.children

  def metadata(vbox) do
    %{
      type: :vbox,
      spacing: vbox.spacing,
      align_items: vbox.align_items,
      justify_content: vbox.justify_content,
      padding: vbox.padding,
      visible: vbox.visible
    }
    |> build_metadata(id: vbox.id, style: vbox.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Layouts.HBox do
  import UnifiedUi.IUR.ElementHelpers

  def children(hbox), do: hbox.children

  def metadata(hbox) do
    %{
      type: :hbox,
      spacing: hbox.spacing,
      align_items: hbox.align_items,
      justify_content: hbox.justify_content,
      padding: hbox.padding,
      visible: hbox.visible
    }
    |> build_metadata(id: hbox.id, style: hbox.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Gauge do
  import UnifiedUi.IUR.ElementHelpers

  def children(_gauge), do: []

  def metadata(gauge) do
    %{
      type: :gauge,
      id: gauge.id,
      value: gauge.value,
      min: gauge.min,
      max: gauge.max,
      label: gauge.label,
      width: gauge.width,
      height: gauge.height,
      color_zones: gauge.color_zones,
      visible: gauge.visible
    }
    |> build_metadata(style: gauge.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Sparkline do
  import UnifiedUi.IUR.ElementHelpers

  def children(_sparkline), do: []

  def metadata(sparkline) do
    %{
      type: :sparkline,
      id: sparkline.id,
      data: sparkline.data,
      width: sparkline.width,
      height: sparkline.height,
      color: sparkline.color,
      show_dots: sparkline.show_dots,
      show_area: sparkline.show_area,
      visible: sparkline.visible
    }
    |> build_metadata(style: sparkline.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.BarChart do
  import UnifiedUi.IUR.ElementHelpers

  def children(_bar_chart), do: []

  def metadata(bar_chart) do
    %{
      type: :bar_chart,
      id: bar_chart.id,
      data: bar_chart.data,
      width: bar_chart.width,
      height: bar_chart.height,
      orientation: bar_chart.orientation,
      show_labels: bar_chart.show_labels,
      visible: bar_chart.visible
    }
    |> build_metadata(style: bar_chart.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.LineChart do
  import UnifiedUi.IUR.ElementHelpers

  def children(_line_chart), do: []

  def metadata(line_chart) do
    %{
      type: :line_chart,
      id: line_chart.id,
      data: line_chart.data,
      width: line_chart.width,
      height: line_chart.height,
      show_dots: line_chart.show_dots,
      show_area: line_chart.show_area,
      visible: line_chart.visible
    }
    |> build_metadata(style: line_chart.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Column do
  import UnifiedUi.IUR.ElementHelpers

  def children(_column), do: []

  def metadata(column) do
    %{
      type: :column,
      key: column.key,
      header: column.header,
      sortable: column.sortable,
      formatter: column.formatter,
      width: column.width,
      align: column.align
    }
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Table do
  import UnifiedUi.IUR.ElementHelpers

  def children(_table), do: []

  def metadata(table) do
    %{
      type: :table,
      id: table.id,
      data: table.data,
      columns: table.columns,
      selected_row: table.selected_row,
      height: table.height,
      on_row_select: table.on_row_select,
      on_sort: table.on_sort,
      sort_column: table.sort_column,
      sort_direction: table.sort_direction,
      visible: table.visible
    }
    |> build_metadata(style: table.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: Any do
  def children(_element), do: []

  def metadata(_element), do: %{type: :unknown}
end
