defmodule UnifiedUi.Renderers.Desktop.Style do
  @moduledoc """
  Style conversion utilities for Desktop renderer.

  Converts UnifiedUi.IUR.Style to DesktopUi widget properties.

  ## Color Mapping

  UnifiedUi uses atom colors that map to DesktopUi colors:
  * `:black`, `:red`, `:green`, `:yellow`, `:blue`, `:magenta`, `:cyan`, `:white`
  * Bright variants: `:bright_black`, `:bright_red`, etc.

  ## Attribute Mapping

  Text attributes are mapped where DesktopUi supports them:
  * `:bold` - Bold text (if font supports it)
  * `:underline` - Underlined text
  * Note: Some terminal attributes may not have desktop equivalents

  ## Examples

      iex> to_props([text: "Hello"], %Style{fg: :cyan})
      [text: "Hello", color: :cyan]

      iex> to_props([text: "Hi"], %Style{fg: :red, attrs: [:bold]})
      [text: "Hi", color: :red, font_style: :bold]

  """

  alias UnifiedUi.IUR.Style

  @type desktop_props :: keyword()

  @doc """
  Converts an IUR Style to DesktopUi widget properties.

  ## Parameters

  * `props` - Existing props keyword list to extend
  * `iur_style` - The IUR Style struct to convert

  ## Returns

  Extended props keyword list with DesktopUi style properties.

  ## Examples

      iex> add_props([text: "Hello"], %Style{fg: :cyan})
      [text: "Hello", color: :cyan]

      iex> add_props([text: "Hi"], nil)
      [text: "Hi"]

  """
  @spec add_props(keyword(), Style.t() | nil) :: keyword()
  def add_props(props, nil), do: props

  def add_props(props, %Style{} = iur_style) do
    # Map IUR style to DesktopUi props
    props
    |> maybe_add_color(iur_style.fg)
    |> maybe_add_background(iur_style.bg)
    |> maybe_add_font_style(iur_style.attrs)
  end

  @doc """
  Converts an IUR Style to DesktopUi widget properties (standalone).

  ## Parameters

  * `iur_style` - The IUR Style struct to convert

  ## Returns

  Props keyword list with DesktopUi style properties.

  ## Examples

      iex> to_props(%Style{fg: :cyan})
      [color: :cyan]

      iex> to_props(nil)
      []

  """
  @spec to_props(Style.t() | nil) :: keyword()
  def to_props(nil), do: []
  def to_props(%Style{} = iur_style), do: add_props([], iur_style)

  # Private helpers

  # Map foreground color to :color prop
  defp maybe_add_color(props, nil), do: props
  defp maybe_add_color(props, color), do: [{:color, color} | props]

  # Map background color to :background prop
  defp maybe_add_background(props, nil), do: props
  defp maybe_add_background(props, color), do: [{:background, color} | props]

  # Map text attributes to font style
  defp maybe_add_font_style(props, nil), do: props
  defp maybe_add_font_style(props, attrs) do
    # DesktopUi may not support all text attributes
    # We map what we can and ignore the rest
    attrs
    |> Enum.reduce(props, fn attr, acc_props ->
      add_font_attr(acc_props, attr)
    end)
  end

  # Font attribute mapping
  # DesktopUi style uses :font_style prop for text decoration
  defp add_font_attr(props, :bold), do: [{:font_style, :bold} | props]
  defp add_font_attr(props, :underline), do: [{:font_style, :underline} | props]
  defp add_font_attr(props, :italic), do: [{:font_style, :italic} | props]

  # For attributes that might not have direct DesktopUi support,
  # we still try to map them or ignore gracefully
  defp add_font_attr(props, :reverse), do: props  # No direct equivalent
  defp add_font_attr(props, :blink), do: props    # No direct equivalent
  defp add_font_attr(props, :dim), do: props      # Could map to opacity/alpha
  defp add_font_attr(props, :strikethrough), do: props  # No direct equivalent
  defp add_font_attr(props, _), do: props         # Unknown attribute, ignore

  @doc """
  Merges multiple styles into a single DesktopUi props list.

  Later styles override earlier styles for conflicting properties.

  ## Parameters

  * `props` - Base props to extend
  * `styles` - List of IUR Style structs or nil values

  ## Returns

  Extended props keyword list with merged style properties.

  ## Examples

      iex> merge_props([text: "Hello"], [%Style{fg: :red}, %Style{bg: :blue}])
      [text: "Hello", background: :blue, color: :red]

  """
  @spec merge_props(keyword(), [Style.t() | nil]) :: keyword()
  def merge_props(props, []), do: props
  def merge_props(props, styles) when is_list(styles) do
    styles
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(props, fn style, acc_props ->
      add_props(acc_props, style)
    end)
  end
end
