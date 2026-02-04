defmodule UnifiedUi.Dsl do
  @moduledoc """
  The main UnifiedUi DSL module.

  This module provides the DSL for defining multi-platform user interfaces.
  Use this module in your UI components to access the DSL constructs.

  ## Example

  ```elixir
  defmodule MyApp.MyScreen do
    use UnifiedUi.Dsl

    ui do
      vbox style: [padding: 2] do
        text "Welcome to MyApp!"
      end
    end
  end
  ```

  ## DSL Sections

  Once you `use UnifiedUi.Dsl`, the following DSL constructs are available:

  * `ui` - Top-level section for UI definitions
  * Widgets (future): `text`, `button`, `text_input`, etc.
  * Layouts (future): `vbox`, `hbox`, `grid`, etc.
  * Styles: `style` option for visual styling

  """

  @doc """
  Uses the UnifiedUi DSL in the calling module.

  This sets up Spark DSL with the UnifiedUi extension.
  """
  defmacro __using__(_opts) do
    quote do
      use Spark.Dsl,
        default_extensions: [extensions: [UnifiedUi.Dsl.Extension]]
    end
  end

  @doc """
  Returns the list of standard signal types.

  These are the standard signal types used for inter-component
  communication via the JidoSignal library.

  ## Returns

  A list of atoms representing standard signal types.

  ## Example

      iex> UnifiedUi.Dsl.standard_signals()
      [:click, :change, :submit, :focus, :blur, :select]
  """
  def standard_signals do
    [:click, :change, :submit, :focus, :blur, :select]
  end
end
