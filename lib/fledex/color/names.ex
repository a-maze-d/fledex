defmodule Fledex.Color.Names do
  @external_resource Fledex.Color.LoadUtils.names_file()
  alias Fledex.Color.LoadUtils

  colors = LoadUtils.load_color_file(@external_resource)
  for color <- colors do
    name = color.name
    def unquote(name)(), do: unquote(Macro.escape(color)).hex
    def unquote(name)(:info), do: unquote(Macro.escape(color))
    def unquote(name)(:rgb), do: unquote(Macro.escape(color)).rgb
    def unquote(name)(:hex), do: unquote(Macro.escape(color)).hex
    def unquote(name)(:hsv), do: unquote(Macro.escape(color)).hsv
    def unquote(name)(:hsl), do: unquote(Macro.escape(color)).hsl
  end

  @colors colors
  @color_names Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)
  def colors do
    @colors
  end

  def names do
    @color_names
  end
end
