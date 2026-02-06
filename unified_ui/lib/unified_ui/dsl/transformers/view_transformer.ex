defmodule UnifiedUi.Dsl.Transformers.ViewTransformer do
  @moduledoc """
  Spark transformer that generates the `view/1` function for Elm Architecture.

  This transformer generates a `view/1` function that returns an IUR tree.
  For Phase 1.5-2.3, it generates a basic view returning a simple container
  with access to state.

  Future phases will:
  - Traverse DSL UI tree (layouts and widgets) - Phase 2.5
  - Convert each DSL entity to corresponding IUR struct - Phase 2.5
  - Implement state interpolation for dynamic content - Phase 2.5

  ## State Interpolation

  For Phase 2.3, the view function accepts the state parameter but doesn't
  yet perform full state interpolation. Full state interpolation will be
  implemented in Phase 2.5 (IUR Tree Building) when the DSL tree walking
  logic is added.

  State helper functions are available in `UnifiedUi.Dsl.StateHelpers` for
  use in update/2 functions to create state updates.

  ## Example

  Generates:

      @impl true
      def view(state) do
        # State is available for manual interpolation
        # Full DSL-based interpolation coming in Phase 2.5
        %UnifiedUi.IUR.Layouts.VBox{
          id: nil,
          spacing: nil,
          align_items: nil,
          children: []
        }
      end
  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    # For Phase 1.5-2.3, generate a basic view with an empty VBox
    # The state parameter is properly named (not prefixed with _)
    # to indicate it will be used for state interpolation in Phase 2.5
    code =
      quote do
        @impl true
        def view(state) do
          # State is available for use when Phase 2.5 implements
          # full DSL tree traversal and state interpolation
          %UnifiedUi.IUR.Layouts.VBox{
            id: nil,
            spacing: nil,
            align_items: nil,
            children: []
          }
        end
      end

    Spark.Dsl.Transformer.eval(dsl_state, [], code)
  end
end
