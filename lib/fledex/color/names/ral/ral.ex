# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.RAL do
  @moduledoc """
  This module defines all the named colors in the RAL Design System Plus, see:
  https://en.wikipedia.org/wiki/List_of_RAL_colours#RAL_Design_System+

  > #### Note {: .info}
  >
  > * This module implements the `@behaviour` [`Fledex.Color.Names.Interface`](`m:Fledex.Color.Names.Interface`) (check it out for more details).
  > * Every color has it's own function as explained in `Fledex.Color.Names.Interface` and supports the following options (`:all`, `:descriptive_name`, `:hex`, `:index`, `:name`, `:rgb`, `:source`, `:module`)
  > * A list of all available colors from this module can be found in the documentation under [Colors](colors.md#ral).
  """
  alias Fledex.Color
  alias Fledex.Color.Names.LoadUtils

  @external_resource Path.dirname(__DIR__) <> "/ral/ral_colors.csv"

  use Fledex.Color.Names.ModuleGenerator,
    filename: @external_resource,
    drop: 0,
    splitter_opts: [separator: ~r/\t+/, split_opts: [trim: true]],
    converter: fn [index, name, _h, _l, _c, r, g, b, code] ->
      rgb = {LoadUtils.a2i(r), LoadUtils.a2i(g), LoadUtils.a2i(b)}

      %{
        index: index,
        name: LoadUtils.str2atom(name),
        descriptive_name: String.trim(name),
        hex: Color.to_colorint(rgb),
        rgb: rgb,
        source: "RAL design system+: #{code}"
      }
    end
end
