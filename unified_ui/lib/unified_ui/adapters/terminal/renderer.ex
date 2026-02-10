defmodule UnifiedUi.Adapters.Terminal do
  @moduledoc """
  Terminal renderer that converts IUR to TermUI render trees.

  This renderer implements the `UnifiedUi.Renderer` behaviour and converts
  Intermediate UI Representation (IUR) elements to TermUI render nodes.

  ## Usage

      # Create an IUR tree
      iur = %VBox{
        children: [
          %Text{content: "Hello"},
          %Button{label: "Click Me", on_click: :clicked}
        ]
      }

      # Render to TermUI
      {:ok, state} = Terminal.render(iur)

      # The state contains the TermUI render tree
      # state.root is the TermUI render tree

  ## Render Tree Structure

  The renderer produces TermUI render trees using:
  * `TermUI.Component.Helpers.text/2` - Text nodes
  * `TermUI.Component.Helpers.stack/3` - Layout containers
  * Custom nodes for buttons, labels, inputs

  ## Style Conversion

  IUR styles are converted to TermUI styles via `Style.convert_style/1`.

  ## Layout Mapping

  * `VBox` → `stack(:vertical, children, opts)`
  * `HBox` → `stack(:horizontal, children, opts)`

  ## Widget Mapping

  * `Text` → Text node with content and style
  * `Button` → Custom button node with label, style, and on_click handler
  * `Label` → Text node with `:for` reference
  * `TextInput` → Custom input node with value, placeholder, type

  """

  @behaviour UnifiedUi.Renderer

  alias UnifiedUi.Adapters.State
  alias UnifiedUi.Adapters.Terminal.Style
  alias UnifiedUi.IUR.Element
  alias UnifiedUi.IUR.Widgets
  alias UnifiedUi.IUR.Layouts

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:terminal, config: opts)

    # Convert IUR tree to TermUI render tree
    root = convert_iur(iur_tree, renderer_state)

    # Update state with root reference
    renderer_state = State.put_root(renderer_state, root)

    {:ok, renderer_state}
  end

  @impl true
  def update(iur_tree, renderer_state, opts \\ []) do
    # For now, just re-render the entire tree
    # Future optimization: diff and update only changed elements
    render(iur_tree, Keyword.merge(renderer_state.config, opts))
  end

  @impl true
  def destroy(_renderer_state) do
    # TermUI uses pure data structures, no cleanup needed
    :ok
  end

  @doc """
  Converts an IUR element to a TermUI render tree.

  ## Parameters

  * `iur_element` - The IUR element to convert
  * `renderer_state` - The renderer state (used for tracking)

  ## Returns

  A TermUI render tree (tagged tuple or RenderNode struct).

  """
  def convert_iur(iur_element, renderer_state \\ %State{}) do
    metadata = Element.metadata(iur_element)
    type = metadata.type
    visible = Map.get(metadata, :visible, true)

    # Skip invisible elements
    if visible == false do
      nil
    else
      convert_by_type(iur_element, type, renderer_state)
    end
  end

  # Widget converters

  defp convert_by_type(%Widgets.Text{} = text, :text, _state) do
    content = text.content || ""
    style = Style.convert_style(text.style)

    # Create text node with optional style
    if style do
      TermUI.Component.Helpers.text(content, style)
    else
      TermUI.Component.Helpers.text(content)
    end
  end

  defp convert_by_type(%Widgets.Button{} = button, :button, _state) do
    label = button.label || ""
    style = Style.convert_style(button.style)

    # Create button text representation
    button_text = "[ #{label} ]"

    # Create text node first
    text_node = TermUI.Component.Helpers.text(button_text)

    # Apply style if present
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Add metadata for event handling
    if button.on_click do
      {:button, styled_node, %{
        on_click: button.on_click,
        id: button.id,
        disabled: button.disabled
      }}
    else
      styled_node
    end
  end

  defp convert_by_type(%Widgets.Label{} = label, :label, _state) do
    text = label.text || ""
    style = Style.convert_style(label.style)

    # Create text node
    text_node = TermUI.Component.Helpers.text(text)

    # Apply style if present
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Add for reference if present
    if label.for do
      {:label, styled_node, %{for: label.for, id: label.id}}
    else
      styled_node
    end
  end

  defp convert_by_type(%Widgets.TextInput{} = input, :text_input, _state) do
    # Build placeholder/value display
    display_value = cond do
      input.value -> input.value
      input.placeholder -> "[#{input.placeholder}]"
      true -> "[________________]"
    end

    # Add visual indicator for input type
    type_indicator = case input.type do
      :password -> "*"
      :email -> "@"
      :number -> "#"
      :tel -> "T"
      _ -> ":"
    end

    display = "#{type_indicator} #{display_value}"

    # Create text node for the input display
    text_node = TermUI.Component.Helpers.text(display)

    # Apply style if present
    style = Style.convert_style(input.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with input metadata
    {:text_input, styled_node, %{
      id: input.id,
      value: input.value,
      placeholder: input.placeholder,
      type: input.type,
      on_change: input.on_change,
      on_submit: input.on_submit,
      disabled: input.disabled,
      form_id: input.form_id
    }}
  end

  # Data visualization converters

  defp convert_by_type(%Widgets.Gauge{} = gauge, :gauge, _state) do
    # Calculate percentage and bar width
    min_val = gauge.min || 0
    max_val = gauge.max || 100
    value = max(min_val, min(max_val, gauge.value))
    range = max_val - min_val
    percentage = if range > 0, do: (value - min_val) / range, else: 0
    bar_width = round(percentage * 20)  # 20 character bar

    # Build the bar string
    filled = String.duplicate("=", bar_width)
    empty = String.duplicate(" ", 20 - bar_width)
    bar = "[#{filled}#{empty}]"

    # Add label if present
    label_text = if gauge.label, do: "#{gauge.label}: ", else: ""

    # Build display text
    display_text = "#{label_text}#{bar} #{gauge.value}/#{max_val}"

    # Create text node
    text_node = TermUI.Component.Helpers.text(display_text)

    # Apply style if present
    style = Style.convert_style(gauge.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with metadata
    {:gauge, styled_node, %{
      id: gauge.id,
      value: gauge.value,
      min: min_val,
      max: max_val,
      label: gauge.label
    }}
  end

  defp convert_by_type(%Widgets.Sparkline{} = sparkline, :sparkline, _state) do
    data = sparkline.data || []

    # Generate ASCII sparkline
    sparkline_text = if length(data) > 1 do
      min_val = Enum.min(data)
      max_val = Enum.max(data)
      range = max_val - min_val

      chars = ["_", "", "-", ".", "o", "O", "@", "#"]

      points = Enum.map(data, fn val ->
        if range > 0 do
          normalized = (val - min_val) / range
          index = min(trunc(normalized * length(chars)), length(chars) - 1)
          Enum.at(chars, index)
        else
          ""
        end
      end)

      Enum.join(points)
    else
      ""
    end

    # Create text node
    text_node = TermUI.Component.Helpers.text(sparkline_text)

    # Apply style if present
    style = Style.convert_style(sparkline.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with metadata
    {:sparkline, styled_node, %{
      id: sparkline.id,
      data: data,
      show_dots: sparkline.show_dots,
      show_area: sparkline.show_area
    }}
  end

  defp convert_by_type(%Widgets.BarChart{} = chart, :bar_chart, _state) do
    data = chart.data || []

    # Find max value for scaling
    max_val = if length(data) > 0 do
      data |> Enum.map(fn {_, v} -> v end) |> Enum.max(fn -> 0 end)
    else
      0
    end

    # Build bar lines based on orientation
    lines = if chart.orientation == :horizontal do
      # Horizontal bars
      Enum.map(data, fn {label, value} ->
        bar_width = if max_val > 0, do: round(value / max_val * 20), else: 0
        bar = String.duplicate("=", bar_width)
        formatted_label = String.pad_trailing(label, 10)
        "#{formatted_label} [#{bar}] #{value}"
      end)
    else
      # Vertical bars (simplified ASCII representation)
      if length(data) > 0 do
        max_value = max_val
        num_bars = min(length(data), 10)

        # Build from top to bottom
        Enum.map(max_value..0//-1, fn y ->
          bars_at_level = Enum.map(0..(num_bars - 1), fn i ->
            if i < length(data) do
              {_, val} = Enum.at(data, i)
              threshold = (y + 1) * max_value / 5
              if val >= threshold, do: "|", else: " "
            else
              " "
            end
          end)
          "#{String.pad_leading(Integer.to_string(y * 20), 4)} |#{Enum.join(bars_at_level, " ")}|"
        end) ++ ["      #{Enum.map(0..(num_bars - 1), fn _ -> "--" end) |> Enum.join(" ")}"]
      else
        ["No data"]
      end
    end

    display_text = Enum.join(lines, "\n")

    # Create text node
    text_node = TermUI.Component.Helpers.text(display_text)

    # Apply style if present
    style = Style.convert_style(chart.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with metadata
    {:bar_chart, styled_node, %{
      id: chart.id,
      data: data,
      orientation: chart.orientation,
      show_labels: chart.show_labels
    }}
  end

  defp convert_by_type(%Widgets.LineChart{} = chart, :line_chart, _state) do
    data = chart.data || []

    # Generate ASCII line chart
    chart_text = if length(data) > 1 do
      min_val = Enum.map(data, fn {_, v} -> v end) |> Enum.min()
      max_val = Enum.map(data, fn {_, v} -> v end) |> Enum.max()
      range = max_val - min_val

      # Create a simple line chart with height of 5 lines
      height = 5
      width = length(data)

      # Build grid
      grid = for y <- (height - 1)..0//-1 do
        row = for x <- 0..(width - 1) do
          if x < length(data) do
            {_, val} = Enum.at(data, x)
            y_level = if range > 0 do
              round((val - min_val) / range * (height - 1))
            else
              0
            end

            if y == y_level do
              if chart.show_dots, do: "o", else: "*"
            else
              " "
            end
          else
            " "
          end
        end
        Enum.join(row)
      end

      # Add labels if requested
      x_labels = if chart.show_labels do
        labels = Enum.map(data, fn {label, _} ->
          String.slice(label, 0, 3) |> String.pad_trailing(4)
        end)
        Enum.join(labels)
      else
        ""
      end

      Enum.join(grid, "\n") <> "\n" <> x_labels
    else
      "No data"
    end

    # Create text node
    text_node = TermUI.Component.Helpers.text(chart_text)

    # Apply style if present
    style = Style.convert_style(chart.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with metadata
    {:line_chart, styled_node, %{
      id: chart.id,
      data: data,
      show_dots: chart.show_dots,
      show_area: chart.show_area
    }}
  end

  defp convert_by_type(%Widgets.Table{} = table, :table, _state) do
    data = table.data || []
    columns = table.columns || []

    # Auto-generate columns from first row if not provided
    columns = if columns == [] and length(data) > 0 do
      first_row = hd(data)
      first_row
      |> extract_keys()
      |> Enum.map(fn key ->
        %Widgets.Column{
          key: key,
          header: to_string(key) |> String.capitalize(),
          sortable: true,
          align: :left
        }
      end)
    else
      columns
    end

    # Sort data if sort_column is specified
    data = if table.sort_column do
      UnifiedUi.Table.Sort.sort_data(data, table.sort_column, table.sort_direction)
    else
      data
    end

    # Build ASCII table
    table_text = if length(columns) > 0 do
      # Calculate column widths
      col_widths = Enum.map(columns, fn col ->
        header_width = String.length(col.header || "")
        max_data_width = data
        |> Enum.map(fn row ->
          value = UnifiedUi.Table.Sort.get_value(row, col.key)
          formatted = apply_formatter(col.formatter, value)
          String.length(formatted)
        end)
        |> Enum.max(fn -> 0 end)

        max(header_width, max_data_width)
        |> min(col.width || 999)
      end)

      # Build header row
      header_cells = Enum.zip(columns, col_widths)
      |> Enum.map(fn {col, width} ->
        sort_indicator = if table.sort_column == col.key do
          if table.sort_direction == :asc, do: " ↑", else: " ↓"
        else
          ""
        end
        align_text(col.header || "", width, col.align) <> sort_indicator
      end)

      # Build separator
      separator = Enum.map(col_widths, fn width ->
        String.duplicate("-", width + 2)
      end) |> Enum.join("+")

      # Build data rows
      data_rows = Enum.with_index(data)
      |> Enum.map(fn {row, idx} ->
        cells = Enum.zip(columns, col_widths)
        |> Enum.map(fn {col, width} ->
          value = UnifiedUi.Table.Sort.get_value(row, col.key)
          formatted = apply_formatter(col.formatter, value)
          align_text(formatted, width, col.align)
        end)

        # Highlight selected row
        row_text = "| " <> Enum.join(cells, " | ") <> " |"

        if table.selected_row == idx do
          # Use reverse attribute for selection (would need style support)
          row_text
        else
          row_text
        end
      end)

      # Combine all parts
      header = "| " <> Enum.join(header_cells, " | ") <> " |"
      rows = [separator, header, separator] ++ data_rows ++ [separator]

      Enum.join(rows, "\n")
    else
      "No columns defined"
    end

    # Create text node
    text_node = TermUI.Component.Helpers.text(table_text)

    # Apply style if present
    style = Style.convert_style(table.style)
    styled_node = if style do
      TermUI.Component.Helpers.styled(text_node, style)
    else
      text_node
    end

    # Wrap with metadata for event handling
    {:table, styled_node, %{
      id: table.id,
      columns: columns,
      data: data,
      selected_row: table.selected_row,
      on_row_select: table.on_row_select,
      on_sort: table.on_sort,
      sort_column: table.sort_column,
      sort_direction: table.sort_direction
    }}
  end

  # Layout converters

  defp convert_by_type(%Layouts.VBox{} = vbox, :vbox, state) do
    children = convert_children(vbox.children, state)

    # Build stack options
    opts = []
    |> maybe_add_spacing(vbox.spacing)
    |> maybe_add_padding(vbox.padding)
    |> maybe_add_align(vbox.align_items)
    |> maybe_add_justify(vbox.justify_content)

    # Add style if present
    style = Style.convert_style(vbox.style)

    stack_node = TermUI.Component.Helpers.stack(:vertical, children, opts)

    if style do
      TermUI.Component.Helpers.styled(stack_node, style)
    else
      stack_node
    end
  end

  defp convert_by_type(%Layouts.HBox{} = hbox, :hbox, state) do
    children = convert_children(hbox.children, state)

    # Build stack options
    opts = []
    |> maybe_add_spacing(hbox.spacing)
    |> maybe_add_padding(hbox.padding)
    |> maybe_add_align(hbox.align_items)
    |> maybe_add_justify(hbox.justify_content)

    # Add style if present
    style = Style.convert_style(hbox.style)

    stack_node = TermUI.Component.Helpers.stack(:horizontal, children, opts)

    if style do
      TermUI.Component.Helpers.styled(stack_node, style)
    else
      stack_node
    end
  end

  # Fallback for unknown types
  defp convert_by_type(_element, _type, _state) do
    # Return empty node for unknown element types
    TermUI.Component.Helpers.empty()
  end

  # Helper functions

  defp convert_children(children, state) when is_list(children) do
    children
    |> Enum.map(fn child -> convert_iur(child, state) end)
    |> Enum.reject(&is_nil/1)
  end

  defp convert_children(_, _state), do: []

  defp maybe_add_spacing(opts, nil), do: opts
  defp maybe_add_spacing(opts, spacing) when is_integer(spacing), do: Keyword.put(opts, :spacing, spacing)

  defp maybe_add_padding(opts, nil), do: opts
  defp maybe_add_padding(opts, padding) when is_integer(padding), do: Keyword.put(opts, :padding, padding)

  defp maybe_add_align(opts, nil), do: opts
  defp maybe_add_align(opts, align), do: Keyword.put(opts, :align, align)

  defp maybe_add_justify(opts, nil), do: opts
  defp maybe_add_justify(opts, justify), do: Keyword.put(opts, :justify, justify)

  # Table rendering helpers

  defp extract_keys(row) when is_map(row) do
    row |> Map.keys() |> Enum.sort()
  end

  defp extract_keys(row) when is_list(row) do
    Keyword.keys(row)
  end

  defp apply_formatter(nil, value), do: format_value(value)
  defp apply_formatter(formatter, value) when is_function(formatter, 1), do: formatter.(value)
  defp apply_formatter(_formatter, value), do: format_value(value)

  defp format_value(nil), do: ""
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_atom(value), do: to_string(value)
  defp format_value(value), do: inspect(value, limit: 50)

  defp align_text(text, width, :left), do: String.pad_trailing(to_string(text), width)
  defp align_text(text, width, :right), do: String.pad_leading(to_string(text), width)
  defp align_text(text, width, :center) do
    str = to_string(text)
    padding = width - String.length(str)
    left_pad = div(padding, 2)
    right_pad = padding - left_pad
    String.duplicate(" ", left_pad) <> str <> String.duplicate(" ", right_pad)
  end
end
