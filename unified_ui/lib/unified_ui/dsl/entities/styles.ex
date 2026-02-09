defmodule UnifiedUi.Dsl.Entities.Styles do
  @moduledoc """
  Spark DSL Entity definitions for named styles.

  This module defines the style entity for creating reusable, named styles
  that can be referenced by widgets and layouts.

  ## Usage

  Styles are defined in the `styles` section of a UI module:

      defmodule MyApp.MyScreen do
        use UnifiedUi.Dsl

        styles do
          style :header do
            attributes [
              fg: :cyan,
              attrs: [:bold],
              padding: 1
            ]
          end

          style :error_header do
            extends :header
            attributes [
              fg: :red,
              attrs: [:bold, :underline]
            ]
          end
        end

        ui do
          vbox do
            text "Welcome", style: :header
            text "Error!", style: :error_header
          end
        end
      end

  ## Style Inheritance

  Styles can extend other styles using the `extends` option. The child style
  inherits all attributes from the parent and can override them:

      style :button_base do
        attributes [
          padding: 1,
          attrs: [:bold]
        ]
      end

      style :primary_button do
        extends :button_base
        attributes [
          fg: :white,
          bg: :blue
        ]
      end

  ## Combining with Inline Styles

  Named styles can be combined with inline styles. Inline styles take
  precedence:

      text "Title", style: [:header, fg: :green]
      # This would use all header attributes but override fg to :green

  """

  alias UnifiedUi.Dsl.Style

  @doc false
  @style_entity %Spark.Dsl.Entity{
    name: :style,
    target: Style,
    args: [:name],
    schema: [
      name: [
        type: :atom,
        doc: "Unique name for this style.",
        required: true
      ],
      extends: [
        type: :atom,
        doc: """
        Optional parent style name to inherit from.

        The child style will inherit all attributes from the parent style.
        Attributes specified in the child style override parent attributes.
        """,
        required: false
      ],
      attributes: [
        type: :keyword_list,
        doc: """
        Style attributes as a keyword list.

        Valid attributes include:
        * `:fg` - Foreground color (atom, RGB tuple, or hex string)
        * `:bg` - Background color (atom, RGB tuple, or hex string)
        * `:attrs` - Text attributes list (:bold, :italic, :underline, :reverse)
        * `:padding` - Internal spacing (integer)
        * `:margin` - External spacing (integer)
        * `:width` - Width constraint (integer, :auto, or :fill)
        * `:height` - Height constraint (integer, :auto, or :fill)
        * `:align` - Alignment (:left, :center, :right, :top, :bottom, etc.)
        * `:spacing` - Spacing between children for layouts (integer)
        """,
        required: false,
        default: []
      ]
    ],
    describe: """
    A named style that can be referenced by widgets and layouts.

    Styles support inheritance through the `extends` option, allowing
    you to create style hierarchies and variants.
    """
  }

  @doc false
  def style_entity, do: @style_entity
end
