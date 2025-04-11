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

  You can retrieve the information through their respective modules (Fledex.Color.Names.Wiki.Wiki,
  Fledex.Color.Names.CSS, Fledex.Color.Names.SVG, and Fledex.Color.Names.RAL)
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
    * `:hsv`: This retrieves an HSV struct, i.e. `{h, s, v}`
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

  **Note:**
  RAL colours do have name and a code (the official "name"), but neither of those are
  commonly used and therefore those colors are NOT exposed through this interface. The
  list is already more extensive than is really needed. But maybe for some special
  application they might be useful. Thus, you will have to use those colors from the
  `Fledex.Color.Names.RAL` module directly. All color names modules have the same
  interface.
  """
  import Fledex.Color.Names.Guards

  alias Fledex.Color.Names.Types

  # List of modules that define coulors that should be loaded
  # Note: if there is an overlap between the lists, i.e. the same color name
  #       appears twice, then only the first definition will be used.
  #       Thus, the different color modules should be sorted accordingly
  #       You can still call the alternative color definition by going
  #       to the defining module directly.
  @modules [
    Fledex.Color.Names.Wiki,
    Fledex.Color.Names.CSS,
    Fledex.Color.Names.SVG
    # we intentionally do not include RAL colors
    # FLedex.Color.Names.RAL,
  ]

  seen = MapSet.new()
  module_names = []

  {module_names, _seen} =
    Enum.reduce(@modules, {module_names, seen}, fn module, {module_names, seen} ->
      Enum.reduce(module.names, {module_names, seen}, fn name, {module_names, seen} ->
        if name in seen do
          {module_names, seen}
        else
          {[{module, name} | module_names], MapSet.put(seen, name)}
        end
      end)
    end)

  for {module, name} <- module_names do
    @doc Fledex.Color.Names.DocUtils.extract_doc(module, name, 1)
    @doc color_name: true
    defdelegate unquote(name)(), to: module
    @doc false
    defdelegate unquote(name)(param), to: module
    @doc false
    defdelegate unquote(name)(param, opts), to: module
  end

  @typedoc """
  The allowed color names
  """
  @type color_names_t ::
          unquote(
            Enum.flat_map(@modules, fn module ->
              module.names
            end)
            |> Enum.uniq()
            |> Enum.sort()
            |> Enum.map_join(" | ", &inspect/1)
            |> Code.string_to_quoted!()
          )

  @doc """
  Get all the data about the predefined colors
  """
  @spec colors :: list(Types.color_struct_t())
  def colors do
    Enum.flat_map(@modules, fn module ->
      module.colors
    end)
    |> Enum.uniq_by(fn color -> color.name end)
  end

  @doc """
  Get a list of all the predefined color (atom) names.

  The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
  name (see also the description at the top and take a look at this [example livebook](3b_fledex_more_about_colors.livemd))
  """
  @spec names :: list(color_names_t)
  def names do
    Enum.flat_map(@modules, fn module ->
      module.names
    end)
  end

  @doc """
  Retrieve information about the color with the given name
  """
  @spec info(name :: Types.color_names_t(), what :: Types.color_props_t()) :: Types.color_vals_t()
  def info(name, what \\ :hex)
  def info(name, what) when is_color_name(name), do: apply(__MODULE__, name, [what])
  def info(_name, _what), do: nil
end
