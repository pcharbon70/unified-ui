defmodule UnifiedUi.Renderers.Web do
  @moduledoc """
  Web renderer that converts IUR to HTML/CSS strings.

  This renderer implements the `UnifiedUi.Renderer` behaviour and converts
  Intermediate UI Representation (IUR) elements to HTML strings with inline
  CSS styles and Phoenix LiveView event bindings.

  ## Usage

      # Create an IUR tree
      iur = %VBox{
        children: [
          %Text{content: "Hello"},
          %Button{label: "Click Me", on_click: :clicked}
        ]
      }

      # Render to HTML
      {:ok, state} = Web.render(iur)

      # The state contains the HTML string
      # state.root is the HTML string

  ## HTML Output Structure

  The renderer produces HTML strings with:
  * Semantic HTML5 elements
  * Inline CSS styles
  * Phoenix LiveView phx-event bindings

  ## Style Conversion

  IUR styles are converted to CSS inline styles via `Style.to_css/1`.

  ## Layout Mapping

  * `VBox` → `<div style="display: flex; flex-direction: column; ...">`
  * `HBox` → `<div style="display: flex; flex-direction: row; ...">`

  ## Widget Mapping

  * `Text` → `<span>` with text content and style
  * `Button` → `<button>` with label, phx-click binding
  * `Label` → `<label>` with text, for attribute
  * `TextInput` → `<input>` with type, placeholder, phx-change binding

  ## Phoenix LiveView Integration

  Event handlers are converted to Phoenix LiveView bindings:
  * `on_click: :submit` → `phx-click="submit"`
  * `on_change: :update` → `phx-change="update"`

  """

  @behaviour UnifiedUi.Renderer

  alias UnifiedUi.Renderers.State
  alias UnifiedUi.Renderers.Web.Style
  alias UnifiedUi.IUR.Element
  alias UnifiedUi.IUR.Widgets
  alias UnifiedUi.IUR.Layouts

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:web, config: opts)

    # Convert IUR tree to HTML string
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
    # HTML is just a string, no cleanup needed
    :ok
  end

  @doc """
  Converts an IUR element to an HTML string.

  ## Parameters

  * `iur_element` - The IUR element to convert
  * `renderer_state` - The renderer state (used for tracking)

  ## Returns

  An HTML string.

  """
  def convert_iur(iur_element, renderer_state \\ %State{}) do
    metadata = Element.metadata(iur_element)
    type = metadata.type
    visible = Map.get(metadata, :visible, true)

    # Skip invisible elements
    if visible == false do
      ""
    else
      convert_by_type(iur_element, type, renderer_state)
    end
  end

  # Widget converters

  defp convert_by_type(%Widgets.Text{} = text, :text, _state) do
    content = escape_html(text.content || "")
    style = Style.to_css(text.style)

    attrs = build_attributes([
      {"style", style}
    ])

    ~s(<span#{attrs}>#{content}</span>)
  end

  defp convert_by_type(%Widgets.Button{} = button, :button, _state) do
    label = escape_html(button.label || "")
    style = Style.to_css(button.style)

    # Build attributes list
    attrs_list = [
      {"style", style}
    ]

    # Add phx-click binding if on_click is present
    attrs_list = if button.on_click do
      event_name = atom_to_event_name(button.on_click)
      [{"phx-click", event_name} | attrs_list]
    else
      attrs_list
    end

    # Add disabled attribute
    attrs_list = if button.disabled, do: [{"disabled", "true"} | attrs_list], else: attrs_list

    # Add id if present
    attrs_list = if button.id, do: [{"id", button.id} | attrs_list], else: attrs_list

    attrs = build_attributes(attrs_list)

    ~s(<button#{attrs}>#{label}</button>)
  end

  defp convert_by_type(%Widgets.Label{} = label, :label, _state) do
    text = escape_html(label.text || "")
    style = Style.to_css(label.style)

    # Build attributes list
    attrs_list = [
      {"style", style}
    ]

    # Add for attribute if present
    attrs_list = if label.for do
      [{"for", label.for} | attrs_list]
    else
      attrs_list
    end

    attrs = build_attributes(attrs_list)

    ~s(<label#{attrs}>#{text}</label>)
  end

  defp convert_by_type(%Widgets.TextInput{} = input, :text_input, _state) do
    style = Style.to_css(input.style)

    # Build attributes list
    attrs_list = [
      {"style", style},
      {"type", input_type_to_string(input.type)}
    ]

    # Add id if present
    attrs_list = if input.id, do: [{"id", input.id} | attrs_list], else: attrs_list

    # Add value if present
    attrs_list = if input.value, do: [{"value", input.value} | attrs_list], else: attrs_list

    # Add placeholder if present
    attrs_list = if input.placeholder, do: [{"placeholder", input.placeholder} | attrs_list], else: attrs_list

    # Add phx-change binding if on_change is present
    attrs_list = if input.on_change do
      event_name = atom_to_event_name(input.on_change)
      [{"phx-change", event_name} | attrs_list]
    else
      attrs_list
    end

    # Add disabled attribute
    attrs_list = if input.disabled, do: [{"disabled", "true"} | attrs_list], else: attrs_list

    # Add form_id if present
    attrs_list = if input.form_id, do: [{"form", input.form_id} | attrs_list], else: attrs_list

    attrs = build_attributes(attrs_list)

    # Self-closing input tag
    ~s(<input#{attrs} />)
  end

  # Data visualization converters

  defp convert_by_type(%Widgets.Gauge{} = gauge, :gauge, _state) do
    # Calculate gauge dimensions
    min_val = gauge.min || 0
    max_val = gauge.max || 100
    value = max(min_val, min(max_val, gauge.value))
    range = max_val - min_val
    percentage = if range > 0, do: (value - min_val) / range * 100, else: 0

    width = gauge.width || 200
    height = gauge.height || 20

    # Build SVG gauge
    svg_content = """
    <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
      <rect x="0" y="0" width="#{width}" height="#{height}" fill="#e0e0e0" rx="4"/>
      <rect x="0" y="0" width="#{width * percentage / 100}" height="#{height}" fill="#4CAF50" rx="4">
        <animate attributeName="width" from="0" to="#{width * percentage / 100}" dur="0.5s" fill="freeze"/>
      </rect>
      <text x="#{width / 2}" y="#{height / 2 + 5}" text-anchor="middle" font-size="12" fill="#333">#{value}/#{max_val}</text>
    </svg>
    """

    # Wrap with label if present
    if gauge.label do
      ~s(<div class="gauge-container">) <>
      escape_html(gauge.label) <>
      ~s(</div>) <>
      svg_content
    else
      svg_content
    end
  end

  defp convert_by_type(%Widgets.Sparkline{} = sparkline, :sparkline, _state) do
    data = sparkline.data || []
    width = sparkline.width || 200
    height = sparkline.height || 50

    # Generate SVG sparkline
    svg_content = if length(data) > 1 do
      min_val = Enum.min(data)
      max_val = Enum.max(data)
      range = max_val - min_val

      # Build points for polyline
      points = data
      |> Enum.with_index()
      |> Enum.map(fn {val, idx} ->
        x = idx * (width / max(length(data) - 1, 1))
        y = if range > 0 do
          height - ((val - min_val) / range * height)
        else
          height / 2
        end
        "#{x},#{y}"
      end)
      |> Enum.join(" ")

      # Build area polygon if show_area
      area_polygon = if sparkline.show_area do
        "<polygon points=\"0,#{height} " <> points <> " #{width},#{height}\" fill=\"rgba(76, 175, 80, 0.2)\"/>"
      else
        ""
      end

      # Build color
      color = case sparkline.color do
        :cyan -> "#00BCD4"
        :green -> "#4CAF50"
        :blue -> "#2196F3"
        :red -> "#F44336"
        :yellow -> "#FFEB3B"
        _ -> "#4CAF50"
      end

      "<svg width=\"#{width}\" height=\"#{height}\" xmlns=\"http://www.w3.org/2000/svg\">" <>
        area_polygon <>
        "<polyline points=\"" <> points <> "\" fill=\"none\" stroke=\"" <> color <> "\" stroke-width=\"2\"/>" <>
        "</svg>"
    else
      ~s(<span>No data</span>)
    end

    svg_content
  end

  defp convert_by_type(%Widgets.BarChart{} = chart, :bar_chart, _state) do
    data = chart.data || []
    width = chart.width || 300
    height = chart.height || 200

    # Generate SVG bar chart
    svg_content = if length(data) > 0 do
      max_val = data |> Enum.map(fn {_, v} -> v end) |> Enum.max(fn -> 0 end)

      bar_width = if chart.orientation == :horizontal do
        width / max(length(data), 1) - 10
      else
        width / max(length(data), 1) - 10
      end

      bars = if chart.orientation == :horizontal do
        # Horizontal bars
        Enum.with_index(data)
        |> Enum.map(fn {{label, value}, idx} ->
          bar_width_px = if max_val > 0, do: (value / max_val * (width - 80)), else: 0
          y = idx * 30 + 10
          """
            <text x="0" y="#{y + 15}" font-size="12">#{escape_html(label)}</text>
            <rect x="70" y="#{y}" width="#{bar_width_px}" height="20" fill="#2196F3" rx="2">
              <animate attributeName="width" from="0" to="#{bar_width_px}" dur="0.5s" fill="freeze"/>
            </rect>
            <text x="#{bar_width_px + 75}" y="#{y + 15}" font-size="12">#{value}</text>
          """
        end)
        |> Enum.join("\n")
      else
        # Vertical bars
        Enum.with_index(data)
        |> Enum.map(fn {{label, value}, idx} ->
          bar_height_px = if max_val > 0, do: (value / max_val * (height - 40)), else: 0
          x = idx * (width / max(length(data), 1)) + 10
          y = height - bar_height_px - 30
          """
            <rect x="#{x}" y="#{y}" width="#{bar_width}" height="#{bar_height_px}" fill="#2196F3" rx="2">
              <animate attributeName="height" from="0" to="#{bar_height_px}" dur="0.5s" fill="freeze"/>
              <animate attributeName="y" from="#{height - 30}" to="#{y}" dur="0.5s" fill="freeze"/>
            </rect>
            <text x="#{x + bar_width / 2}" y="#{height - 10}" text-anchor="middle" font-size="10">#{escape_html(String.slice(label, 0, 5))}</text>
          """
        end)
        |> Enum.join("\n")
      end

      """
      <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
        #{bars}
      </svg>
      """
    else
      ~s(<span>No data</span>)
    end

    svg_content
  end

  defp convert_by_type(%Widgets.LineChart{} = chart, :line_chart, _state) do
    data = chart.data || []
    width = chart.width || 300
    height = chart.height || 200

    # Generate SVG line chart
    svg_content = if length(data) > 1 do
      min_val = data |> Enum.map(fn {_, v} -> v end) |> Enum.min()
      max_val = data |> Enum.map(fn {_, v} -> v end) |> Enum.max()
      range = max_val - min_val

      # Build points for polyline
      points = data
      |> Enum.with_index()
      |> Enum.map(fn {{_label, val}, idx} ->
        x = idx * (width / max(length(data) - 1, 1))
        y = if range > 0 do
          height - 30 - ((val - min_val) / range * (height - 50))
        else
          height / 2
        end
        "#{x},#{y}"
      end)
      |> Enum.join(" ")

      # Build area polygon if show_area
      area_polygon = if chart.show_area do
        "<polygon points=\"0,#{height - 30} " <> points <> " #{width},#{height - 30}\" fill=\"rgba(33, 150, 243, 0.2)\"/>"
      else
        ""
      end

      # Build dots if show_dots
      dots = if chart.show_dots do
        data
        |> Enum.with_index()
        |> Enum.map(fn {{_label, val}, idx} ->
          x = idx * (width / max(length(data) - 1, 1))
          y = if range > 0 do
            height - 30 - ((val - min_val) / range * (height - 50))
          else
            height / 2
          end
          "<circle cx=\"#{x}\" cy=\"#{y}\" r=\"4\" fill=\"#2196F3\"/>"
        end)
        |> Enum.join("\n")
      else
        ""
      end

      # Build labels
      labels = if length(data) <= 10 do
        data
        |> Enum.with_index()
        |> Enum.map(fn {{label, _val}, idx} ->
          x = idx * (width / max(length(data) - 1, 1))
          escaped_label = escape_html(String.slice(label, 0, 6))
          "<text x=\"#{x}\" y=\"#{height - 5}\" text-anchor=\"middle\" font-size=\"10\">#{escaped_label}</text>"
        end)
        |> Enum.join("\n")
      else
        ""
      end

      "<svg width=\"#{width}\" height=\"#{height}\" xmlns=\"http://www.w3.org/2000/svg\">" <>
        area_polygon <>
        "<polyline points=\"" <> points <> "\" fill=\"none\" stroke=\"#2196F3\" stroke-width=\"2\"/>" <>
        dots <>
        labels <>
        "</svg>"
    else
      ~s(<span>No data</span>)
    end

    svg_content
  end

  # Layout converters

  defp convert_by_type(%Layouts.VBox{} = vbox, :vbox, state) do
    children_html = convert_children(vbox.children, state)

    # Build CSS styles
    css_parts = ["display: flex", "flex-direction: column"]

    css_parts = maybe_add_spacing_css(css_parts, vbox.spacing)
    css_parts = maybe_add_padding_css(css_parts, vbox.padding)
    css_parts = maybe_add_align_items_css(css_parts, vbox.align_items, :column)
    css_parts = maybe_add_justify_content_css(css_parts, vbox.justify_content, :column)

    # Add style from IUR style
    style = Style.to_css(vbox.style)
    css_parts = if style do
      [style | css_parts]
    else
      css_parts
    end

    css = Enum.reverse(css_parts) |> Enum.join("; ")

    attrs = build_attributes([{"style", css}])

    ~s(<div#{attrs}>#{children_html}</div>)
  end

  defp convert_by_type(%Layouts.HBox{} = hbox, :hbox, state) do
    children_html = convert_children(hbox.children, state)

    # Build CSS styles
    css_parts = ["display: flex", "flex-direction: row"]

    css_parts = maybe_add_spacing_css(css_parts, hbox.spacing)
    css_parts = maybe_add_padding_css(css_parts, hbox.padding)
    css_parts = maybe_add_align_items_css(css_parts, hbox.align_items, :row)
    css_parts = maybe_add_justify_content_css(css_parts, hbox.justify_content, :row)

    # Add style from IUR style
    style = Style.to_css(hbox.style)
    css_parts = if style do
      [style | css_parts]
    else
      css_parts
    end

    css = Enum.reverse(css_parts) |> Enum.join("; ")

    attrs = build_attributes([{"style", css}])

    ~s(<div#{attrs}>#{children_html}</div>)
  end

  # Fallback for unknown types
  defp convert_by_type(_element, _type, _state) do
    # Return empty span for unknown element types
    "<span></span>"
  end

  # Helper functions

  defp convert_children(children, state) when is_list(children) do
    children
    |> Enum.map(fn child -> convert_iur(child, state) end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join()
  end

  defp convert_children(_, _state), do: ""

  # Build HTML attributes string
  defp build_attributes(attrs_list) do
    attrs_list
    |> Enum.reject(fn {_, value} -> is_nil(value) or value == "" end)
    |> Enum.map(fn {name, value} -> " #{name}=\"#{escape_html(value)}\"" end)
    |> Enum.join()
  end

  # Spacing in CSS (using gap property for flexbox)
  defp maybe_add_spacing_css(css_parts, nil), do: css_parts
  defp maybe_add_spacing_css(css_parts, spacing) when is_integer(spacing),
    do: ["gap: #{spacing}px" | css_parts]

  # Padding in CSS
  defp maybe_add_padding_css(css_parts, nil), do: css_parts
  defp maybe_add_padding_css(css_parts, padding) when is_integer(padding),
    do: ["padding: #{padding}px" | css_parts]

  # Alignment mapping to CSS
  # For flexbox, align-items controls cross-axis alignment
  defp maybe_add_align_items_css(css_parts, nil, _direction), do: css_parts
  defp maybe_add_align_items_css(css_parts, :start, :column),
    do: ["align-items: flex-start" | css_parts]
  defp maybe_add_align_items_css(css_parts, :center, _direction),
    do: ["align-items: center" | css_parts]
  defp maybe_add_align_items_css(css_parts, :end, :column),
    do: ["align-items: flex-end" | css_parts]
  defp maybe_add_align_items_css(css_parts, :start, :row),
    do: ["align-items: center" | css_parts]
  defp maybe_add_align_items_css(css_parts, :end, :row),
    do: ["align-items: stretch" | css_parts]
  defp maybe_add_align_items_css(css_parts, align, _direction),
    do: ["align-items: #{align}" | css_parts]

  # Justification mapping to CSS
  # For flexbox, justify-content controls main-axis alignment
  defp maybe_add_justify_content_css(css_parts, nil, _direction), do: css_parts
  defp maybe_add_justify_content_css(css_parts, :start, _direction),
    do: ["justify-content: flex-start" | css_parts]
  defp maybe_add_justify_content_css(css_parts, :center, _direction),
    do: ["justify-content: center" | css_parts]
  defp maybe_add_justify_content_css(css_parts, :end, _direction),
    do: ["justify-content: flex-end" | css_parts]
  defp maybe_add_justify_content_css(css_parts, justify, _direction),
    do: ["justify-content: #{justify}" | css_parts]

  # Convert Elixir atom to Phoenix LiveView event name
  defp atom_to_event_name(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> String.replace("_", "-")
  end

  # Handle tuple event handlers like {:submit, %{form: :login}}
  defp atom_to_event_name({event_name, _payload}) when is_atom(event_name) do
    event_name |> Atom.to_string() |> String.replace("_", "-")
  end

  # Handle MFA tuples {Module, :function, args}
  defp atom_to_event_name({_module, _function, _args}) do
    "generic-event"
  end

  # Fallback for other types
  defp atom_to_event_name(other) when is_binary(other), do: other
  defp atom_to_event_name(_other), do: "event"

  # Convert input type atom to HTML type string
  defp input_type_to_string(nil), do: "text"
  defp input_type_to_string(:text), do: "text"
  defp input_type_to_string(:password), do: "password"
  defp input_type_to_string(:email), do: "email"
  defp input_type_to_string(:number), do: "number"
  defp input_type_to_string(:tel), do: "tel"
  defp input_type_to_string(:url), do: "url"
  defp input_type_to_string(:search), do: "search"
  defp input_type_to_string(_), do: "text"

  # Basic HTML escaping
  defp escape_html(nil), do: ""
  defp escape_html(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
  defp escape_html(value), do: value |> to_string() |> escape_html()
end
