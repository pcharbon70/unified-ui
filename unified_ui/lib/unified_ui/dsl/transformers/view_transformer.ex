defmodule UnifiedUi.Dsl.Transformers.ViewTransformer do
  @moduledoc """
  Spark transformer that generates the `view/1` function for Elm Architecture.

  This transformer generates a `view/1` function that returns an IUR tree.
  For Phase 1.5, it generates a basic view returning a simple container.

  Future phases will:
  - Traverse DSL UI tree (layouts and widgets)
  - Convert each DSL entity to corresponding IUR struct
  - Implement state interpolation for dynamic content

  ## Example

  Generates:

      @impl true
      def view(_state) do
        %UnifiedUi.IUR.Layouts.VBox{
          id: nil,
          spacing: nil,
          align: nil,
          children: []
        }
      end
  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    # For Phase 1.5, generate a basic view with an empty VBox
    # In Phase 2+, we'll traverse DSL entities and build full IUR tree
    code =
      quote do
        @impl true
        def view(_state) do
          %UnifiedUi.IUR.Layouts.VBox{
            id: nil,
            spacing: nil,
            align: nil,
            children: []
          }
        end
      end

    Spark.Dsl.Transformer.eval(dsl_state, [], code)
  end
end
