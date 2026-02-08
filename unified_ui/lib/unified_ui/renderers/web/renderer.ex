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
