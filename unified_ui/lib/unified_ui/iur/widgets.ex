defmodule UnifiedUi.IUR.Widgets do
  @moduledoc """
  Intermediate UI Representation (IUR) widget structs.

  Widgets are the basic building blocks of a user interface.
  Each widget is a simple data container (struct) with no business logic.
  They represent leaf nodes in the UI tree - widgets do not contain children.

  ## Widget Types

  * `Text` - Display text content
  * `Button` - Clickable button with label
  * `Label` - Label for form inputs
  * `TextInput` - Text input field for data entry

  ## Common Fields

  All widgets have:
  * `id` - Optional unique identifier for the widget
  * `style` - Optional style struct for visual appearance
  * `visible` - Whether the widget is visible (default: true)

  ## Examples

  Create a text widget:

      iex> %Text{content: "Hello, World!", id: :greeting}
      %Text{content: "Hello, World!", id: :greeting, style: nil}

  Create a button widget:

      iex> %Button{label: "Click Me", on_click: :submit, id: :submit_btn}
      %Button{label: "Click Me", on_click: :submit, id: :submit_btn, ...}

  Create a label widget:

      iex> %Label{for: :email_input, text: "Email:"}
      %Label{for: :email_input, text: "Email:", id: nil, style: nil}

  Create a text input widget:

      iex> %TextInput{id: :email, placeholder: "user@example.com"}
      %TextInput{id: :email, placeholder: "user@example.com", type: :text, ...}
  """

  defmodule Text do
    @moduledoc """
    Text widget for displaying text content.
    """

    defstruct [:content, :id, style: nil, visible: true]

    @type t :: %__MODULE__{
            content: String.t() | nil,
            id: atom() | nil,
            style: UnifiedUi.IUR.Style.t() | nil,
            visible: boolean()
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
    * `visible` - Whether the button is visible (default: true)

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

    defstruct [:label, :on_click, :id, style: nil, disabled: false, visible: true]

    @type t :: %__MODULE__{
            label: String.t() | nil,
            on_click: atom() | {atom(), any()} | nil,
            id: atom() | nil,
            style: UnifiedUi.IUR.Style.t() | nil,
            disabled: boolean(),
            visible: boolean()
          }
  end

  defmodule Label do
    @moduledoc """
    Label widget for form inputs.

    Associates descriptive text with a form input widget.

    ## Fields

    * `for` - The id of the input this label is for
    * `text` - The label text to display
    * `id` - Optional unique identifier
    * `style` - Optional style struct
    * `visible` - Whether the label is visible (default: true)

    ## Examples

        iex> %Label{for: :email_input, text: "Email:"}
        %Label{for: :email_input, text: "Email:", id: nil, style: nil}

        iex> %Label{for: :password, text: "Password:", id: :pwd_label}
        %Label{for: :password, text: "Password:", id: :pwd_label, ...}
    """

    defstruct [:for, :text, :id, style: nil, visible: true]

    @type t :: %__MODULE__{
            for: atom(),
            text: String.t(),
            id: atom() | nil,
            style: UnifiedUi.IUR.Style.t() | nil,
            visible: boolean()
          }
  end

  defmodule TextInput do
    @moduledoc """
    Text input widget for user data entry.

    ## Fields

    * `id` - Required identifier for the input
    * `value` - Initial value (optional)
    * `placeholder` - Placeholder text when empty
    * `type` - Input type (:text, :password, :email, :number, :tel)
    * `on_change` - Signal to emit when value changes
    * `on_submit` - Signal to emit on Enter key
    * `form_id` - Optional form identifier for grouping inputs
    * `disabled` - Whether the input is disabled
    * `style` - Optional style struct
    * `visible` - Whether the input is visible

    ## Input Types

    * `:text` - Plain text input (default)
    * `:password` - Password input (characters hidden)
    * `:email` - Email input (with validation hint)
    * `:number` - Numeric input
    * `:tel` - Telephone number input

    ## Signal Format

    The `on_change` and `on_submit` fields can be:
    * An atom signal name: `:value_changed`
    * A tuple with payload: `{:value_changed, %{value: "new"}}`
    * A function reference (stored for later evaluation)

    ## Examples

        iex> %TextInput{id: :email, placeholder: "user@example.com"}
        %TextInput{id: :email, placeholder: "user@example.com", type: :text, ...}

        iex> %TextInput{id: :password, type: :password}
        %TextInput{id: :password, type: :password, ...}

        iex> %TextInput{id: :age, type: :number, placeholder: "Age"}
        %TextInput{id: :age, type: :number, placeholder: "Age", ...}
    """

    @type input_type :: :text | :password | :email | :number | :tel

    defstruct [
      :id,
      :value,
      :placeholder,
      :type,
      :on_change,
      :on_submit,
      :form_id,
      :disabled,
      :style,
      visible: true
    ]

    @type t :: %__MODULE__{
            id: atom(),
            value: String.t() | nil,
            placeholder: String.t() | nil,
            type: input_type(),
            on_change: atom() | {atom(), any()} | nil,
            on_submit: atom() | {atom(), any()} | nil,
            form_id: atom() | nil,
            disabled: boolean(),
            style: UnifiedUi.IUR.Style.t() | nil,
            visible: boolean()
          }
  end
end
