defmodule UnifiedUi.Dsl.Transformers.ViewTransformer do
  @moduledoc """
  Spark transformer that generates the `view/1` function for Elm Architecture.

  This transformer generates a `view/1` function that returns an IUR tree.
  For Phase 2.5, it uses the IUR.Builder to convert DSL entities into IUR structs.

  ## State Interpolation

  The view function accepts the state parameter. State interpolation is handled
  at the IUR level by the renderer, which can access state values when needed.

  ## Example

  Generates:

      @impl true
      def view(state) do
        # The builder converts DSL entities to IUR structs
        case UnifiedUi.IUR.Builder.build(__dsl_state__()) do
          nil -> %UnifiedIUR.Layouts.VBox{children: []}
          iur -> iur
        end
      end

  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    # For Phase 2.5, we use the IUR.Builder to convert DSL entities to IUR
    code =
      quote do
        @impl true
        def view(state) do
          case UnifiedUi.IUR.Builder.build(unquote(Macro.escape(dsl_state))) do
            nil ->
              # Fallback to empty VBox if no entities defined
              %UnifiedIUR.Layouts.VBox{
                id: nil,
                spacing: nil,
                align_items: nil,
                children: []
              }

            iur ->
              iur
          end
        end
      end

    {:ok, Spark.Dsl.Transformer.eval(dsl_state, [], code)}
  end
end
