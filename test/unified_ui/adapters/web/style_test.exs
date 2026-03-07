defmodule UnifiedUi.Adapters.Web.StyleTest do
  use ExUnit.Case, async: true

  alias UnifiedIUR.Style
  alias UnifiedUi.Adapters.Web.Style, as: WebStyle

  test "to_css/1 maps fg/bg and text attrs" do
    css =
      WebStyle.to_css(%Style{
        fg: :cyan,
        bg: :black,
        attrs: [:bold, :underline, :italic, :strikethrough, :dim]
      })

    assert css =~ "color: cyan"
    assert css =~ "background-color: black"
    assert css =~ "font-weight: bold"
    assert css =~ "text-decoration: underline"
    assert css =~ "font-style: italic"
    assert css =~ "text-decoration: line-through"
    assert css =~ "opacity: 0.7"
  end

  test "to_css/1 supports string, rgb, and rgba color inputs" do
    rgb_css = WebStyle.to_css(%Style{fg: {12, 34, 56}})
    rgba_css = WebStyle.to_css(%Style{bg: {1, 2, 3, 128}})
    hex_css = WebStyle.to_css(%Style{fg: "#ff00aa"})

    assert rgb_css =~ "color: rgb(12, 34, 56)"
    assert rgba_css =~ "background-color: rgba(1, 2, 3, "
    assert hex_css =~ "color: #ff00aa"
  end

  test "to_css/1 returns empty css for nil style" do
    assert WebStyle.to_css(nil) == ""
  end

  test "add_to_css/2 appends style css to existing css" do
    assert WebStyle.add_to_css("display: block", nil) == "display: block"

    appended = WebStyle.add_to_css("display: block", %Style{fg: :green})
    assert appended == "display: block; color: green"

    replacement = WebStyle.add_to_css("", %Style{bg: :blue})
    assert replacement == "background-color: blue"
  end

  test "merge_styles/1 accumulates non-nil styles in order" do
    css =
      WebStyle.merge_styles([
        %Style{fg: :red},
        nil,
        %Style{bg: :white, attrs: [:bold]}
      ])

    assert css =~ "color: red"
    assert css =~ "background-color: white"
    assert css =~ "font-weight: bold"
  end
end
