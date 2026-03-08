# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule UnifiedUi.Dsl.Transformers.UpdateTransformer do
  @moduledoc """
  Spark transformer that generates a DSL-driven `update/2` function.

  The generated `update/2` routes incoming signals by:
  1. Signal type (`click`, `change`, `submit`)
  2. A key extracted from signal data (`action`, `input_id`, `form_id`, etc.)
  3. DSL-declared handlers found on widgets/entities

  If no DSL route matches, it falls back to default handlers that return
  state unchanged. For matched routes, default handlers apply route-driven
  state updates. All default handlers are overridable.
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias UnifiedUi.Dsl.CompileIndex
  alias UnifiedIUR.Widgets

  @click_signal_type "unified.button.clicked"
  @change_signal_type "unified.input.changed"
  @submit_signal_type "unified.form.submitted"

  @impl true
  @spec transform(Spark.Dsl.t()) :: {:ok, Spark.Dsl.t()} | {:error, term()}
  def transform(dsl_state) do
    routes = extract_routes(dsl_state)
    modal_scopes = extract_modal_scopes(dsl_state)
    click_routes = Macro.escape(routes.click)
    change_routes = Macro.escape(routes.change)
    submit_routes = Macro.escape(routes.submit)
    modal_scopes = Macro.escape(modal_scopes)

    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    code =
      quote do
        @impl true
        def update(state, %Jido.Signal{type: unquote(@click_signal_type)} = signal) do
          dispatch_click_signal(state, signal)
        end

        @impl true
        def update(state, %{type: unquote(@click_signal_type)} = signal) do
          dispatch_click_signal(state, signal)
        end

        @impl true
        def update(state, %Jido.Signal{type: unquote(@change_signal_type)} = signal) do
          dispatch_change_signal(state, signal)
        end

        @impl true
        def update(state, %{type: unquote(@change_signal_type)} = signal) do
          dispatch_change_signal(state, signal)
        end

        @impl true
        def update(state, %Jido.Signal{type: unquote(@submit_signal_type)} = signal) do
          dispatch_submit_signal(state, signal)
        end

        @impl true
        def update(state, %{type: unquote(@submit_signal_type)} = signal) do
          dispatch_submit_signal(state, signal)
        end

        @impl true
        def update(state, _signal) do
          state
        end

        defp dispatch_click_signal(state, signal) do
          if UnifiedUi.Dsl.Transformers.UpdateTransformer.modal_blocked?(
               state,
               signal,
               unquote(modal_scopes)
             ) do
            state
          else
            route =
              UnifiedUi.Dsl.Transformers.UpdateTransformer.find_matching_route(
                unquote(click_routes),
                signal,
                :click
              )

            case route do
              nil -> handle_click_signal(state, signal)
              route -> handle_click_signal(state, signal, route)
            end
          end
        end

        defp dispatch_change_signal(state, signal) do
          if UnifiedUi.Dsl.Transformers.UpdateTransformer.modal_blocked?(
               state,
               signal,
               unquote(modal_scopes)
             ) do
            state
          else
            route =
              UnifiedUi.Dsl.Transformers.UpdateTransformer.find_matching_route(
                unquote(change_routes),
                signal,
                :change
              )

            case route do
              nil -> handle_change_signal(state, signal)
              route -> handle_change_signal(state, signal, route)
            end
          end
        end

        defp dispatch_submit_signal(state, signal) do
          if UnifiedUi.Dsl.Transformers.UpdateTransformer.modal_blocked?(
               state,
               signal,
               unquote(modal_scopes)
             ) do
            state
          else
            route =
              UnifiedUi.Dsl.Transformers.UpdateTransformer.find_matching_route(
                unquote(submit_routes),
                signal,
                :submit
              )

            case route do
              nil -> handle_submit_signal(state, signal)
              route -> handle_submit_signal(state, signal, route)
            end
          end
        end

        @doc """
        Handles click signals from buttons/elements.
        """
        def handle_click_signal(state, _signal) do
          state
        end

        @doc """
        Handles click signals with a matched DSL route.
        """
        def handle_click_signal(state, signal, route) do
          UnifiedUi.Dsl.Transformers.UpdateTransformer.apply_route_update(
            :click,
            state,
            signal,
            route
          )
        end

        @doc """
        Handles change signals from inputs.
        """
        def handle_change_signal(state, _signal) do
          state
        end

        @doc """
        Handles change signals with a matched DSL route.
        """
        def handle_change_signal(state, signal, route) do
          UnifiedUi.Dsl.Transformers.UpdateTransformer.apply_route_update(
            :change,
            state,
            signal,
            route
          )
        end

        @doc """
        Handles submit signals from forms/inputs.
        """
        def handle_submit_signal(state, _signal) do
          state
        end

        @doc """
        Handles submit signals with a matched DSL route.
        """
        def handle_submit_signal(state, signal, route) do
          UnifiedUi.Dsl.Transformers.UpdateTransformer.apply_route_update(
            :submit,
            state,
            signal,
            route
          )
        end

        defoverridable handle_click_signal: 2
        defoverridable handle_click_signal: 3
        defoverridable handle_change_signal: 2
        defoverridable handle_change_signal: 3
        defoverridable handle_submit_signal: 2
        defoverridable handle_submit_signal: 3
      end

    {:ok, Transformer.eval(dsl_state, [], code)}
  end

  @doc """
  Indicates whether this transformer should run before another transformer.
  """
  @impl true
  @spec before?(module()) :: boolean()
  def before?(_other), do: false

  @doc """
  Indicates whether this transformer should run after another transformer.
  """
  @impl true
  @spec after?(module()) :: boolean()
  def after?(_other), do: false

  @doc """
  Indicates whether this transformer runs in the after-compile phase.
  """
  @impl true
  @spec after_compile?() :: boolean()
  def after_compile?, do: false

  @doc false
  @spec find_matching_route([map()], map(), :click | :change | :submit) :: map() | nil
  def find_matching_route(routes, signal, kind) when is_list(routes) do
    route_key = extract_route_key(kind, signal)
    signal_data = extract_signal_data(signal)
    source_keys = extract_source_keys(signal_data)
    action_keys = extract_action_keys(signal_data, route_key)

    Enum.find(routes, fn route -> route.source in source_keys end) ||
      Enum.find(routes, fn route -> route.key in action_keys end)
  end

  @doc false
  @spec modal_blocked?(map(), map(), map()) :: boolean()
  def modal_blocked?(state, signal, modal_scopes)
      when is_map(state) and is_map(modal_scopes) do
    source_id =
      signal
      |> extract_signal_data()
      |> extract_modal_source_id()

    cond do
      map_size(modal_scopes) == 0 ->
        false

      is_nil(source_id) ->
        false

      true ->
        case active_modal_allowed_ids(state, modal_scopes) do
          nil -> false
          allowed_ids -> not MapSet.member?(allowed_ids, source_id)
        end
    end
  end

  def modal_blocked?(_state, _signal, _modal_scopes), do: false

  @doc false
  @spec apply_route_update(:click | :change | :submit, map(), map(), map()) :: map()
  def apply_route_update(kind, state, signal, route) when is_map(state) and is_map(route) do
    case route.handler do
      {:mfa, module, function, args} ->
        invoke_mfa_route(module, function, args, state, signal, route)

      _ ->
        state
        |> Map.merge(default_route_updates(kind, signal, route))
    end
  end

  defp extract_signal_data(%Jido.Signal{data: data}) when is_map(data), do: data
  defp extract_signal_data(%{data: data}) when is_map(data), do: data
  defp extract_signal_data(_), do: %{}

  defp extract_route_key(:click, signal) do
    data = extract_signal_data(signal)

    Map.get(data, :action) ||
      Map.get(data, :button_id) ||
      Map.get(data, :widget_id) ||
      Map.get(data, :id)
  end

  defp extract_route_key(:change, signal) do
    data = extract_signal_data(signal)

    Map.get(data, :input_id) ||
      Map.get(data, :widget_id) ||
      Map.get(data, :field) ||
      Map.get(data, :action) ||
      Map.get(data, :id)
  end

  defp extract_route_key(:submit, signal) do
    data = extract_signal_data(signal)

    Map.get(data, :form_id) ||
      Map.get(data, :action) ||
      Map.get(data, :id)
  end

  defp extract_route_key(_kind, _signal), do: nil

  defp extract_source_keys(data) do
    [
      Map.get(data, :widget_id),
      Map.get(data, :button_id),
      Map.get(data, :input_id),
      Map.get(data, :form_id),
      Map.get(data, :id)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp extract_action_keys(data, route_key) do
    [
      route_key,
      Map.get(data, :action)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp default_route_updates(:click, _signal, route), do: route.payload

  defp default_route_updates(:change, signal, route) do
    signal_data = extract_signal_data(signal)
    input_key = route.source
    input_value = Map.get(signal_data, :value)

    if is_atom(input_key) and not is_nil(input_value) do
      Map.put(route.payload, input_key, input_value)
    else
      route.payload
    end
  end

  defp default_route_updates(:submit, signal, route) do
    signal_data = extract_signal_data(signal)
    Map.merge(route.payload, extract_submit_updates(signal_data))
  end

  defp default_route_updates(_kind, _signal, _route), do: %{}

  defp extract_submit_updates(signal_data) do
    case Map.get(signal_data, :data) do
      form_data when is_map(form_data) ->
        form_data

      _ ->
        signal_data
        |> Map.drop([:form_id, :action, :platform, :widget_id, :button_id, :input_id, :id])
    end
  end

  defp invoke_mfa_route(module, function, args, state, signal, route) do
    result =
      cond do
        function_exported?(module, function, length(args) + 3) ->
          apply(module, function, [state, signal, route | args])

        function_exported?(module, function, length(args) + 2) ->
          apply(module, function, [state, signal | args])

        function_exported?(module, function, length(args) + 1) ->
          apply(module, function, [signal | args])

        function_exported?(module, function, length(args)) ->
          apply(module, function, args)

        true ->
          state
      end

    normalize_route_result(result, state)
  rescue
    _ -> state
  catch
    _, _ -> state
  end

  defp normalize_route_result(%{} = result, _fallback), do: result
  defp normalize_route_result({:ok, %{} = result}, _fallback), do: result
  defp normalize_route_result({:noreply, %{} = result}, _fallback), do: result
  defp normalize_route_result(_result, fallback), do: fallback

  defp extract_modal_scopes(dsl_state) do
    entities = collect_entities(dsl_state)

    modal_entities =
      Enum.flat_map(entities, fn
        %Widgets.Dialog{id: id, visible: visible} when is_atom(id) ->
          [%{id: id, default_visible: visible != false}]

        %Widgets.AlertDialog{id: id, visible: visible} when is_atom(id) ->
          [%{id: id, default_visible: visible != false}]

        %{name: name, attrs: attrs} when name in [:dialog, :alert_dialog] ->
          modal_id = attr_get(attrs, :id)

          if is_atom(modal_id) do
            [%{id: modal_id, default_visible: attr_get(attrs, :visible) != false}]
          else
            []
          end

        _ ->
          []
      end)

    dialog_button_ids =
      entities
      |> Enum.flat_map(fn
        %Widgets.DialogButton{id: id} when is_atom(id) ->
          [id]

        %{name: :dialog_button, attrs: attrs} ->
          case attr_get(attrs, :id) do
            id when is_atom(id) -> [id]
            _ -> []
          end

        _ ->
          []
      end)
      |> MapSet.new()

    Enum.reduce(modal_entities, %{}, fn %{id: modal_id, default_visible: default_visible}, acc ->
      allowed_ids = dialog_button_ids |> MapSet.put(modal_id)
      Map.put(acc, modal_id, %{default_visible: default_visible, allowed_ids: allowed_ids})
    end)
  end

  defp extract_routes(dsl_state) do
    entities = collect_entities(dsl_state)

    %{
      click: extract_click_routes(entities),
      change: extract_change_routes(entities),
      submit: extract_submit_routes(entities)
    }
  end

  defp collect_entities(dsl_state) do
    CompileIndex.get(dsl_state).flat
  end

  defp extract_modal_source_id(data) do
    [
      Map.get(data, :widget_id),
      Map.get(data, :button_id),
      Map.get(data, :input_id),
      Map.get(data, :form_id),
      Map.get(data, :id)
    ]
    |> Enum.find(&is_atom/1)
  end

  defp active_modal_allowed_ids(state, modal_scopes) do
    allowed =
      modal_scopes
      |> Enum.reduce(MapSet.new(), fn {modal_id,
                                       %{
                                         default_visible: default_visible,
                                         allowed_ids: allowed_ids
                                       }},
                                      acc ->
        if modal_active?(state, modal_id, default_visible) do
          MapSet.union(acc, allowed_ids)
        else
          acc
        end
      end)

    if MapSet.size(allowed) > 0, do: allowed, else: nil
  end

  defp modal_active?(state, modal_id, default_visible) do
    open_key = :"#{modal_id}_open"
    visible_key = :"#{modal_id}_visible"

    cond do
      Map.has_key?(state, open_key) -> state[open_key] not in [false, nil]
      Map.has_key?(state, visible_key) -> state[visible_key] not in [false, nil]
      true -> default_visible != false
    end
  end

  defp extract_click_routes(entities) do
    entities
    |> Enum.flat_map(fn
      %Widgets.Button{} = button ->
        [build_route(:click, button.on_click, button.id)]

      %{name: :button, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :on_click), attr_get(attrs, :id))]

      %Widgets.MenuItem{} = item ->
        [build_route(:click, item.action, item.id)]

      %{name: :menu_item, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :action), attr_get(attrs, :id))]

      %Widgets.Table{} = table ->
        [
          build_route(:click, table.on_row_select, table.id),
          build_route(:click, table.on_sort, table.id)
        ]

      %{name: :table, attrs: attrs} ->
        [
          build_route(:click, attr_get(attrs, :on_row_select), attr_get(attrs, :id)),
          build_route(:click, attr_get(attrs, :on_sort), attr_get(attrs, :id))
        ]

      %Widgets.Tabs{} = tabs ->
        [build_route(:click, tabs.on_change, tabs.id)]

      %{name: :tabs, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :on_change), attr_get(attrs, :id))]

      %Widgets.TreeView{} = tree ->
        [
          build_route(:click, tree.on_select, tree.id),
          build_route(:click, tree.on_toggle, tree.id)
        ]

      %{name: :tree_view, attrs: attrs} ->
        [
          build_route(:click, attr_get(attrs, :on_select), attr_get(attrs, :id)),
          build_route(:click, attr_get(attrs, :on_toggle), attr_get(attrs, :id))
        ]

      %Widgets.DialogButton{} = button ->
        [build_route(:click, button.action, button.id)]

      %{name: :dialog_button, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :action), attr_get(attrs, :id))]

      %Widgets.Dialog{} = dialog ->
        [build_route(:click, dialog.on_close, dialog.id)]

      %{name: :dialog, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :on_close), attr_get(attrs, :id))]

      %Widgets.AlertDialog{} = alert ->
        [
          build_route(:click, alert.on_confirm, alert.id),
          build_route(:click, alert.on_cancel, alert.id)
        ]

      %{name: :alert_dialog, attrs: attrs} ->
        [
          build_route(:click, attr_get(attrs, :on_confirm), attr_get(attrs, :id)),
          build_route(:click, attr_get(attrs, :on_cancel), attr_get(attrs, :id))
        ]

      %Widgets.Toast{} = toast ->
        [build_route(:click, toast.on_dismiss, toast.id)]

      %{name: :toast, attrs: attrs} ->
        [build_route(:click, attr_get(attrs, :on_dismiss), attr_get(attrs, :id))]

      _ ->
        []
    end)
    |> compact_routes()
  end

  defp extract_change_routes(entities) do
    entities
    |> Enum.flat_map(fn
      %Widgets.TextInput{} = input ->
        [build_route(:change, input.on_change, input.id)]

      %{name: :text_input, attrs: attrs} ->
        [build_route(:change, attr_get(attrs, :on_change), attr_get(attrs, :id))]

      %Widgets.PickList{} = pick_list ->
        [build_route(:change, pick_list.on_select, pick_list.id)]

      %{name: :pick_list, attrs: attrs} ->
        [build_route(:change, attr_get(attrs, :on_select), attr_get(attrs, :id))]

      _ ->
        []
    end)
    |> compact_routes()
  end

  defp extract_submit_routes(entities) do
    entities
    |> Enum.flat_map(fn
      %Widgets.TextInput{} = input ->
        fallback = input.form_id || input.id
        [build_route(:submit, input.on_submit, fallback)]

      %{name: :text_input, attrs: attrs} ->
        fallback = attr_get(attrs, :form_id) || attr_get(attrs, :id)
        [build_route(:submit, attr_get(attrs, :on_submit), fallback)]

      %Widgets.FormBuilder{} = form_builder ->
        fallback = form_builder.action || form_builder.id
        [build_route(:submit, form_builder.on_submit, fallback)]

      %{name: :form_builder, attrs: attrs} ->
        fallback = attr_get(attrs, :action) || attr_get(attrs, :id)
        [build_route(:submit, attr_get(attrs, :on_submit), fallback)]

      _ ->
        []
    end)
    |> compact_routes()
  end

  defp build_route(_kind, nil, _fallback_key), do: nil

  defp build_route(kind, handler, fallback_key) do
    key = handler_key(handler, fallback_key)

    if is_atom(key) do
      %{
        kind: kind,
        key: key,
        handler: normalize_handler(handler),
        payload: handler_payload(handler),
        source: fallback_key
      }
    else
      nil
    end
  end

  defp compact_routes(routes) do
    routes
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce({MapSet.new(), []}, fn route, {seen, acc} ->
      dedupe_key = {route.key, route.source}

      if MapSet.member?(seen, dedupe_key) do
        {seen, acc}
      else
        {MapSet.put(seen, dedupe_key), [route | acc]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp handler_key(handler, _fallback_key) when is_atom(handler), do: handler

  defp handler_key({signal_name, _payload}, _fallback_key) when is_atom(signal_name),
    do: signal_name

  defp handler_key({_module, _function, _args}, fallback_key), do: fallback_key
  defp handler_key(_handler, fallback_key), do: fallback_key

  defp normalize_handler(handler) when is_atom(handler), do: {:signal, handler}

  defp normalize_handler({signal_name, payload})
       when is_atom(signal_name) and is_map(payload) do
    {:signal_with_payload, signal_name, payload}
  end

  defp normalize_handler({module, function, args})
       when is_atom(module) and is_atom(function) and is_list(args) do
    {:mfa, module, function, args}
  end

  defp normalize_handler(other), do: {:unknown, other}

  defp handler_payload({_signal_name, payload}) when is_map(payload), do: payload
  defp handler_payload(_), do: %{}

  defp attr_get(attrs, key) when is_map(attrs), do: Map.get(attrs, key)
  defp attr_get(attrs, key) when is_list(attrs), do: Keyword.get(attrs, key)
  defp attr_get(_attrs, _key), do: nil
end
