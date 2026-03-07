defmodule UnifiedUi.Dsl.CompileIndex do
  @moduledoc false

  alias Spark.Dsl.Transformer

  @persist_key :unified_ui_compile_index
  @nested_entity_keys [:entities, :children, :items, :tabs, :nodes, :columns]

  @type t :: %{
          widgets: list(),
          layouts: list(),
          ui: list(),
          state: list(),
          flat: list()
        }

  @spec get(Spark.Dsl.t()) :: t()
  def get(dsl_state) do
    Transformer.get_persisted(dsl_state, @persist_key) || build(dsl_state)
  end

  @spec persist(Spark.Dsl.t()) :: Spark.Dsl.t()
  def persist(dsl_state) do
    Transformer.persist(dsl_state, @persist_key, build(dsl_state))
  end

  @spec build(Spark.Dsl.t()) :: t()
  def build(dsl_state) do
    widgets = safe_get_entities(dsl_state, :widgets)
    layouts = safe_get_entities(dsl_state, :layouts)
    ui_entities = collect_ui_entities(dsl_state)
    state_entities = collect_state_entities(dsl_state)

    roots =
      [widgets, layouts, ui_entities]
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    %{
      widgets: widgets,
      layouts: layouts,
      ui: ui_entities,
      state: state_entities,
      flat: flatten_entities(roots)
    }
  end

  defp collect_ui_entities(dsl_state) do
    entities =
      [
        safe_get_entities(dsl_state, [:ui]),
        safe_get_entities(dsl_state, :ui)
      ]
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    if entities == [] do
      dsl_state
      |> Map.get(:ui, %{})
      |> Map.get(:entities, [])
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
    else
      entities
    end
  end

  defp collect_state_entities(dsl_state) do
    entities = safe_get_entities(dsl_state, [:ui, :state])

    if entities == [] do
      dsl_state
      |> Map.get(:ui, %{})
      |> Map.get(:state, %{})
      |> Map.get(:entities, [])
      |> List.wrap()
      |> Enum.reject(&is_nil/1)
    else
      entities
    end
  end

  defp safe_get_entities(dsl_state, path) do
    dsl_state
    |> Transformer.get_entities(path)
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
  rescue
    _ -> []
  catch
    _, _ -> []
  end

  defp flatten_entities(entities) when is_list(entities) do
    Enum.flat_map(entities, &flatten_entity/1)
  end

  defp flatten_entity(entity) when is_map(entity) do
    nested =
      @nested_entity_keys
      |> Enum.flat_map(fn key ->
        case Map.get(entity, key) do
          values when is_list(values) -> values
          _ -> []
        end
      end)

    [entity | flatten_entities(nested)]
  end

  defp flatten_entity(entity), do: [entity]
end
