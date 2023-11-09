defmodule Fledex.Color.Names do
  @external_resource Fledex.Color.LoadUtils.names_file()
  alias Fledex.Color.LoadUtils

  colors = LoadUtils.load_color_file(@external_resource)
  for color <- colors do
    name = color.name
    def unquote(name)(), do: unquote(Macro.escape(color))
  end

  @colors colors
  @color_names Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)
  def colors do
    @colors
  end

  def names do
    @color_names
  end
  def get_color_int(name) when is_atom(name) do
    # call the function with the same name as the atom
    colorinfo = apply(__MODULE__, name, [])
    colorinfo.hex
  end
  def get_color_sub_pixels(name) when is_atom(name) do
    # call the function with the same name as the atom
    colorinfo = apply(__MODULE__, name, [])
    colorinfo.rgb
  end
end
