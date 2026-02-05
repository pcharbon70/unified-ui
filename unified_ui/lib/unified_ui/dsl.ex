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

  ## Elm Architecture

  Modules using `use UnifiedUi.Dsl` automatically receive generated
  `init/1`, `update/2`, and `view/1` functions following The Elm Architecture.
  To adopt the behaviour explicitly, add `@behaviour UnifiedUi.ElmArchitecture`
  before `use UnifiedUi.Dsl`.

  ```elixir
  defmodule MyComponent do
    @behaviour UnifiedUi.ElmArchitecture
    use UnifiedUi.Dsl

    # ... DSL definitions
  end
  ```

  """

  @doc """
  Uses the UnifiedUi DSL in the calling module.

  This sets up Spark DSL with the UnifiedUi extension.
  Note: This does not automatically adopt the ElmArchitecture behaviour
  to avoid conflicts with Spark.Dsl. Add `@behaviour UnifiedUi.ElmArchitecture`
  explicitly if you want the behaviour contract.
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

  Delegates to `UnifiedUi.Signals.standard_signals/0` as the
  single source of truth for signal definitions.

  ## Returns

  A list of atoms representing standard signal types.

  ## Example

      iex> UnifiedUi.Dsl.standard_signals()
      [:click, :change, :submit, :focus, :blur, :select]
  """
  defdelegate standard_signals, to: UnifiedUi.Signals
end
