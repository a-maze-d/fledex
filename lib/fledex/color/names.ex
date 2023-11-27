defmodule Fledex.Color.Names do
  @moduledoc """
  Fledex has an extensive set of predefined colors from
  [Wikipedia](https://en.wikipedia.org/wiki/List_of_colors:_A%E2%80%93F). You can retrieve the information through this module
  by calling the different functions.

  You can also retrieve the information from a specific color, like `:almond` by calling the function with the same name, i.e.
  `almond/1`. It should be noted, that the color functions in other modules (are often just approximations) and do not
  provide the same results. The values returned here are the ones as defined on the Wikipedia page.

  The additional parameter determines which additional information should be provided. The options are:

    * `:all`: This retrieves the full data set
    * `:desriptive_name`: a string with name (from this the Atom is derived)
    * `:hex` (default): This is the same as `almond/0`
    * `:hsl`: This retrieves an HSL struct, i.e. `{h, s, l}`
    * `:hsv`: This retrieves an HSV struct, i.e. `{h, s, v}`
    * `:index`: The index of this color in the list of all colors
    * `:rgb`: This retrieves an RGB struct, i.e. `{r, g, b}`
    * `:source`: Information where the color comes from, see Wikipedia for more details
  """
  @external_resource Fledex.Color.LoadUtils.names_file()

  import Fledex.Color.Types

  alias Fledex.Color.LoadUtils

  @type t :: %{
    index: integer,
    name: atom,
    descriptive_name: String.t,
    hex: Types.colorint,
    rgb: Types.rgb,
    hsl: Types.hsl,
    hsv: Types.hsv,
    source: String.t
  }

  colors = LoadUtils.load_color_file(@external_resource)
  for color <- colors do
    name = color.name
    @doc """
    See the module docs for `Fledex.Color.Names` for more info
    """
    @doc color_name: true
    @spec unquote(name)(atom) :: Types.colorint | Types.rgb | Types.hsv | Types.hsl | t
    def unquote(name)(what \\ :hex)
    def unquote(name)(:all), do: unquote(Macro.escape(color))
    def unquote(name)(:index), do: unquote(Macro.escape(color)).index
    # def unquote(name)(:name), do: unquote(Macro.escape(color)).name
    def unquote(name)(:rgb), do: unquote(Macro.escape(color)).rgb
    def unquote(name)(:hex), do: unquote(Macro.escape(color)).hex
    def unquote(name)(:hsv), do: unquote(Macro.escape(color)).hsv
    def unquote(name)(:hsl), do: unquote(Macro.escape(color)).hsl
    def unquote(name)(:descriptive_name), do: unquote(Macro.escape(color)).descriptive_name
    def unquote(name)(:source), do: unquote(Macro.escape(color)).source
  end

  @colors colors
  @color_names Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)

  quote do
    @type t :: unquote_splicing(@color_names)
  end

  defguard is_color_name(atom) when atom in @color_names

  @doc """
  Get all the data about the predefined colors
  """
  @spec colors :: list(t)
  def colors do
    @colors
  end

  @doc """
  Get a list of all the predefined color (atom) names. The name can be used to either
  retrieve the info by calling `info/2` or by calling the function with that
  name (see also the [example livebook](3b_fledex_more_about_colors.livemd))
  """
  @spec names :: list(atom)
  def names do
    @color_names
  end
  @doc """
  Retrieve information about the color with the given name
  """
  @spec info(name :: atom, what :: atom) :: Types.colorint | Types.rgb | Types.hsv | Types.hsl | t
  def info(name, what \\ :hex) do
    apply(__MODULE__, name, [what])
  end
end
