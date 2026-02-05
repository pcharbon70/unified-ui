defmodule UnifiedUi.Dsl.Transformers.UpdateTransformer do
  @moduledoc """
  Spark transformer that generates the `update/2` function for Elm Architecture.

  This transformer generates an `update/2` function that handles signals
  by pattern matching on signal type. Currently generates a basic fallback
  that returns state unchanged.

  Future enhancement will extract signal handlers from DSL entities and
  generate pattern match clauses for each handler.

  ## Example

  Generates:

      @impl true
      def update(state, _signal) do
        state
      end
  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    # For now, generate a basic update that returns state unchanged
    # In Phase 1.6+, we'll extract signal handlers from DSL entities
    # and generate pattern match clauses for each signal type
    code =
      quote do
        @impl true
        def update(state, _signal) do
          state
        end
      end

    Spark.Dsl.Transformer.eval(dsl_state, [], code)
  end
end
