defmodule UnifiedUi.Dsl.Transformers.InitTransformer do
  @moduledoc """
  Spark transformer that generates the `init/1` function for Elm Architecture.

  This transformer extracts the initial state from the DSL `state` entity
  and generates an `init/1` function that returns it as a map with atom keys.

  ## Example

  Given DSL with:

      ui do
        state count: 0, username: "guest", active: true
      end

  Generates:

      @impl true
      def init(_opts) do
        %{count: 0, username: "guest", active: true}
      end

  If no state is defined, generates an init that returns an empty map.
  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    initial_state = get_initial_state(dsl_state)

    code =
      quote do
        @impl true
        def init(_opts) do
          unquote(Macro.escape(initial_state))
        end
      end

    Spark.Dsl.Transformer.eval(dsl_state, [], code)
  end

  # Extract initial state from DSL state entity
  defp get_initial_state(dsl_state) do
    case Spark.Dsl.Transformer.get_entities(dsl_state, [:ui, :state]) do
      [] -> %{}
      [%{attrs: state_keyword}] when is_list(state_keyword) -> Enum.into(state_keyword, %{})
      _ -> %{}
    end
  end
end
