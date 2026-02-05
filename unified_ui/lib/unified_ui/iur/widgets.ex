defmodule UnifiedUi.IUR.Widgets do
  @moduledoc """
  Intermediate UI Representation (IUR) widget structs.

  Widgets are the basic building blocks of a user interface.
  Each widget is a simple data container (struct) with no business logic.
  They represent leaf nodes in the UI tree - widgets do not contain children.

  ## Widget Types

  * `Text` - Display text content
  * `Button` - Clickable button with label

  ## Common Fields

  All widgets have:
  * `id` - Optional unique identifier for the widget
  * `style` - Optional style struct for visual appearance

  ## Examples

  Create a text widget:

      iex> %Text{content: "Hello, World!", id: :greeting}
      %Text{content: "Hello, World!", id: :greeting, style: nil}

  Create a button widget:

      iex> %Button{label: "Click Me", on_click: :submit, id: :submit_btn}
      %Button{label: "Click Me", on_click: :submit, id: :submit_btn, ...}
  """

  defmodule Text do
    @moduledoc """
    Text widget for displaying text content.
    """

    defstruct [:content, :id, style: nil]

    @type t :: %__MODULE__{
            content: String.t() | nil,
            id: atom() | nil,
            style: UnifiedUi.IUR.Style.t() | nil
          }
  end

  defmodule Button do
    @moduledoc """
    Button widget for user interaction.

    ## Fields

    * `label` - The text displayed on the button
    * `on_click` - Signal to emit when clicked (atom, tuple, or function reference)
    * `disabled` - Whether the button is disabled (default: false)
    * `style` - Optional `UnifiedUi.IUR.Style` struct
    * `id` - Optional unique identifier

    ## Signal Format

    The `on_click` field can be:
    * An atom signal name: `:submit`
    * A tuple with payload: `{:submit, %{data: "value"}}`
    * A function reference (stored for later evaluation)

    ## Examples

        iex> %Button{label: "Submit", on_click: :submit}
        %Button{label: "Submit", on_click: :submit, disabled: false, ...}

        iex> %Button{label: "Disabled", on_click: :noop, disabled: true}
        %Button{label: "Disabled", on_click: :noop, disabled: true, ...}
    """

    defstruct [:label, :on_click, :id, style: nil, disabled: false]

    @type t :: %__MODULE__{
            label: String.t() | nil,
            on_click: atom() | {atom(), any()} | nil,
            id: atom() | nil,
            style: UnifiedUi.IUR.Style.t() | nil,
            disabled: boolean()
          }
  end
end
