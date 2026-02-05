defmodule UnifiedUi.IUR.Layouts do
  @moduledoc """
  Intermediate UI Representation (IUR) layout structs.

  Layouts are container elements that arrange widgets and other layouts
  in specific patterns. They represent internal nodes in the UI tree.

  ## Layout Types

  * `VBox` - Vertical box: arranges children top to bottom
  * `HBox` - Horizontal box: arranges children left to right

  ## Common Fields

  All layouts have:
  * `children` - List of child elements (widgets or nested layouts)
  * `id` - Optional unique identifier
  * `spacing` - Space between children
  * `align` - Alignment of children within the layout

  ## Examples

  Create a vertical box with text and button:

      iex> %VBox{
      ...>   children: [
      ...>     %Text{content: "Welcome!"},
      ...>     %Button{label: "Start", on_click: :start}
      ...>   ],
      ...>   spacing: 1,
      ...>   align: :center
      ...> }

  Create a horizontal form row:

      iex> %HBox{
      ...>   children: [
      ...>     %Text{content: "Name:"},
      ...>     %TextInput{id: :name_input}
      ...>   ],
      ...>   spacing: 2
      ...> }
  """

  defmodule VBox do
    @moduledoc """
    Vertical box layout container.

    Arranges children vertically from top to bottom.

    ## Fields

    * `children` - List of child elements (widgets or nested layouts)
    * `spacing` - Space between children (integer, default: 0)
    * `align` - Horizontal alignment of children (`:left`, `:center`, `:right`, `:start`, `:end`, `:stretch`)
    * `id` - Optional unique identifier

    ## Alignment Values

    * `:left` - Align children to the left edge
    * `:center` - Center children horizontally
    * `:right` - Align children to the right edge
    * `:start` - Align to the start (left for LTR, right for RTL)
    * `:end` - Align to the end (right for LTR, left for RTL)
    * `:stretch` - Stretch children to fill the width

    ## Examples

        iex> %VBox{children: [%Text{content: "A"}, %Text{content: "B"}], spacing: 1}
        %VBox{children: [...], spacing: 1, align: nil, id: nil}
    """

    defstruct [:id, children: [], spacing: 0, align: nil]

    @type alignment :: :left | :center | :right | :start | :end | :stretch
    @type child :: UnifiedUi.IUR.Widgets.Text.t() | UnifiedUi.IUR.Widgets.Button.t() | t()

    @type t :: %__MODULE__{
            id: atom() | nil,
            children: [child()],
            spacing: integer(),
            align: alignment() | nil
          }
  end

  defmodule HBox do
    @moduledoc """
    Horizontal box layout container.

    Arranges children horizontally from left to right.

    ## Fields

    * `children` - List of child elements (widgets or nested layouts)
    * `spacing` - Space between children (integer, default: 0)
    * `align` - Vertical alignment of children (`:top`, `:center`, `:bottom`, `:start`, `:end`, `:stretch`)
    * `id` - Optional unique identifier

    ## Alignment Values

    * `:top` - Align children to the top edge
    * `:center` - Center children vertically
    * `:bottom` - Align children to the bottom edge
    * `:start` - Align to the start (top for TTB, bottom for BTT)
    * `:end` - Align to the end (bottom for TTB, top for BTT)
    * `:stretch` - Stretch children to fill the height

    ## Examples

        iex> %HBox{children: [%Text{content: "A"}, %Text{content: "B"}], spacing: 2}
        %HBox{children: [...], spacing: 2, align: nil, id: nil}
    """

    defstruct [:id, children: [], spacing: 0, align: nil]

    @type alignment :: :top | :center | :bottom | :start | :end | :stretch
    @type child :: UnifiedUi.IUR.Widgets.Text.t() | UnifiedUi.IUR.Widgets.Button.t() | t()

    @type t :: %__MODULE__{
            id: atom() | nil,
            children: [child()],
            spacing: integer(),
            align: alignment() | nil
          }
  end
end
