defmodule UnifiedUi.Renderers.Web.Style do
  @moduledoc """
  Style conversion utilities for Web renderer.

  Converts UnifiedUi.IUR.Style to CSS inline style strings.

  ## Color Mapping

  UnifiedUi uses atom colors that map to CSS color names:
  * `:black`, `:red`, `:green`, `:yellow`, `:blue`, `:magenta`, `:cyan`, `:white`
  * CSS also supports hex, rgb, hsl, and named colors

  ## Attribute Mapping

  Text attributes map to CSS properties:
  * `:bold` - `font-weight: bold`
  * `:underline` - `text-decoration: underline`
  * `:italic` - `font-style: italic`
  * `:strikethrough` - `text-decoration: line-through`

  ## Examples

      iex> to_css(%Style{fg: :cyan})
      "color: cyan"

      iex> to_css(%Style{fg: :red, attrs: [:bold]})
      "font-weight: bold; color: red"

  """

  alias UnifiedUi.IUR.Style

  @type css_string :: String.t()

  @doc """
  Converts an IUR Style to a CSS inline style string.

  ## Parameters

  * `iur_style` - The IUR Style struct to convert

  ## Returns

  A CSS inline style string, or nil if no style.

  ## Examples

      iex> to_css(%Style{fg: :cyan})
      "color: cyan"

      iex> to_css(%Style{fg: :red, attrs: [:bold]})
      "font-weight: bold; color: red"

      iex> to_css(nil)
      ""

  """
  @spec to_css(Style.t() | nil) :: css_string()
  def to_css(nil), do: ""

  def to_css(%Style{} = iur_style) do
    # Build CSS parts
    css_parts = []

    # Add foreground color
    css_parts = if iur_style.fg do
      ["color: #{color_to_css(iur_style.fg)}" | css_parts]
    else
      css_parts
    end

    # Add background color
    css_parts = if iur_style.bg do
      ["background-color: #{color_to_css(iur_style.bg)}" | css_parts]
    else
      css_parts
    end

    # Add text attributes
    css_parts = if iur_style.attrs do
      Enum.reduce(iur_style.attrs, css_parts, fn attr, acc ->
        add_attr_css(acc, attr)
      end)
    else
      css_parts
    end

    # Join with semicolons (reverse to maintain order)
    css_parts |> Enum.reverse() |> Enum.join("; ")
  end

  @doc """
  Extends existing CSS string with IUR style properties.

  ## Parameters

  * `css` - Existing CSS string
  * `iur_style` - The IUR Style struct to add

  ## Returns

  Extended CSS string with additional style properties.

  ## Examples

      iex> add_to_css("color: red", %Style{bg: :blue})
      "color: red; background-color: blue"

  """
  @spec add_to_css(css_string(), Style.t() | nil) :: css_string()
  def add_to_css(css, nil), do: css
  def add_to_css("", %Style{} = iur_style), do: to_css(iur_style)
  def add_to_css(css, %Style{} = iur_style) do
    additional_css = to_css(iur_style)
    if additional_css == "" do
      css
    else
      "#{css}; #{additional_css}"
    end
  end

  # Private helpers

  # Convert IUR color to CSS color value
  defp color_to_css(color) when is_atom(color) do
    # Atoms like :cyan, :magenta work directly as CSS color names
    Atom.to_string(color)
  end

  defp color_to_css(color) when is_binary(color) do
    # Already a string (could be hex, rgb, etc.)
    color
  end

  defp color_to_css({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    # RGB tuple → rgb()
    "rgb(#{r}, #{g}, #{b})"
  end

  defp color_to_css({r, g, b, a}) when is_integer(r) and is_integer(g) and is_integer(b) and is_integer(a) do
    # RGBA tuple → rgba()
    "rgba(#{r}, #{g}, #{b}, #{a / 255})"
  end

  # Add text attribute as CSS
  defp add_attr_css(css_parts, :bold), do: ["font-weight: bold" | css_parts]
  defp add_attr_css(css_parts, :underline), do: ["text-decoration: underline" | css_parts]
  defp add_attr_css(css_parts, :italic), do: ["font-style: italic" | css_parts]
  defp add_attr_css(css_parts, :strikethrough), do: ["text-decoration: line-through" | css_parts]

  # For attributes that may not have direct CSS support or are terminal-specific
  defp add_attr_css(css_parts, :reverse), do: css_parts
  defp add_attr_css(css_parts, :blink), do: css_parts
  defp add_attr_css(css_parts, :dim), do: ["opacity: 0.7" | css_parts]
  defp add_attr_css(css_parts, _), do: css_parts  # Unknown attribute, ignore

  @doc """
  Merges multiple styles into a single CSS string.

  Later styles override earlier styles for conflicting properties.

  ## Parameters

  * `styles` - List of IUR Style structs or nil values

  ## Returns

  A CSS inline style string.

  ## Examples

      iex> merge_styles([%Style{fg: :red}, %Style{bg: :blue}])
      "color: red; background-color: blue"

  """
  @spec merge_styles([Style.t() | nil]) :: css_string()
  def merge_styles(styles) when is_list(styles) do
    styles
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce("", fn style, acc_css ->
      add_to_css(acc_css, style)
    end)
  end
end
