defmodule Fledex.Color.Names do
  alias Fledex.Color.LoadUtils

  # TODO: Create functions for the color data so we can get fast access
  colors = LoadUtils.load_color_file()
  for color <- colors do
    # IO.puts("some Text #{color.name}")
    name = color.name
    def unquote(name)(), do: unquote(Macro.escape(color))
    # end # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @colors colors
  def colors do
    @colors
    # unquote(Macro.escape(colors))
  end

  def names do
    Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)
  end
  def get_color_int(name) when is_atom(name) do
    # call the function with the same name as the atom
    colorinfo = apply(__MODULE__, name, [])
    colorinfo.hex
  end
end
