defmodule UnifiedUi.Dsl.StyleResolverTest do
  @moduledoc """
  Tests for the UnifiedUi DSL StyleResolver module.

  These tests verify that:
  - Named styles can be resolved to IUR.Style structs
  - Style inheritance works correctly via extends
  - Inline styles merge with named styles
  - Style references of various formats are handled
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Dsl.StyleResolver
  alias UnifiedUi.Dsl.Style, as: DslStyle
  alias UnifiedIUR.Style

  # Helper to create a mock DSL state with styles
  defp create_dsl_state(styles_entities) do
    %{
      persist: %{module: TestModule},
      styles: %{entities: styles_entities}
    }
  end

  # Helper to create a DslStyle entity
  defp create_style(name, opts \\ []) do
    defaults = [
      __struct__: DslStyle,
      name: name,
      extends: nil,
      attributes: [],
      __meta__: []
    ]

    struct(DslStyle, Keyword.merge(defaults, opts))
  end

  describe "resolve/3" do
    test "resolves a named style to IUR.Style" do
      entities = [
        create_style(:header, attributes: [fg: :cyan, attrs: [:bold], padding: 1])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :header)

      assert %Style{fg: :cyan, attrs: [:bold], padding: 1} = result
    end

    test "returns empty style when style not found" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.resolve(dsl_state, :nonexistent)

      assert %Style{fg: nil, bg: nil, attrs: [], padding: nil} = result
    end

    test "applies overrides to resolved style" do
      entities = [
        create_style(:header, attributes: [fg: :cyan, attrs: [:bold]])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :header, fg: :green, padding: 2)

      assert %Style{fg: :green, attrs: [:bold], padding: 2} = result
    end

    test "resolves style with no attributes" do
      entities = [
        create_style(:empty, attributes: [])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :empty)

      assert %Style{fg: nil, bg: nil, attrs: [], padding: nil} = result
    end
  end

  describe "resolve_with inheritance" do
    test "resolves child style with parent attributes" do
      entities = [
        create_style(:base, attributes: [fg: :white, bg: :blue, padding: 1]),
        create_style(:variant, extends: :base, attributes: [fg: :yellow])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :variant)

      # Parent's fg is overridden by child, bg and padding are inherited
      assert %Style{fg: :yellow, bg: :blue, padding: 1} = result
    end

    test "child inherits all parent attributes when not overriding" do
      entities = [
        create_style(:base, attributes: [fg: :white, bg: :blue, padding: 1, attrs: [:bold]]),
        create_style(:variant, extends: :base, attributes: [])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :variant)

      assert %Style{fg: :white, bg: :blue, padding: 1, attrs: [:bold]} = result
    end

    test "handles multi-level inheritance" do
      entities = [
        create_style(:base, attributes: [fg: :white, bg: :blue]),
        create_style(:mid, extends: :base, attributes: [padding: 1]),
        create_style(:leaf, extends: :mid, attributes: [fg: :yellow])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :leaf)

      # fg from leaf, bg from base, padding from mid
      assert %Style{fg: :yellow, bg: :blue, padding: 1} = result
    end

    test "applies overrides to inherited style" do
      entities = [
        create_style(:base, attributes: [fg: :white, bg: :blue]),
        create_style(:variant, extends: :base, attributes: [padding: 1])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :variant, margin: 2)

      assert %Style{fg: :white, bg: :blue, padding: 1, margin: 2} = result
    end

    test "handles missing parent style gracefully" do
      entities = [
        create_style(:orphan, extends: :missing_parent, attributes: [fg: :red])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :orphan)

      # Should use child's attributes even without parent
      assert %Style{fg: :red} = result
    end

    test "inherits attrs lists correctly" do
      entities = [
        create_style(:base, attributes: [attrs: [:bold]]),
        create_style(:variant, extends: :base, attributes: [attrs: [:underline]])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :variant)

      # Both bold and underline should be present
      assert :bold in result.attrs
      assert :underline in result.attrs
    end
  end

  describe "resolve_style_ref/2" do
    test "resolves atom style reference" do
      entities = [
        create_style(:header, attributes: [fg: :cyan])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve_style_ref(dsl_state, :header)

      assert %Style{fg: :cyan} = result
    end

    test "resolves inline keyword list styles" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.resolve_style_ref(dsl_state, [fg: :red, bg: :white])

      assert %Style{fg: :red, bg: :white} = result
    end

    test "resolves named style with inline overrides" do
      entities = [
        create_style(:header, attributes: [fg: :cyan, attrs: [:bold]])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve_style_ref(dsl_state, [:header, fg: :green, padding: 1])

      assert %Style{fg: :green, attrs: [:bold], padding: 1} = result
    end

    test "returns nil for nil style ref" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.resolve_style_ref(dsl_state, nil)

      assert is_nil(result)
    end

    test "returns nil for empty list style ref" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.resolve_style_ref(dsl_state, [])

      assert is_nil(result)
    end

    test "handles pure inline styles starting with known style key" do
      dsl_state = create_dsl_state([])

      # This is a keyword list that happens to start with :fg as a key
      # It's treated as inline styles (keyword list)
      result = StyleResolver.resolve_style_ref(dsl_state, fg: :red, bg: :white)

      assert %Style{fg: :red, bg: :white} = result
    end
  end

  describe "get_all_styles/1" do
    test "returns map of all defined styles" do
      entities = [
        create_style(:header, attributes: [fg: :cyan]),
        create_style(:footer, attributes: [fg: :gray])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.get_all_styles(dsl_state)

      assert map_size(result) == 2
      assert %DslStyle{name: :header} = result[:header]
      assert %DslStyle{name: :footer} = result[:footer]
    end

    test "returns empty map when no styles defined" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.get_all_styles(dsl_state)

      assert result == %{}
    end
  end

  describe "validate_style_ref/2" do
    test "returns :ok for existing named style" do
      entities = [
        create_style(:header, attributes: [fg: :cyan])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.validate_style_ref(dsl_state, :header)

      assert result == :ok
    end

    test "returns error for non-existent named style" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.validate_style_ref(dsl_state, :nonexistent)

      assert result == {:error, :style_not_found}
    end

    test "returns :ok for inline style list" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.validate_style_ref(dsl_state, [fg: :red])

      assert result == :ok
    end

    test "returns :ok for nil" do
      dsl_state = create_dsl_state([])

      result = StyleResolver.validate_style_ref(dsl_state, nil)

      assert result == :ok
    end

    test "returns :ok for named style with overrides list" do
      entities = [
        create_style(:header, attributes: [fg: :cyan])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.validate_style_ref(dsl_state, [:header, fg: :green])

      assert result == :ok
    end
  end

  describe "integration tests" do
    test "complex style hierarchy with multiple levels" do
      entities = [
        create_style(:base, attributes: [padding: 1, margin: 1, fg: :white]),
        create_style(:button, extends: :base, attributes: [bg: :blue, attrs: [:bold]]),
        create_style(:primary_button, extends: :button, attributes: [bg: :green]),
        create_style(:large_button, extends: :primary_button, attributes: [padding: 2])
      ]

      dsl_state = create_dsl_state(entities)

      # large_button should have: padding from large_button (2), bg from primary_button (green),
      # attrs from button (:bold), margin from base (1), fg from base (:white)
      result = StyleResolver.resolve(dsl_state, :large_button)

      assert %Style{
        padding: 2,
        bg: :green,
        attrs: [:bold],
        margin: 1,
        fg: :white
      } = result
    end

    test "style ref with inheritance and inline override" do
      entities = [
        create_style(:base, attributes: [fg: :white, bg: :blue]),
        create_style(:variant, extends: :base, attributes: [padding: 1])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve_style_ref(dsl_state, [:variant, fg: :yellow, margin: 2])

      assert %Style{fg: :yellow, bg: :blue, padding: 1, margin: 2} = result
    end

    test "all attribute types resolve correctly" do
      entities = [
        create_style(:full, attributes: [
          fg: :red,
          bg: :white,
          attrs: [:bold, :underline],
          padding: 2,
          margin: 3,
          width: :fill,
          height: :auto,
          align: :center
        ])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :full)

      assert result.fg == :red
      assert result.bg == :white
      assert :bold in result.attrs
      assert :underline in result.attrs
      assert result.padding == 2
      assert result.margin == 3
      assert result.width == :fill
      assert result.height == :auto
      assert result.align == :center
    end
  end

  describe "circular reference detection" do
    test "detects direct circular reference (A extends B, B extends A)" do
      entities = [
        create_style(:style_a, extends: :style_b, attributes: [fg: :red]),
        create_style(:style_b, extends: :style_a, attributes: [bg: :blue])
      ]

      dsl_state = create_dsl_state(entities)

      assert_raise Spark.Error.DslError, ~r/Circular style reference detected/, fn ->
        StyleResolver.resolve(dsl_state, :style_a)
      end
    end

    test "detects indirect circular reference (A -> B -> C -> A)" do
      entities = [
        create_style(:style_a, extends: :style_b, attributes: [fg: :red]),
        create_style(:style_b, extends: :style_c, attributes: [bg: :blue]),
        create_style(:style_c, extends: :style_a, attributes: [padding: 1])
      ]

      dsl_state = create_dsl_state(entities)

      assert_raise Spark.Error.DslError, ~r/Circular style reference detected/, fn ->
        StyleResolver.resolve(dsl_state, :style_a)
      end
    end

    test "allows deep inheritance without circular references" do
      entities = [
        create_style(:base, attributes: [fg: :white]),
        create_style(:level1, extends: :base, attributes: [bg: :blue]),
        create_style(:level2, extends: :level1, attributes: [padding: 1]),
        create_style(:level3, extends: :level2, attributes: [margin: 1]),
        create_style(:level4, extends: :level3, attributes: [align: :center])
      ]

      dsl_state = create_dsl_state(entities)

      result = StyleResolver.resolve(dsl_state, :level4)

      # All attributes should be merged through the chain
      assert result.fg == :white
      assert result.bg == :blue
      assert result.padding == 1
      assert result.margin == 1
      assert result.align == :center
    end

    test "detects self-reference (style extends itself)" do
      entities = [
        create_style(:self_ref, extends: :self_ref, attributes: [fg: :red])
      ]

      dsl_state = create_dsl_state(entities)

      assert_raise Spark.Error.DslError, ~r/Circular style reference detected/, fn ->
        StyleResolver.resolve(dsl_state, :self_ref)
      end
    end
  end
end
