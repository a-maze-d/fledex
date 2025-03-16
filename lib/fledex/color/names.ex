# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
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
    * `:descriptive_name`: a string with name (from this the Atom is derived)
    * `:hex` (default): This is the same as `almond/0`
    * `:hsl`: This retrieves an HSL struct, i.e. `{h, s, l}`
    * `:hsv`: This retrieves an HSV struct, i.e. `{h, s, v}`
    * `:index`: The index of this color in the list of all colors
    * `:rgb`: This retrieves an RGB struct, i.e. `{r, g, b}`
    * `:source`: Information where the color comes from, see Wikipedia for more details

  And finally every color exists also in a version that allows you to add it to a `Fledex.Leds`
  sequence. Either as next led (`almond/1`) or with a specified offset (`almond/2`). The latter
  has no extra documentation, because it wouldn't add any real value, but would clutter the doc.
  Here an example spec:

  ```elixir
  @spec almond(leds :: Fledex.Leds.t, offset :: non_neg_integer) :: Fledex.Leds.t
  ```

  Some additional functions exist for guards and for retrieving all colors.
  """
  # TODO: extend with (if not already included):
  # * CSS colors: https://drafts.csswg.org/css-color/#named-colors
  # * RAL colors: https://en.wikipedia.org/wiki/List_of_RAL_colours
  import Fledex.Color.Names.Guards
  alias Fledex.Color.Names.Types

  @modules [
    Fledex.Color.Names.NamesWikiA2H,
    Fledex.Color.Names.NamesWikiI2O,
    Fledex.Color.Names.NamesWikiP2Z
  ]

  for module <- @modules do
    for name <- module.names do
      defdelegate unquote(name)(), to: module
      defdelegate unquote(name)(param), to: module
      defdelegate unquote(name)(param, offset), to: module
    end
  end

  @typedoc """
  The allowed color names
  """
  @type color_names_t ::
          unquote(
            Enum.flat_map(@modules, fn module ->
              module.names
            end)
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
