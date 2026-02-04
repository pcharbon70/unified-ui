defmodule UnifiedUi.Dsl.Sections.Signals do
  @moduledoc """
  The Signals section for the UnifiedUi DSL.

  This section defines signal types for inter-component communication
  using the JidoSignal library.

  ## Signal-Based Communication

  UI components communicate via signals, which are messages sent between
  Jido.Agent.Server processes. When a user interacts with a widget
  (e.g., clicks a button, types in an input), the widget emits a signal.

  ## Standard Signal Types

  The following standard signals will be supported:
  * `:click` - Button/element clicked
  * `:change` - Input value changed
  * `:submit` - Form submitted
  * `:focus` - Element gained focus
  * `:blur` - Element lost focus
  * `:select` - Item selected (table row, menu item, etc.)

  ## Signal Format

  Signals are tuples with the signal name and a payload map:
  ```elixir
  {:button_clicked, %{id: :submit_btn, timestamp: ~U[2025-02-04 10:00:00Z]}}
  ```

  ## Example (Future)

  ```elixir
  ui do
    vbox do
      button "Save",
        id: :save_btn,
        on_click: fn -> {:save_clicked, %{}} end
    end
  end

  # In the component's update/2 function:
  def update({:save_clicked, _payload}, state) do
    # Handle the save action
    {:noreply, state}
  end
  ```
  """

  @signals_section %Spark.Dsl.Section{
    name: :signals,
    describe: """
    The signals section contains signal type definitions.

    Signals are used for inter-component communication via the JidoSignal library.
    They represent events that occur when users interact with UI elements.
    """,
    schema: [
      name: [
        type: :atom,
        doc: "The name of the signal type.",
        required: true
      ],
      payload: [
        type: :keyword_list,
        doc: "The payload schema for the signal.",
        required: false
      ],
      description: [
        type: :string,
        doc: "Human-readable description of the signal.",
        required: false
      ]
    ],
    entities: [
      # Custom signal entities will be added in future phases
    ]
  }

  @doc false
  def section, do: @signals_section

  @doc false
  def entities, do: @signals_section.entities

  @doc false
  def top_level?, do: false

  @doc false
  def name, do: @signals_section.name

  @doc """
  Returns the list of standard signal types.
  """
  def standard_signals do
    [:click, :change, :submit, :focus, :blur, :select]
  end
end
