defmodule UnifiedUi.Renderers.Terminal do
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

  alias UnifiedUi.Renderers.State
  alias UnifiedUi.Renderers.Terminal.Style
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
end
