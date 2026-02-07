defmodule UnifiedUi.Dsl.StyleResolver do
  @moduledoc """
  Resolves named styles to IUR.Style structs with inheritance support.

  This module handles the resolution of style references in the DSL to
  actual IUR.Style structs. It supports:
  - Named style references (atoms)
  - Style inheritance via `extends`
  - Merging with inline styles
  - Circular reference detection

  ## Usage

  Resolve a named style:

      iex> StyleResolver.resolve(dsl_state, :header)
      %IUR.Style{fg: :cyan, attrs: [:bold], ...}

  Resolve with inline overrides:

      iex> StyleResolver.resolve(dsl_state, :header, fg: :green)
      %IUR.Style{fg: :green, attrs: [:bold], ...}

  Resolve from a style reference (atom or keyword list):

      iex> StyleResolver.resolve_style_ref(dsl_state, :header)
      %IUR.Style{fg: :cyan, ...}

      iex> StyleResolver.resolve_style_ref(dsl_state, [fg: :red])
      %IUR.Style{fg: :red, ...}

      iex> StyleResolver.resolve_style_ref(dsl_state, [:header, fg: :green])
      %IUR.Style{fg: :green, attrs: [:bold], ...}

  ## Style Inheritance

  When a style extends another, the resolver merges the parent's attributes
  with the child's attributes (child attributes take precedence):

      style :base do
        attributes [fg: :white, bg: :blue, padding: 1]
      end

      style :variant do
        extends :base
        attributes [fg: :yellow]
      end

      # Resolving :variant gives: fg: :yellow, bg: :blue, padding: 1

  """

  alias Spark.Dsl.Transformer
  alias UnifiedUi.IUR.Style
  alias UnifiedUi.Dsl.Style, as: DslStyle

  @doc """
  Resolves a named style to an IUR.Style struct.

  Handles inheritance by recursively resolving parent styles.
  Detects and prevents circular references in style inheritance.

  ## Parameters

  * `dsl_state` - The Spark DSL state
  * `style_name` - The name of the style to resolve (atom)
  * `overrides` - Optional keyword list of attribute overrides

  ## Returns

  An `IUR.Style` struct with merged attributes.

  ## Raises

  Raises `Spark.Error.DslError` if a circular reference is detected.

  ## Examples

      iex> resolve(dsl_state, :header)
      %Style{fg: :cyan, attrs: [:bold], ...}

      iex> resolve(dsl_state, :header, fg: :green)
      %Style{fg: :green, attrs: [:bold], ...}

  """
  @spec resolve(map(), atom(), keyword()) :: Style.t()
  def resolve(dsl_state, style_name, overrides \\ []) when is_atom(style_name) do
    style_entity = find_style(dsl_state, style_name)

    if style_entity do
      resolve_with_inheritance(dsl_state, style_entity, overrides, MapSet.new())
    else
      # Style not found, return empty style with overrides
      Style.new(overrides)
    end
  end

  @doc """
  Resolves a style reference to an IUR.Style struct.

  The style reference can be:
  * An atom - named style reference
  * A keyword list - inline styles
  * A list starting with an atom - named style with inline overrides

  ## Parameters

  * `dsl_state` - The Spark DSL state
  * `style_ref` - The style reference to resolve

  ## Returns

  An `IUR.Style` struct or `nil` if style_ref is `nil` or empty list.

  ## Examples

      iex> resolve_style_ref(dsl_state, :header)
      %Style{fg: :cyan, ...}

      iex> resolve_style_ref(dsl_state, [fg: :red])
      %Style{fg: :red, ...}

      iex> resolve_style_ref(dsl_state, [:header, fg: :green])
      %Style{fg: :green, attrs: [:bold], ...}

      iex> resolve_style_ref(dsl_state, nil)
      nil

  """
  @spec resolve_style_ref(map(), atom() | keyword() | list()) :: Style.t() | nil
  def resolve_style_ref(_dsl_state, nil), do: nil
  def resolve_style_ref(_dsl_state, []), do: nil

  def resolve_style_ref(dsl_state, style_name) when is_atom(style_name) do
    resolve(dsl_state, style_name)
  end

  def resolve_style_ref(dsl_state, style_ref) when is_list(style_ref) do
    # Check if this is a list with a named style as first element
    case style_ref do
      [style_name | overrides] when is_atom(style_name) ->
        resolve_or_inline(dsl_state, style_name, overrides)

      _ ->
        # Pure inline styles (keyword list)
        Style.new(style_ref)
    end
  end

  # Private functions

  defp resolve_or_inline(dsl_state, style_name, overrides) do
    # Check if this is a valid style name or just inline attributes
    # If the first element is a known style attribute key, treat as pure inline
    style_keys = [:fg, :bg, :attrs, :padding, :margin, :width, :height, :align, :spacing]

    if style_name in style_keys do
      # This is actually inline styles starting with a keyword
      Style.new([style_name | overrides])
    else
      # This is a named style reference with overrides
      resolve(dsl_state, style_name, overrides)
    end
  end

  defp find_style(dsl_state, style_name) do
    dsl_state
    |> Transformer.get_entities(:styles)
    |> Enum.find(fn
      %DslStyle{name: ^style_name} -> true
      _ -> false
    end)
  end

  defp resolve_with_inheritance(_dsl_state, %DslStyle{extends: nil} = style_entity, overrides, _seen) do
    base_attrs = style_entity.attributes || []
    Style.merge(Style.new(base_attrs), Style.new(overrides))
  end

  defp resolve_with_inheritance(dsl_state, %DslStyle{name: name, extends: parent_name} = style_entity, overrides, seen) do
    # Check for circular reference
    if MapSet.member?(seen, name) do
      module = get_persisted_module(dsl_state)

      raise Spark.Error.DslError,
        module: module,
        path: [:styles, name],
        message: """
        Circular style reference detected

        Style '#{inspect(name)} extends '#{inspect(parent_name)}', which creates a circular reference.

        Style inheritance chain:
        #{format_seen_chain(seen)}

        To fix this, remove the circular reference by having one of the styles not extend the other.
        """
    end

    # Track this style as seen
    seen = MapSet.put(seen, name)

    parent_style = find_style(dsl_state, parent_name)

    if parent_style do
      # Resolve parent first (recursive)
      parent_resolved = resolve_with_inheritance(dsl_state, parent_style, [], seen)
      current_attrs = style_entity.attributes || []

      Style.merge(parent_resolved, Style.new(current_attrs))
      |> Style.merge(Style.new(overrides))
    else
      # Parent style not found, just use current style
      base_attrs = style_entity.attributes || []
      Style.merge(Style.new(base_attrs), Style.new(overrides))
    end
  end

  defp get_persisted_module(dsl_state) do
    Spark.Dsl.Verifier.get_persisted(dsl_state, :module)
  end

  defp format_seen_chain(seen) do
    seen
    |> MapSet.to_list()
    |> Enum.map(fn style -> "  - #{inspect(style)}" end)
    |> Enum.join("\n")
  end

  @doc """
  Gets all named styles defined in the DSL state.

  Returns a map of style_name => DslStyle struct.

  ## Examples

      iex> get_all_styles(dsl_state)
      %{header: %DslStyle{name: :header, ...}, ...}

  """
  @spec get_all_styles(map()) :: %{atom() => DslStyle.t()}
  def get_all_styles(dsl_state) do
    dsl_state
    |> Transformer.get_entities(:styles)
    |> Enum.map(fn style -> {style.name, style} end)
    |> Map.new()
  end

  @doc """
  Validates that a style reference is valid.

  Returns `:ok` if the style exists, `{:error, :style_not_found}` if not.

  ## Examples

      iex> validate_style_ref(dsl_state, :header)
      :ok

      iex> validate_style_ref(dsl_state, :nonexistent)
      {:error, :style_not_found}

  Inline styles (lists) always return `:ok`.

  """
  @spec validate_style_ref(map(), atom() | list()) :: :ok | {:error, atom()}
  def validate_style_ref(_dsl_state, style_ref) when is_list(style_ref), do: :ok
  def validate_style_ref(_dsl_state, nil), do: :ok

  def validate_style_ref(dsl_state, style_name) when is_atom(style_name) do
    case find_style(dsl_state, style_name) do
      nil -> {:error, :style_not_found}
      _style -> :ok
    end
  end
end
