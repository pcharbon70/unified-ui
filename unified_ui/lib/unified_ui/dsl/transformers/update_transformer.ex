defmodule UnifiedUi.Dsl.Transformers.UpdateTransformer do
  @moduledoc """
  Spark transformer that generates the `update/2` function for Elm Architecture.

  This transformer generates an `update/2` function that handles signals
  by pattern matching on signal type.

  For Phase 2.4, the transformer:
  - Generates a basic update/2 with signal pattern matching
  - Includes a fallback clause for unhandled signals
  - Prepares for signal handler extraction from DSL entities (Phase 2.5)

  Future enhancement will extract signal handlers from DSL entities and
  generate pattern match clauses for each handler automatically.

  ## Example

  Generates:

      @impl true
      def update(state, signal) do
        case signal do
          %{type: "unified.button.clicked"} = sig ->
            handle_click_signal(state, sig)

          %{type: "unified.input.changed"} = sig ->
            handle_change_signal(state, sig)

          %{type: "unified.form.submitted"} = sig ->
            handle_submit_signal(state, sig)

          _signal ->
            state
        end
      end

  ## Signal Handler Functions

  The generated handler functions can be overridden in the UI module
  to provide custom behavior for each signal type.

  """

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    # For Phase 2.4, generate an update/2 with signal pattern matching
    # In Phase 2.5+, we'll extract signal handlers from DSL entities
    # and generate custom clauses for each handler

    code =
      quote do
        @impl true
        def update(state, signal) do
          case signal do
            %{type: "unified.button.clicked"} = sig ->
              handle_click_signal(state, sig)

            %{type: "unified.input.changed"} = sig ->
              handle_change_signal(state, sig)

            %{type: "unified.form.submitted"} = sig ->
              handle_submit_signal(state, sig)

            _signal ->
              state
          end
        end

        # Default signal handlers - can be overridden in UI module

        @doc """
        Handles click signals from buttons.

        Override this function in your UI module to customize click handling.
        """
        def handle_click_signal(state, _signal) do
          state
        end

        @doc """
        Handles change signals from inputs.

        Override this function in your UI module to customize change handling.
        """
        def handle_change_signal(state, _signal) do
          state
        end

        @doc """
        Handles submit signals from forms.

        Override this function in your UI module to customize submit handling.
        """
        def handle_submit_signal(state, _signal) do
          state
        end

        defoverridable handle_click_signal: 2
        defoverridable handle_change_signal: 2
        defoverridable handle_submit_signal: 2
      end

    Spark.Dsl.Transformer.eval(dsl_state, [], code)
  end
end
