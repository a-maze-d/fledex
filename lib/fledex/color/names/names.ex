# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names do
  @moduledoc """
  Fledex has an extensive set of predefined colors from:

  * [Wikipedia - List of colors A-F](https://en.wikipedia.org/wiki/List_of_colors:_A%E2%80%93F),
    [Wikipedia - List of colors G-M](https://en.wikipedia.org/wiki/List_of_colors:_N%E2%80%93Z),
    [Wikipedia - List of colors N-Z](https://en.wikipedia.org/wiki/List_of_colors:_G%E2%80%93M)
  * [W3C - CSS colors](https://drafts.csswg.org/css-color/#named-colors)
  * [W3C - SVG colors](https://www.w3.org/TR/SVG11/types.html#ColorKeywords)
  * [Wikipedia - List of RAL colors](https://en.wikipedia.org/wiki/List_of_RAL_colours)

  You can retrieve the information through their respective color names modules (`Fledex.Color.Names.Wiki.Wiki`,
  `Fledex.Color.Names.CSS`, `Fledex.Color.Names.SVG`, and `Fledex.Color.Names.RAL`)
  This module binds (most of) them together into a single module (in case of conflict the
  first mentioned module definition will win).

  Each color is reachable through a function with the name of the color. For example, you can
  retrieve the information for the color `:almond` by calling the function with the same name, i.e.
  `almond/1`. It should be noted, that the color functions are defined in other modules and we only
  delegate to those. Still the documentation is directly available in this module.

  The additional parameter determines which additional information should be provided. The options are:

    * `:all`: This retrieves the full data set
    * `:descriptive_name`: a string with name (from this the Atom is derived)
    * `:hex` (default): This is the same as `almond/0`
    * `:hsl`: This retrieves an HSL struct, i.e. `{h, s, l}`
    * `:hsv`: This retrieves an HSV struct, i.e. `Fledex.Color.HSV`
    * `:index`: The index of this color in the list of all colors
    * `:rgb`: This retrieves an RGB struct, i.e. `{r, g, b}`
    * `:source`: Information where the color comes from, see Wikipedia for more details
    * `:module`: to get more information where the color is actually implemented. The function might return `:unknown`

  And finally every color exists also in a version that allows you to add it to a `Fledex.Leds`
  sequence. Either as next led (`almond/1`) or with a specified offset (`almond/2`). The latter
  has no extra documentation, because it wouldn't add any real value, but would clutter the doc.
  Here an example spec:

  ```elixir
  @spec almond(leds :: Fledex.Leds.t, offset :: non_neg_integer) :: Fledex.Leds.t
  ```

  Some additional functions exist for retrieving all `colors`, all color `names`, and `info` about an
  `atom` color. Thus, you can get the same information for `almond()` by calling
  `info(:almond, :hex)`

  > #### Note {: .info}
  >
  > RAL colours do have a name and a code (the official "name"), but neither of those are
  > commonly used and therefore those colors are NOT exposed through this interface. The
  > list is already more extensive than is really needed. But maybe for some special
  > application they might be useful. Thus, you will have to use those colors from the
  > `Fledex.Color.Names.RAL` module directly. You can easily use them by using `Fledex.Color`
  > too (implicitly or explicitly). Let's assume you want to use the `:sunset_red` RAL color,
  > then you can use it like the following:
  > ```elixir
  > Leds.new(10)
  >   |> Leds.light(:sunset_red)
  >   |> Leds.light(Fledex.Color.to_colorint(:sunset_red))
  >   |> Leds.light(Fledex.Color.to_rgb(:sunset_red))
  >   |> Leds.light(Fledex.Color.Names.RAL.sunset_red(:hex))
  >   |> Leds.light(Fledex.Color.Names.RAL.sunset_red(:rgb))
  >   |> Fledex.Color.Names.RAL.sunset_red()
  > ```
  > you can also import `Fledex.Color.Names.RAL` to make `sunset_red()` available and
  > thereby get more or less the same convenience

  > #### Note {: .info}
  >
  > This module implements the `Fledex.Color.Names.Interface` behaviour.
  """
  @behaviour Fledex.Color.Names.Interface

  require Logger

  # I think the documentation is not picking up the
  # behaviour if we use the alias before the behaviour
  alias Fledex.Color.Names.Interface
  alias Fledex.Color.Names.Types

  # List of modules that define colors that should be loaded
  # Note: if there is an overlap between the lists, i.e. the same color name
  #       appears twice, then only the first definition will be used.
  #       Thus, the different color modules should be sorted accordingly
  #       You can still call the alternative color definition by going
  #       to the defining module directly.
  # Note2: Each color module can be of type `:core` and therefore will be included
  #       in the Fledex.Color.Names module or of tpe `:optional` which can still
  #       be used through the `Fledex.Color` protocol by calling:
  #       to_colorint(some_atom), which will also be looked up in optional
  #       color modules
  @modules [
    {Fledex.Color.Names.Wiki, :core, :wiki},
    {Fledex.Color.Names.CSS, :core, :css},
    {Fledex.Color.Names.SVG, :core, :svg},
    # we intentionally do not include RAL colors as `:core`
    {Fledex.Color.Names.RAL, :optional, :ral}
  ]

  @doc """
  This module allows to define a single interface for several color modules
  Instead of importing this module use `use #{__MODULE__}` instead.

  This allows  to control which color name spaces (and in which order)
  get imported.

  > #### Note {: .info}
  >
  > If no colors are defined (i.e. `colors: []` is specified), then nothing will
  > be created.
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(opts \\ []) do
    color_mod_name_defined = Keyword.has_key?(opts, :color_mod_name)
    color_mod_name = Keyword.get(opts, :color_mod_name, nil)
    colors = Keyword.get(opts, :colors, [])
    if Enum.empty?(colors) or (color_mod_name_defined and color_mod_name == nil) do
      nil
    else
      color_mod_name = color_mod_name || Fledex.Color.Names
      quote do
        defmodule unquote(color_mod_name) do
          @modules_and_colors unquote(colors)
          def modules_and_colors do
            @modules_and_colors
          end
        end
      end
    end
  end

  @doc """
  gets a list of modules that define colors. Only the core
  module are available directlyl through this module
  """
  @spec color_name_modules :: list({module(), :core | :optional})
  def color_name_modules do
    @modules
  end

  seen = MapSet.new()
  module_names = []

  {module_names, _seen} =
    Enum.reduce(@modules, [], fn
      # filter out optional modules
      {module, :core, _name}, acc -> [module | acc]
      {_module, _type, _name}, acc -> acc
    end)
    |> Enum.reverse()
    |> Enum.reduce({module_names, seen}, fn module, {module_names, seen} ->
      Enum.reduce(module.names(), {module_names, seen}, fn name, {module_names, seen} ->
        if name in seen do
          {module_names, seen}
        else
          {[{module, name} | module_names], MapSet.put(seen, name)}
        end
      end)
    end)

  for {module, name} <- module_names do
    # Note: This requires my hacked version of ex_doc!!!
    # Note2: we use the arity = 1 version, because the function has a
    #        default parameter, the arity=0 version has no documentation!
    @doc copy: {module, name, 1}
    @doc color_name: true
    defdelegate unquote(name)(), to: module
    @doc false
    defdelegate unquote(name)(what_or_leds), to: module
    @doc false
    defdelegate unquote(name)(what_or_leds, opts), to: module
  end

  @typedoc """
  The allowed color names
  """
  @type color_names_t ::
          unquote(
            Enum.flat_map(@modules, fn
              {module, :core, _name} -> module.names()
              {_module, _type, _name} -> []
            end)
            |> Enum.uniq()
            |> Enum.sort()
            |> Enum.map_join(" | ", &inspect/1)
            |> Code.string_to_quoted!()
          )

  @doc """
    All atoms are valid color names.

    If the color name can't be resolved to a color in
    `Fledex.Color.to_colorint/1` or `Fledex.Color.to_rgb/1`
    then black will be used instead.
    You can use the individual guards in the various color definitions
    if you really want to guard for specific color names.
  """
  @impl Interface
  @doc guard: true
  defguard is_color_name(atom) when is_atom(atom)

  @doc ~S"""
  Get all the data about the predefined colors
  """
  @impl Interface
  @spec colors :: list(Types.color_struct_t())
  def colors do
    Enum.flat_map(@modules, fn
      {module, :core, _name} -> module.colors()
      {_module, _type, _name} -> []
    end)
    |> Enum.uniq_by(fn color -> color.name end)
  end

  @doc ~S"""
  Get a list of all the predefined color (atom) names.

  The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
  name (see also the description at the top and take a look at this [example
  livebook](3b_fledex_everything_about_colors.livemd))
  """
  @impl Interface
  @spec names :: list(color_names_t)
  def names do
    Enum.flat_map(@modules, fn
      {module, :core, _name} -> module.names()
      {_module, _type, _name} -> []
    end)
    |> Enum.uniq()
  end

  @doc """
  Retrieve information about the color with the given name
  """
  @impl Interface
  def info(name, what \\ :hex)
  # def info(name, what) when is_color_name(name), do: apply(__MODULE__, name, [what])
  def info(name, what) do
    case function_exported?(__MODULE__, name, 1) do
      true -> apply(__MODULE__, name, [what])
      false -> nil
    end
  end
end
