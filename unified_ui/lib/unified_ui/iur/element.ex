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
    build_metadata(%{type: :text}, id: text.id, style: text.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Widgets.Button do
  import UnifiedUi.IUR.ElementHelpers

  def children(_button), do: []

  def metadata(button) do
    %{type: :button, label: button.label, on_click: button.on_click, disabled: button.disabled}
    |> build_metadata(id: button.id, style: button.style)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Layouts.VBox do
  import UnifiedUi.IUR.ElementHelpers

  def children(vbox), do: vbox.children

  def metadata(vbox) do
    build_metadata(%{type: :vbox, spacing: vbox.spacing, align: vbox.align}, id: vbox.id)
  end
end

defimpl UnifiedUi.IUR.Element, for: UnifiedUi.IUR.Layouts.HBox do
  import UnifiedUi.IUR.ElementHelpers

  def children(hbox), do: hbox.children

  def metadata(hbox) do
    build_metadata(%{type: :hbox, spacing: hbox.spacing, align: hbox.align}, id: hbox.id)
  end
end

defimpl UnifiedUi.IUR.Element, for: Any do
  def children(_element), do: []

  def metadata(_element), do: %{type: :unknown}
end
