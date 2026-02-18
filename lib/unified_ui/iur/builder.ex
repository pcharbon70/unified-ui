defmodule UnifiedUi.IUR.Builder do
  @moduledoc """
  Builds Intermediate UI Representation (IUR) trees from DSL definitions.

  This module traverses the Spark DSL state and converts DSL entities
  into their corresponding IUR structs. It handles nested structures
  recursively and applies style resolution during the build process.

  ## Usage

  The builder is typically used within the ViewTransformer to generate
  the view/1 function that returns the IUR tree.

      def view(state) do
        Builder.build(dsl_state)
      end

  ## Entity Conversion

  Each DSL entity type has a corresponding build function:

  | DSL Entity | IUR Struct | Build Function |
  |------------|-----------|---------------|
  | button | Widgets.Button | build_button/2 |
  | text | Widgets.Text | build_text/2 |
  | label | Widgets.Label | build_label/2 |
  | text_input | Widgets.TextInput | build_text_input/2 |
  | vbox | Layouts.VBox | build_vbox/2 |
  | hbox | Layouts.HBox | build_hbox/2 |
  | gauge | Widgets.Gauge | build_gauge/2 |
  | sparkline | Widgets.Sparkline | build_sparkline/2 |
  | bar_chart | Widgets.BarChart | build_bar_chart/2 |
  | line_chart | Widgets.LineChart | build_line_chart/2 |
  | table | Widgets.Table | build_table/2 |

  ## Style Handling

  Styles can be specified in multiple ways:
  * Inline keyword list: `style: [fg: :blue, attrs: [:bold]]`
  * Named style reference: `style: :header`
  * Named style with overrides: `style: [:header, fg: :green]`

  The builder resolves all style references to IUR.Style structs.

  ## Nesting

  Layout entities can contain nested widgets and layouts. The builder
  recursively processes children, preserving the hierarchical structure.

  ## Examples

  Given a DSL with:

      ui do
        vbox spacing: 1 do
          text "Welcome"
          button "Start", on_click: :start
        end
      end

  The builder produces:

      %VBox{
        spacing: 1,
        children: [
          %Text{content: "Welcome"},
          %Button{label: "Start", on_click: :start}
        ]
      }
  """

  alias UnifiedIUR.{Style, Widgets, Layouts}
  alias UnifiedUi.Dsl.StyleResolver
  alias Spark.Dsl

  @doc """
  Builds an IUR tree from the DSL state.

  Extracts entities from the [:ui] section and converts them to IUR structs.
  Returns the root IUR element (typically a layout).

  ## Examples

      iex> {:ok, iur} = Builder.build(dsl_state)
      iex> is_struct(iur, VBox) or is_struct(iur, HBox)
      true

  """
  @spec build(Dsl.t()) :: struct() | nil
  def build(dsl_state) do
    dsl_state
    |> collect_root_entities()
    |> Enum.find_value(fn entity -> build_entity(entity, dsl_state) end)
  end

  @doc """
  Converts a single DSL entity to its corresponding IUR struct.

  Dispatches to the appropriate build function based on entity type.
  """
  @spec build_entity(map() | struct(), Dsl.t()) :: struct() | nil
  def build_entity(%module{} = entity, _dsl_state)
      when module in [
             Layouts.VBox,
             Layouts.HBox,
             Widgets.Button,
             Widgets.Text,
             Widgets.Label,
             Widgets.TextInput,
             Widgets.Gauge,
             Widgets.Sparkline,
             Widgets.BarChart,
             Widgets.LineChart,
             Widgets.Table,
             Widgets.Column,
             Widgets.Menu,
             Widgets.MenuItem,
             Widgets.ContextMenu,
             Widgets.Tabs,
             Widgets.Tab,
             Widgets.TreeView,
             Widgets.TreeNode
           ] do
    entity
  end

  def build_entity(%{name: :button} = entity, dsl_state) do
    build_button(entity, dsl_state)
  end

  def build_entity(%{name: :text} = entity, dsl_state) do
    build_text(entity, dsl_state)
  end

  def build_entity(%{name: :label} = entity, dsl_state) do
    build_label(entity, dsl_state)
  end

  def build_entity(%{name: :text_input} = entity, dsl_state) do
    build_text_input(entity, dsl_state)
  end

  def build_entity(%{name: :vbox} = entity, dsl_state) do
    build_vbox(entity, dsl_state)
  end

  def build_entity(%{name: :hbox} = entity, dsl_state) do
    build_hbox(entity, dsl_state)
  end

  def build_entity(%{name: :gauge} = entity, dsl_state) do
    build_gauge(entity, dsl_state)
  end

  def build_entity(%{name: :sparkline} = entity, dsl_state) do
    build_sparkline(entity, dsl_state)
  end

  def build_entity(%{name: :bar_chart} = entity, dsl_state) do
    build_bar_chart(entity, dsl_state)
  end

  def build_entity(%{name: :line_chart} = entity, dsl_state) do
    build_line_chart(entity, dsl_state)
  end

  def build_entity(%{name: :table} = entity, dsl_state) do
    build_table(entity, dsl_state)
  end

  def build_entity(%{name: :column} = entity, dsl_state) do
    build_column(entity, dsl_state)
  end

  def build_entity(%{name: :menu} = entity, dsl_state) do
    build_menu(entity, dsl_state)
  end

  def build_entity(%{name: :context_menu} = entity, dsl_state) do
    build_context_menu(entity, dsl_state)
  end

  def build_entity(%{name: :tabs} = entity, dsl_state) do
    build_tabs(entity, dsl_state)
  end

  def build_entity(%{name: :tree_view} = entity, dsl_state) do
    build_tree_view(entity, dsl_state)
  end

  def build_entity(_entity, _dsl_state) do
    # Unknown entity type, return nil
    nil
  end

  # Widget builders

  @doc """
  Builds a Button IUR struct from a button DSL entity.
  """
  @spec build_button(map(), Dsl.t()) :: Widgets.Button.t()
  def build_button(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Button{
      label: Map.get(attrs, :label),
      on_click: Map.get(attrs, :on_click),
      id: Map.get(attrs, :id),
      disabled: Map.get(attrs, :disabled, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a Text IUR struct from a text DSL entity.
  """
  @spec build_text(map(), Dsl.t()) :: Widgets.Text.t()
  def build_text(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Text{
      content: Map.get(attrs, :content),
      id: Map.get(attrs, :id),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a Label IUR struct from a label DSL entity.
  """
  @spec build_label(map(), Dsl.t()) :: Widgets.Label.t()
  def build_label(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Label{
      for: Map.get(attrs, :for),
      text: Map.get(attrs, :text),
      id: Map.get(attrs, :id),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a TextInput IUR struct from a text_input DSL entity.
  """
  @spec build_text_input(map(), Dsl.t()) :: Widgets.TextInput.t()
  def build_text_input(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.TextInput{
      id: Map.get(attrs, :id),
      value: Map.get(attrs, :value),
      placeholder: Map.get(attrs, :placeholder),
      type: Map.get(attrs, :type, :text),
      on_change: Map.get(attrs, :on_change),
      on_submit: Map.get(attrs, :on_submit),
      form_id: Map.get(attrs, :form_id),
      disabled: Map.get(attrs, :disabled, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  # Data visualization builders

  @doc """
  Builds a Gauge IUR struct from a gauge DSL entity.
  """
  @spec build_gauge(map(), Dsl.t()) :: Widgets.Gauge.t()
  def build_gauge(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Gauge{
      id: Map.get(attrs, :id),
      value: Map.get(attrs, :value),
      min: Map.get(attrs, :min, 0),
      max: Map.get(attrs, :max, 100),
      label: Map.get(attrs, :label),
      width: Map.get(attrs, :width),
      height: Map.get(attrs, :height),
      color_zones: Map.get(attrs, :color_zones),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a Sparkline IUR struct from a sparkline DSL entity.
  """
  @spec build_sparkline(map(), Dsl.t()) :: Widgets.Sparkline.t()
  def build_sparkline(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Sparkline{
      id: Map.get(attrs, :id),
      data: Map.get(attrs, :data),
      width: Map.get(attrs, :width),
      height: Map.get(attrs, :height),
      color: Map.get(attrs, :color),
      show_dots: Map.get(attrs, :show_dots, false),
      show_area: Map.get(attrs, :show_area, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a BarChart IUR struct from a bar_chart DSL entity.
  """
  @spec build_bar_chart(map(), Dsl.t()) :: Widgets.BarChart.t()
  def build_bar_chart(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.BarChart{
      id: Map.get(attrs, :id),
      data: Map.get(attrs, :data),
      width: Map.get(attrs, :width),
      height: Map.get(attrs, :height),
      orientation: Map.get(attrs, :orientation, :horizontal),
      show_labels: Map.get(attrs, :show_labels, true),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a LineChart IUR struct from a line_chart DSL entity.
  """
  @spec build_line_chart(map(), Dsl.t()) :: Widgets.LineChart.t()
  def build_line_chart(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.LineChart{
      id: Map.get(attrs, :id),
      data: Map.get(attrs, :data),
      width: Map.get(attrs, :width),
      height: Map.get(attrs, :height),
      show_dots: Map.get(attrs, :show_dots, true),
      show_area: Map.get(attrs, :show_area, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  # Table builders

  @doc """
  Builds a Table IUR struct from a table DSL entity.
  """
  @spec build_table(map(), Dsl.t()) :: Widgets.Table.t()
  def build_table(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    columns =
      case build_nested_entities(entity, dsl_state, :columns, &build_column/2,
             child_name: :column
           ) do
        [] -> normalize_columns(Map.get(attrs, :columns), dsl_state)
        nested -> nested
      end

    %Widgets.Table{
      id: Map.get(attrs, :id),
      data: Map.get(attrs, :data, []),
      columns: columns,
      selected_row: Map.get(attrs, :selected_row),
      height: Map.get(attrs, :height),
      on_row_select: Map.get(attrs, :on_row_select),
      on_sort: Map.get(attrs, :on_sort),
      sort_column: Map.get(attrs, :sort_column),
      sort_direction: Map.get(attrs, :sort_direction, :asc),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state)
    }
  end

  @doc """
  Builds a Column IUR struct from a column DSL entity.
  """
  @spec build_column(map(), Dsl.t()) :: Widgets.Column.t()
  def build_column(entity, _dsl_state) do
    attrs = get_entity_attrs(entity)

    %Widgets.Column{
      key: Map.get(attrs, :key),
      header: Map.get(attrs, :header),
      sortable: Map.get(attrs, :sortable, true),
      formatter: Map.get(attrs, :formatter),
      width: Map.get(attrs, :width),
      align: Map.get(attrs, :align, :left)
    }
  end

  # Layout builders

  @doc """
  Builds a VBox IUR struct from a vbox DSL entity.

  Recursively builds all children.
  """
  @spec build_vbox(map(), Dsl.t()) :: Layouts.VBox.t()
  def build_vbox(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    children = build_children(entity, dsl_state)

    %Layouts.VBox{
      id: Map.get(attrs, :id),
      spacing: Map.get(attrs, :spacing, 0),
      align_items: Map.get(attrs, :align_items),
      justify_content: Map.get(attrs, :justify_content),
      padding: Map.get(attrs, :padding),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      children: children
    }
  end

  @doc """
  Builds an HBox IUR struct from an hbox DSL entity.

  Recursively builds all children.
  """
  @spec build_hbox(map(), Dsl.t()) :: Layouts.HBox.t()
  def build_hbox(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    children = build_children(entity, dsl_state)

    %Layouts.HBox{
      id: Map.get(attrs, :id),
      spacing: Map.get(attrs, :spacing, 0),
      align_items: Map.get(attrs, :align_items),
      justify_content: Map.get(attrs, :justify_content),
      padding: Map.get(attrs, :padding),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      children: children
    }
  end

  # Navigation widget builders

  @doc """
  Builds a Menu IUR struct from a menu DSL entity.

  Recursively builds all menu items.
  """
  @spec build_menu(map(), Dsl.t()) :: Widgets.Menu.t()
  def build_menu(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    items =
      build_nested_entities(entity, dsl_state, :menu_items, &build_menu_item/2,
        child_name: :menu_item
      )

    %Widgets.Menu{
      id: Map.get(attrs, :id),
      title: Map.get(attrs, :title),
      position: Map.get(attrs, :position),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      items: items
    }
  end

  @doc """
  Builds a menu item IUR struct from a menu_item DSL entity.
  """
  @spec build_menu_item(map(), Dsl.t()) :: Widgets.MenuItem.t()
  def build_menu_item(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    # Menu items can have submenus - check for nested entities
    submenu =
      build_nested_entities(entity, dsl_state, :submenu, &build_menu_item/2,
        child_name: :menu_item
      )

    %Widgets.MenuItem{
      label: Map.get(attrs, :label),
      id: Map.get(attrs, :id),
      action: Map.get(attrs, :action),
      disabled: Map.get(attrs, :disabled, false),
      submenu:
        case submenu do
          [] -> nil
          items -> items
        end,
      icon: Map.get(attrs, :icon),
      shortcut: Map.get(attrs, :shortcut),
      visible: Map.get(attrs, :visible, true)
    }
  end

  @doc """
  Builds a ContextMenu IUR struct from a context_menu DSL entity.
  """
  @spec build_context_menu(map(), Dsl.t()) :: Widgets.ContextMenu.t()
  def build_context_menu(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    items =
      build_nested_entities(entity, dsl_state, :items, &build_menu_item/2, child_name: :menu_item)

    %Widgets.ContextMenu{
      id: Map.get(attrs, :id),
      trigger_on: Map.get(attrs, :trigger_on, :right_click),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      items: items
    }
  end

  @doc """
  Builds a Tabs IUR struct from a tabs DSL entity.

  Recursively builds all tabs.
  """
  @spec build_tabs(map(), Dsl.t()) :: Widgets.Tabs.t()
  def build_tabs(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    tabs = build_nested_entities(entity, dsl_state, :tabs, &build_tab/2, child_name: :tab)

    %Widgets.Tabs{
      id: Map.get(attrs, :id),
      active_tab: Map.get(attrs, :active_tab),
      position: Map.get(attrs, :position),
      on_change: Map.get(attrs, :on_change),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      tabs: tabs
    }
  end

  @doc """
  Builds a Tab IUR struct from a tab DSL entity.
  """
  @spec build_tab(map(), Dsl.t()) :: Widgets.Tab.t()
  def build_tab(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    # Tab content is nested children
    content = build_children(entity, dsl_state)

    %Widgets.Tab{
      id: Map.get(attrs, :id),
      label: Map.get(attrs, :label),
      icon: Map.get(attrs, :icon),
      disabled: Map.get(attrs, :disabled, false),
      closable: Map.get(attrs, :closable, false),
      visible: Map.get(attrs, :visible, true),
      content:
        case content do
          [] -> nil
          [single] -> single
          multiple -> multiple
        end
    }
  end

  @doc """
  Builds a TreeView IUR struct from a tree_view DSL entity.

  Recursively builds all tree nodes.
  """
  @spec build_tree_view(map(), Dsl.t()) :: Widgets.TreeView.t()
  def build_tree_view(entity, dsl_state) do
    attrs = get_entity_attrs(entity)

    root_nodes =
      build_nested_entities(entity, dsl_state, :root_nodes, &build_tree_node/2,
        child_name: :tree_node
      )

    %Widgets.TreeView{
      id: Map.get(attrs, :id),
      selected_node: Map.get(attrs, :selected_node),
      expanded_nodes: Map.get(attrs, :expanded_nodes),
      on_select: Map.get(attrs, :on_select),
      on_toggle: Map.get(attrs, :on_toggle),
      show_root: Map.get(attrs, :show_root, true),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style), dsl_state),
      root_nodes: root_nodes
    }
  end

  @doc """
  Builds a TreeNode IUR struct from a tree_node DSL entity.
  """
  @spec build_tree_node(map(), Dsl.t()) :: Widgets.TreeNode.t()
  def build_tree_node(entity, dsl_state) do
    attrs = get_entity_attrs(entity)
    # Tree nodes can have child nodes
    children =
      build_nested_entities(entity, dsl_state, :children, &build_tree_node/2,
        child_name: :tree_node
      )

    %Widgets.TreeNode{
      id: Map.get(attrs, :id),
      label: Map.get(attrs, :label),
      value: Map.get(attrs, :value),
      expanded: Map.get(attrs, :expanded, false),
      icon: Map.get(attrs, :icon),
      icon_expanded: Map.get(attrs, :icon_expanded),
      selectable: Map.get(attrs, :selectable, true),
      visible: Map.get(attrs, :visible, true),
      children:
        case children do
          [] -> nil
          nodes -> nodes
        end
    }
  end

  # Children building

  @doc """
  Builds child elements for a layout entity.

  Extracts nested entities and recursively builds them.
  """
  @spec build_children(map(), Dsl.t()) :: [struct()]
  def build_children(entity, dsl_state) do
    # Get nested entities from the entity
    # Spark stores nested entities in a specific way
    case Map.get(entity, :entities) do
      nil ->
        []

      entities when is_list(entities) ->
        Enum.map(entities, &build_entity(&1, dsl_state))
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  @doc """
  Builds nested entities with a specific key.

  Similar to build_children but for named nested entity collections
  like menu_items, tabs, root_nodes, etc.
  """
  @spec build_nested_entities(map(), Dsl.t(), atom(), fun(), keyword()) :: [struct()]
  def build_nested_entities(entity, dsl_state, key, builder_fn, opts \\ []) do
    child_name = Keyword.get(opts, :child_name)

    case Map.get(entity, :entities) do
      nil ->
        []

      entities when is_list(entities) ->
        entities
        |> Enum.flat_map(&extract_nested_entities(&1, key, child_name))
        |> Enum.map(fn nested -> builder_fn.(nested, dsl_state) end)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  # Style building

  @doc """
  Converts a style reference to an IUR.Style struct.

  Supports:
  * nil - returns nil
  * [] - returns nil
  * Atom (named style) - resolves from DSL
  * Keyword list (inline styles) - creates Style struct
  * List with atom first (named style + overrides) - resolves with overrides

  Returns nil if no style is provided.
  """
  @spec build_style(keyword() | atom() | nil, Dsl.t()) :: Style.t() | nil
  def build_style(style_ref, dsl_state)

  def build_style(nil, _dsl_state), do: nil
  def build_style([], _dsl_state), do: nil

  def build_style(style_name, dsl_state) when is_atom(style_name) do
    StyleResolver.resolve_style_ref(dsl_state, style_name)
  end

  def build_style(style_keyword, dsl_state) when is_list(style_keyword) do
    StyleResolver.resolve_style_ref(dsl_state, style_keyword)
  end

  def build_style(%Style{} = style, _dsl_state), do: style

  # Helper functions

  @doc """
  Extracts attributes from a DSL entity.

  Handles different ways Spark stores entity attributes.
  """
  @spec get_entity_attrs(map()) :: map()
  def get_entity_attrs(entity) do
    # Spark stores entity attrs in the :attrs field
    case Map.get(entity, :attrs) do
      nil -> %{}
      attrs when is_map(attrs) -> attrs
      attrs when is_list(attrs) -> Enum.into(attrs, %{})
      _ -> %{}
    end
  end

  @doc """
  Validates an IUR tree structure.

  Checks that required fields are present and values are valid.
  Returns :ok if valid, {:error, reason} if invalid.

  Note: This validates struct constraints based on how the DSL entities
  define required fields. For Label and TextInput, the struct defines
  these fields as optional, so we accept them.
  """
  @spec validate(struct()) :: :ok | {:error, term()}
  def validate(%Widgets.Button{label: label}) when is_binary(label), do: :ok
  def validate(%Widgets.Button{}), do: {:error, :missing_label}

  def validate(%Widgets.Text{content: content}) when is_binary(content), do: :ok
  def validate(%Widgets.Text{}), do: {:error, :missing_content}

  # Label struct has optional :for and :text fields (defined in [] part of defstruct)
  # So we accept any Label struct as valid from the struct perspective
  def validate(%Widgets.Label{}), do: :ok

  # TextInput struct has optional :id field (defined in [] part of defstruct)
  # So we accept any TextInput struct as valid from the struct perspective
  def validate(%Widgets.TextInput{}), do: :ok
  def validate(%Widgets.Gauge{}), do: :ok
  def validate(%Widgets.Sparkline{}), do: :ok
  def validate(%Widgets.BarChart{}), do: :ok
  def validate(%Widgets.LineChart{}), do: :ok
  def validate(%Widgets.Table{}), do: :ok
  def validate(%Widgets.Column{}), do: :ok
  def validate(%Widgets.Menu{}), do: :ok
  def validate(%Widgets.MenuItem{}), do: :ok
  def validate(%Widgets.ContextMenu{}), do: :ok
  def validate(%Widgets.Tabs{}), do: :ok
  def validate(%Widgets.Tab{}), do: :ok
  def validate(%Widgets.TreeView{}), do: :ok
  def validate(%Widgets.TreeNode{}), do: :ok

  def validate(%Layouts.VBox{children: children}), do: validate_children(children)
  def validate(%Layouts.HBox{children: children}), do: validate_children(children)

  def validate(_), do: {:error, :unknown_type}

  @doc """
  Validates all children in a list.
  """
  @spec validate_children([struct()]) :: :ok | {:error, term()}
  def validate_children([]), do: :ok

  def validate_children(children) when is_list(children) do
    Enum.reduce_while(children, :ok, fn child, _acc ->
      case validate(child) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp collect_root_entities(dsl_state) do
    [
      safe_get_entities(dsl_state, [:ui]),
      safe_get_entities(dsl_state, :ui)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp safe_get_entities(dsl_state, path) do
    Dsl.Transformer.get_entities(dsl_state, path)
  rescue
    _ -> []
  catch
    _, _ -> []
  end

  defp extract_nested_entities(%{name: name, entities: nested}, key, _child_name)
       when name == key and is_list(nested) do
    nested
  end

  defp extract_nested_entities(%{name: name} = entity, _key, child_name)
       when not is_nil(child_name) and name == child_name do
    [entity]
  end

  defp extract_nested_entities(%{name: name} = entity, key, nil) when name == key do
    [entity]
  end

  defp extract_nested_entities(_entity, _key, _child_name), do: []

  defp normalize_columns(nil, _dsl_state), do: nil

  defp normalize_columns(columns, dsl_state) when is_list(columns) do
    Enum.map(columns, fn
      %Widgets.Column{} = column ->
        column

      %{name: :column} = column_entity ->
        build_column(column_entity, dsl_state)

      attrs when is_map(attrs) ->
        build_column(%{attrs: attrs}, dsl_state)

      attrs when is_list(attrs) ->
        build_column(%{attrs: Enum.into(attrs, %{})}, dsl_state)

      other ->
        other
    end)
  end

  defp normalize_columns(other, _dsl_state), do: other
end
