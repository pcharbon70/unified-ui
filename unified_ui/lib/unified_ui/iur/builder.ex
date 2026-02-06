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

  ## Style Handling

  Inline styles specified as keyword lists in the DSL are converted to
  IUR.Style structs during the build process.

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

  alias UnifiedUi.IUR.{Style, Widgets, Layouts}
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
  @spec build(Dsl.t()) :: Layouts.VBox.t() | Layouts.HBox.t() | Widgets.Text.t() | nil
  def build(dsl_state) do
    # Get all entities from the ui section
    # The ui section contains nested entities, we need to extract them properly
    case Dsl.Transformer.get_entities(dsl_state, [:ui]) do
      [] ->
        # No entities found, return nil (view will handle this)
        nil

      entities when is_list(entities) ->
        # The first entity should be the root layout (usually vbox or hbox)
        # Convert the first entity to IUR
        case entities do
          [entity | _] ->
            build_entity(entity, dsl_state)

          _ ->
            nil
        end
    end
  end

  @doc """
  Converts a single DSL entity to its corresponding IUR struct.

  Dispatches to the appropriate build function based on entity type.
  """
  @spec build_entity(map(), Dsl.t()) :: struct()
  def build_entity(%{name: :button} = entity, _dsl_state) do
    build_button(entity)
  end

  def build_entity(%{name: :text} = entity, _dsl_state) do
    build_text(entity)
  end

  def build_entity(%{name: :label} = entity, _dsl_state) do
    build_label(entity)
  end

  def build_entity(%{name: :text_input} = entity, _dsl_state) do
    build_text_input(entity)
  end

  def build_entity(%{name: :vbox} = entity, dsl_state) do
    build_vbox(entity, dsl_state)
  end

  def build_entity(%{name: :hbox} = entity, dsl_state) do
    build_hbox(entity, dsl_state)
  end

  def build_entity(_entity, _dsl_state) do
    # Unknown entity type, return nil
    nil
  end

  # Widget builders

  @doc """
  Builds a Button IUR struct from a button DSL entity.
  """
  @spec build_button(map()) :: Widgets.Button.t()
  def build_button(entity) do
    attrs = get_entity_attrs(entity)

    %Widgets.Button{
      label: Map.get(attrs, :label),
      on_click: Map.get(attrs, :on_click),
      id: Map.get(attrs, :id),
      disabled: Map.get(attrs, :disabled, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style))
    }
  end

  @doc """
  Builds a Text IUR struct from a text DSL entity.
  """
  @spec build_text(map()) :: Widgets.Text.t()
  def build_text(entity) do
    attrs = get_entity_attrs(entity)

    %Widgets.Text{
      content: Map.get(attrs, :content),
      id: Map.get(attrs, :id),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style))
    }
  end

  @doc """
  Builds a Label IUR struct from a label DSL entity.
  """
  @spec build_label(map()) :: Widgets.Label.t()
  def build_label(entity) do
    attrs = get_entity_attrs(entity)

    %Widgets.Label{
      for: Map.get(attrs, :for),
      text: Map.get(attrs, :text),
      id: Map.get(attrs, :id),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style))
    }
  end

  @doc """
  Builds a TextInput IUR struct from a text_input DSL entity.
  """
  @spec build_text_input(map()) :: Widgets.TextInput.t()
  def build_text_input(entity) do
    attrs = get_entity_attrs(entity)

    %Widgets.TextInput{
      id: Map.get(attrs, :id),
      value: Map.get(attrs, :value),
      placeholder: Map.get(attrs, :placeholder),
      type: Map.get(attrs, :type, :text),
      on_change: Map.get(attrs, :on_change),
      on_submit: Map.get(attrs, :on_submit),
      disabled: Map.get(attrs, :disabled, false),
      visible: Map.get(attrs, :visible, true),
      style: build_style(Map.get(attrs, :style))
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
      style: build_style(Map.get(attrs, :style)),
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
      style: build_style(Map.get(attrs, :style)),
      children: children
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

  # Style building

  @doc """
  Converts a keyword list style to an IUR.Style struct.

  Returns nil if no style is provided.
  """
  @spec build_style(keyword() | nil) :: Style.t() | nil
  def build_style(nil), do: nil
  def build_style([]), do: nil

  def build_style(style_keyword) when is_list(style_keyword) do
    Style.new(style_keyword)
  end

  def build_style(%Style{} = style), do: style

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
end
