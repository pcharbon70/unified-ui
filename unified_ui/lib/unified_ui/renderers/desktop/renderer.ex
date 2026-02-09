defmodule UnifiedUi.Renderers.Desktop do
  @moduledoc """
  Desktop renderer that converts IUR to DesktopUi-style widget trees.

  This renderer implements the `UnifiedUi.Renderer` behaviour and converts
  Intermediate UI Representation (IUR) elements to DesktopUi-compatible widget maps.

  ## Usage

      # Create an IUR tree
      iur = %VBox{
        children: [
          %Text{content: "Hello"},
          %Button{label: "Click Me", on_click: :clicked}
        ]
      }

      # Render to DesktopUi-style widgets
      {:ok, state} = Desktop.render(iur)

      # The state contains the DesktopUi widget tree
      # state.root is the DesktopUi widget tree

  ## Widget Tree Structure

  The renderer produces DesktopUi-style widget maps with:
  * `:type` - Widget type (`:label`, `:button`, `:container`)
  * `:id` - Optional unique identifier
  * `:props` - Widget properties (keyword list)
  * `:children` - Child widgets (for containers)

  ## Style Conversion

  IUR styles are converted to DesktopUi widget properties via `Style.to_props/1`.

  ## Layout Mapping

  * `VBox` → `%{type: :container, direction: :vbox, ...}`
  * `HBox` → `%{type: :container, direction: :hbox, ...}`

  ## Widget Mapping

  * `Text` → `%{type: :label, text: content}` with optional color prop
  * `Button` → `%{type: :button, label: label, on_click: action}` with style props
  * `Label` → `%{type: :label, text: text}` with metadata for `:for` reference
  * `TextInput` → Tagged tuple `{:text_input, widget, metadata}`

  ## DesktopUi Compatibility

  The widget maps produced by this renderer follow the DesktopUi structure:
  - `%{type: :label, id: nil, props: [text: "Hello"], children: []}`
  - `%{type: :button, id: nil, props: [label: "Click", on_click: :clicked], children: []}`
  - `%{type: :container, id: nil, props: [direction: :vbox, spacing: 8], children: [...]}`

  When DesktopUi is added as a dependency, these maps can be passed directly
  to DesktopUI rendering functions.

  """

  @behaviour UnifiedUi.Renderer

  alias UnifiedUi.Renderers.State
  alias UnifiedUi.Renderers.Desktop.Style
  alias UnifiedUi.IUR.Element
  alias UnifiedUi.IUR.Widgets
  alias UnifiedUi.IUR.Layouts

  @impl true
  def render(iur_tree, opts \\ []) do
    renderer_state = State.new(:desktop, config: opts)

    # Convert IUR tree to DesktopUi widget tree
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
    # DesktopUi uses pure data structures, no cleanup needed
    :ok
  end

  @doc """
  Converts an IUR element to a DesktopUi widget tree.

  ## Parameters

  * `iur_element` - The IUR element to convert
  * `renderer_state` - The renderer state (used for tracking)

  ## Returns

  A DesktopUi widget (map with :type key).

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

  # Widget builders - Construct DesktopUi-style widget maps directly

  defp build_label(text, props \\ []) do
    %{
      type: :label,
      id: nil,
      props: [text: text] ++ props,
      children: []
    }
  end

  defp build_button(label, on_click, props) do
    %{
      type: :button,
      id: nil,
      props: [label: label, on_click: on_click] ++ props,
      children: []
    }
  end

  defp build_container(direction, children, props) do
    %{
      type: :container,
      id: nil,
      props: [direction: direction] ++ props,
      children: children
    }
  end

  # Widget converters

  defp convert_by_type(%Widgets.Text{} = text, :text, _state) do
    content = text.content || ""

    # Build base props
    props = []

    # Add style props if present
    props = Style.add_props(props, text.style)

    # Create DesktopUi-style label widget
    build_label(content, props)
  end

  defp convert_by_type(%Widgets.Button{} = button, :button, _state) do
    label = button.label || ""

    # Build base props
    props = []

    # Add style props if present
    props = Style.add_props(props, button.style)

    # Add disabled state
    props = if button.disabled, do: [{:disabled, true} | props], else: props

    # Create DesktopUi-style button widget
    widget = build_button(label, button.on_click, props)

    # Add ID to widget metadata if present
    if button.id do
      Map.put(widget, :id, button.id)
    else
      widget
    end
  end

  defp convert_by_type(%Widgets.Label{} = label, :label, _state) do
    text = label.text || ""

    # Build base props
    props = []

    # Add style props if present
    props = Style.add_props(props, label.style)

    # Create DesktopUi-style label widget
    widget = build_label(text, props)

    # Store :for reference in metadata
    if label.for do
      widget
      |> Map.put(:label_for, label.for)
      |> Map.put(:id, label.id)
    else
      widget
    end
  end

  defp convert_by_type(%Widgets.TextInput{} = input, :text_input, _state) do
    # Build display text
    display_text = cond do
      input.value -> input.value
      input.placeholder -> "[#{input.placeholder}]"
      true -> "[________________]"
    end

    # Build base props
    props = []

    # Add style props if present
    props = Style.add_props(props, input.style)

    # Add input-specific props
    props = if input.disabled, do: [{:disabled, true} | props], else: props

    # Create a label widget to represent the input field
    # DesktopUi doesn't have a dedicated TextInput widget yet
    # We use a label with metadata indicating it's an input
    base_widget = build_label(display_text, props)

    # Wrap with input metadata as a tagged tuple for event handling
    # This follows the same pattern as the Terminal renderer
    {:text_input, base_widget, %{
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

  # Layout converters

  defp convert_by_type(%Layouts.VBox{} = vbox, :vbox, state) do
    children = convert_children(vbox.children, state)

    # Build container props
    props = []
    |> maybe_add_spacing(vbox.spacing)
    |> maybe_add_padding(vbox.padding)
    |> maybe_add_align_items(vbox.align_items)
    |> maybe_add_justify_content(vbox.justify_content)

    # Add style props if present
    props = Style.add_props(props, vbox.style)

    # Create DesktopUi-style container widget
    build_container(:vbox, children, props)
  end

  defp convert_by_type(%Layouts.HBox{} = hbox, :hbox, state) do
    children = convert_children(hbox.children, state)

    # Build container props
    props = []
    |> maybe_add_spacing(hbox.spacing)
    |> maybe_add_padding(hbox.padding)
    |> maybe_add_align_items(hbox.align_items)
    |> maybe_add_justify_content(hbox.justify_content)

    # Add style props if present
    props = Style.add_props(props, hbox.style)

    # Create DesktopUi-style container widget
    build_container(:hbox, children, props)
  end

  # Fallback for unknown types
  defp convert_by_type(_element, _type, _state) do
    # Return empty label for unknown element types
    build_label("")
  end

  # Helper functions

  defp convert_children(children, state) when is_list(children) do
    children
    |> Enum.map(fn child -> convert_iur(child, state) end)
    |> Enum.reject(&is_nil/1)
  end

  defp convert_children(_, _state), do: []

  # Spacing in DesktopUi is in pixels
  defp maybe_add_spacing(props, nil), do: props
  defp maybe_add_spacing(props, spacing) when is_integer(spacing),
    do: [{:spacing, spacing} | props]

  # Padding in DesktopUi is in pixels
  defp maybe_add_padding(props, nil), do: props
  defp maybe_add_padding(props, padding) when is_integer(padding),
    do: [{:padding, padding} | props]

  # Alignment mapping
  # IUR alignment → DesktopUi alignment
  defp maybe_add_align_items(props, nil), do: props
  defp maybe_add_align_items(props, :start), do: [{:align, :left} | props]
  defp maybe_add_align_items(props, :center), do: [{:align, :center} | props]
  defp maybe_add_align_items(props, :end), do: [{:align, :right} | props]
  defp maybe_add_align_items(props, align), do: [{:align, align} | props]

  # Justification mapping
  defp maybe_add_justify_content(props, nil), do: props
  defp maybe_add_justify_content(props, :start), do: [{:justify, :top} | props]
  defp maybe_add_justify_content(props, :center), do: [{:justify, :center} | props]
  defp maybe_add_justify_content(props, :end), do: [{:justify, :bottom} | props]
  defp maybe_add_justify_content(props, justify), do: [{:justify, justify} | props]
end
