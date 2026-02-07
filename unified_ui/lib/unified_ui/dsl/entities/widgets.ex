defmodule UnifiedUi.Dsl.Entities.Widgets do
  @moduledoc """
  Spark DSL Entity definitions for basic widgets.

  This module defines the DSL entities for the foundational widgets:
  button, text, label, and text_input.

  Each entity specifies:
  - Required arguments (args)
  - Optional options (schema)
  - Target struct for storing the parsed DSL data
  - Documentation for users

  ## Usage

  These entities are automatically available when using `UnifiedUi.Dsl`:

      defmodule MyApp.MyScreen do
        use UnifiedUi.Dsl

        ui do
          # Widgets can be used here (in Phase 2.2 when layout entities are added)
        end
      end
  """

  alias UnifiedUi.IUR.Widgets

  @doc """
  Button entity for creating clickable buttons.

  ## Arguments

  * `:label` - The text to display on the button (required)

  ## Options

  * `:id` - Unique identifier for the button (optional)
  * `:on_click` - Signal to emit when clicked (atom, tuple, or MFA)
  * `:disabled` - Whether the button is disabled (default: false)
  * `:style` - Inline style as keyword list (optional)
  * `:visible` - Whether the button is visible (default: true)

  ## Examples

      button "Submit"
      button "Click Me", id: :submit_btn
      button "Save", on_click: :save, style: [fg: :cyan]
      button "Disabled", disabled: true

  ## Signal Handler Format

  The `on_click` option accepts:
  * An atom signal name: `on_click: :submit`
  * A tuple with payload: `on_click: {:submit, %{form_id: :login}}`
  * An MFA tuple: `on_click: {MyModule, :my_function, []}`

  """
  @button_entity %Spark.Dsl.Entity{
    name: :button,
    target: Widgets.Button,
    args: [:label],
    schema: [
      label: [
        type: :string,
        doc: "The text to display on the button.",
        required: true
      ],
      id: [
        type: :atom,
        doc: "Unique identifier for the button.",
        required: false
      ],
      on_click: [
        type: {:or, [:atom, {:tuple, [:atom, :map]}, {:tuple, [:atom, :atom, :list]}]},
        doc: """
        Signal to emit when clicked. Can be an atom (signal name),
        a tuple {signal_name, payload}, or an MFA tuple {Module, :function, args}.
        """,
        required: false
      ],
      disabled: [
        type: :boolean,
        doc: "Whether the button is disabled.",
        required: false,
        default: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the button is visible.",
        required: false,
        default: true
      ]
    ],
    describe: """
    A clickable button with a label.

    Buttons are the primary way for users to trigger actions in your UI.
    They can be disabled, styled, and configured to emit signals when clicked.
    """
  }

  @doc """
  Text entity for displaying text content.

  ## Arguments

  * `:content` - The text string to display (required)

  ## Options

  * `:id` - Unique identifier for the text element (optional)
  * `:style` - Inline style as keyword list (optional)
  * `:visible` - Whether the text is visible (default: true)

  ## Examples

      text "Hello, World!"
      text "Welcome", id: :greeting, style: [fg: :green, attrs: [:bold]]

  """
  @text_entity %Spark.Dsl.Entity{
    name: :text,
    target: Widgets.Text,
    args: [:content],
    schema: [
      content: [
        type: :string,
        doc: "The text content to display.",
        required: true
      ],
      id: [
        type: :atom,
        doc: "Unique identifier for the text element.",
        required: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the text is visible.",
        required: false,
        default: true
      ]
    ],
    describe: """
    Displays text content.

    Text widgets are the simplest way to display information to users.
    They support styling and can be given identifiers for referencing.
    """
  }

  @doc """
  Label entity for form input labels.

  ## Arguments

  * `:for` - The id of the input this label is for (required)
  * `:text` - The label text to display (required)

  ## Options

  * `:id` - Unique identifier for the label (optional)
  * `:style` - Inline style as keyword list (optional)
  * `:visible` - Whether the label is visible (default: true)

  ## Examples

      label :email_input, "Email:"
      label :password, "Password:", id: :pwd_label
      label :username, "Username:", style: [fg: :cyan]

  """
  @label_entity %Spark.Dsl.Entity{
    name: :label,
    target: Widgets.Label,
    args: [:for, :text],
    schema: [
      for: [
        type: :atom,
        doc: "The id of the input this label is associated with.",
        required: true
      ],
      text: [
        type: :string,
        doc: "The label text to display.",
        required: true
      ],
      id: [
        type: :atom,
        doc: "Unique identifier for the label.",
        required: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the label is visible.",
        required: false,
        default: true
      ]
    ],
    describe: """
    A label for a form input.

    Labels associate descriptive text with form input widgets,
    improving accessibility and usability. The `for` attribute
    should match the `id` of the corresponding input widget.
    """
  }

  @doc """
  Text input entity for user data entry.

  ## Arguments

  * `:id` - Unique identifier for the input (required)

  ## Options

  * `:value` - Initial value for the input (optional)
  * `:placeholder` - Placeholder text when empty (optional)
  * `:type` - Input type (:text, :password, :email, :number, :tel)
  * `:on_change` - Signal to emit when value changes
  * `:on_submit` - Signal to emit on Enter key
  * `:form_id` - Form identifier to group this input with a form
  * `:disabled` - Whether the input is disabled
  * `:style` - Inline style as keyword list
  * `:visible` - Whether the input is visible

  ## Examples

      text_input :email
      text_input :email, placeholder: "user@example.com"
      text_input :password, type: :password
      text_input :age, type: :number, placeholder: "Age"
      text_input :name, on_change: {:name_changed, :value}
      text_input :email, form_id: :login_form
      text_input :password, form_id: :login_form, type: :password

  ## Form Support

  Use the `:form_id` option to group multiple inputs into a form:

      text_input :email, form_id: :login
      text_input :password, form_id: :login, type: :password
      text_input :name, form_id: :signup

  Form data can be collected using `UnifiedUi.Dsl.FormHelpers.collect_form_data/2`.

  ## Input Types

  * `:text` - Plain text input (default)
  * `:password` - Password input (characters hidden)
  * `:email` - Email input
  * `:number` - Numeric input
  * `:tel` - Telephone number input

  ## Signal Handler Format

  The `on_change` and `on_submit` options accept:
  * An atom signal name: `on_change: :value_changed`
  * A tuple with payload: `on_change: {:value_changed, %{field: :email}}`
  * An MFA tuple: `on_change: {MyModule, :validate, [:email]}`

  """
  @text_input_entity %Spark.Dsl.Entity{
    name: :text_input,
    target: Widgets.TextInput,
    args: [:id],
    schema: [
      id: [
        type: :atom,
        doc: "Unique identifier for the input.",
        required: true
      ],
      value: [
        type: :string,
        doc: "Initial value for the input.",
        required: false
      ],
      placeholder: [
        type: :string,
        doc: "Placeholder text displayed when input is empty.",
        required: false
      ],
      type: [
        type: {:one_of, [:text, :password, :email, :number, :tel]},
        doc: """
        The type of input. Valid values: :text, :password, :email, :number, :tel.
        """,
        required: false,
        default: :text
      ],
      on_change: [
        type: {:or, [:atom, {:tuple, [:atom, :map]}, {:tuple, [:atom, :atom, :list]}]},
        doc: """
        Signal to emit when value changes. Can be an atom (signal name),
        a tuple {signal_name, payload}, or an MFA tuple {Module, :function, args}.
        """,
        required: false
      ],
      on_submit: [
        type: {:or, [:atom, {:tuple, [:atom, :map]}, {:tuple, [:atom, :atom, :list]}]},
        doc: """
        Signal to emit on Enter key. Can be an atom (signal name),
        a tuple {signal_name, payload}, or an MFA tuple {Module, :function, args}.
        """,
        required: false
      ],
      form_id: [
        type: :atom,
        doc: """
        Optional form identifier to group this input with a form for data collection.
        Inputs sharing the same form_id can be collected together using
        UnifiedUi.Dsl.FormHelpers.collect_form_data/2.
        """,
        required: false
      ],
      disabled: [
        type: :boolean,
        doc: "Whether the input is disabled.",
        required: false,
        default: false
      ],
      style: [
        type: :keyword_list,
        doc: "Inline style as keyword list.",
        required: false
      ],
      visible: [
        type: :boolean,
        doc: "Whether the input is visible.",
        required: false,
        default: true
      ]
    ],
    describe: """
    A text input field for user data entry.

    Text inputs allow users to enter and edit text data. They support
    various input types for different data formats and can emit signals
    when values change or when the user submits the input.
    """
  }

  @doc false
  def button_entity, do: @button_entity

  @doc false
  def text_entity, do: @text_entity

  @doc false
  def label_entity, do: @label_entity

  @doc false
  def text_input_entity, do: @text_input_entity
end
