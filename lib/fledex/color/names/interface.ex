# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Interface do
  @moduledoc """
  This module defines the standard interface (behaviour) for color names modules
  which they should implement.

  The easiest way to generate a color names module is probably by reading in a csv file
  with the definitions with the help of `Fledex.Color.Names.ModuleGenerator`

  Fledex has an extensive set of predefined colors from:

  * `Fledex.Color.Names.Wiki` from [Wikipedia - List of colors A-F](https://en.wikipedia.org/wiki/List_of_colors:_A%E2%80%93F),
    [Wikipedia - List of colors G-M](https://en.wikipedia.org/wiki/List_of_colors:_N%E2%80%93Z),
    [Wikipedia - List of colors N-Z](https://en.wikipedia.org/wiki/List_of_colors:_G%E2%80%93M)
  * `Fledex.Color.Names.CSS` from [W3C - CSS colors](https://drafts.csswg.org/css-color/#named-colors)
  * `Fledex.Color.Names.SVG` from [W3C - SVG colors](https://www.w3.org/TR/SVG11/types.html#ColorKeywords)
  * `Fledex.Color.Names.RAL` from [Wikipedia - List of RAL colors](https://en.wikipedia.org/wiki/List_of_RAL_colours)

  The behaviour only defines a very small set of functions, but it is expected that each color is reachable through a function with the name of the color. For example, you can
  retrieve the information for the color `:almond` by calling the function with the same
  name, i.e. `almond/1`.

  The additional parameter determines which additional information should be provided. Each color module can define it's own set of parameters (except `:all`, `:hex`, and `:name` that are mandatory), but the classical options are:

    * `:all`: This retrieves the full data set
    * `:descriptive_name`: a string with name (from this the Atom is derived)
    * `:hex` (default): This is the same as `almond/0`
    * `:hsl`: This retrieves an HSL struct, i.e. `Fledex.Color.HSL`
    * `:hsv`: This retrieves an HSV struct, i.e. `Fledex.Color.HSV`
    * `:index`: The index of this color in the list of all colors
    * `:rgb`: This retrieves an RGB struct, i.e. `{r, g, b}`
    * `:source`: Information where the color comes from, see Wikipedia for more details
    * `:module`: to get more information where the color is actually implemented. The function might return `:unknown`

  And finally every color exists also in a version that allows you to add it to a
  `Fledex.Leds` sequence. Either as next led (`almond/1`) or with a specified offset
  (`almond/2`). The latter has no extra documentation, because it wouldn't add any real
  value, but would clutter the doc. Here an example spec:

  ```elixir
  @spec almond(leds :: Fledex.Leds.t, offset :: non_neg_integer) :: Fledex.Leds.t
  ```

  Some additional functions exist for retrieving all `colors`, all color `names`,
  and `info` about an `atom` color. Thus, you can get the same information for
  `almond()` by calling `info(:almond, :hex)`
  """

  alias Fledex.Color.Names.Types
  alias Fledex.Color.Types, as: ColorTypes

  @doc ~S"""
  Check whether the atom is a valid color name
  """
  @doc guard: true
  @macrocallback is_color_name(atom) :: Macro.t()

  @doc ~S"""
  Get all the data about the predefined colors
  """
  @callback colors :: list(Types.color_struct_t())

  @doc ~S"""
  Get a list of all the predefined color (atom) names.

  The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
  name (see also the description at the top and take a look at this [example
  livebook](3b_fledex_everything_about_colors.livemd))
  """
  @callback names :: list(atom)

  @doc """
  Retrieve information about the color with the given name
  """
  @callback info(name :: atom, :index) :: nil | integer
  @callback info(name :: atom, :name) :: nil | Types.color_name_t()
  @callback info(name :: atom, :descriptive_name) :: nil | String.t()
  @callback info(name :: atom, :hex) :: nil | ColorTypes.colorint()
  @callback info(name :: atom, :rgb) :: nil | ColorTypes.rgb()
  @callback info(name :: atom, :hsl) :: nil | ColorTypes.hsl()
  @callback info(name :: atom, :hsv) :: nil | ColorTypes.hsv()
  @callback info(name :: atom, :source) :: nil | String.t()
  @callback info(name :: atom, :module) :: nil | module()
  @callback info(name :: atom, :all) :: nil | Types.color_vals_t()
  @callback info(name :: atom, what :: atom) :: any()
end
