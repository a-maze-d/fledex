# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.CSS do
  @moduledoc ~S"""
  This module defines all the named colors in the CSS standard, see:
  https://drafts.csswg.org/css-color/#named-colors

  > #### Note {: .info}
  >
  > * This module implements the `@behaviour` [`Fledex.Color.Names.Interface`](`m:Fledex.Color.Names.Interface`) (check it out for more details).
  > * Every color has it's own function as explained in `Fledex.Color.Names.Interface` and supports the following options (`:all`, `:descriptive_name`, `:hex`, `:index`, `:name`, `:rgb`, `:source`, `:module`)
  > * A list of all available colors from this module can be found in the documentation under [Colors](colors.md#css).
  """
  alias Fledex.Color.Names.LoadUtils

  @external_resource Path.dirname(__DIR__) <> "/css/css_colors.csv"

  use Fledex.Color.Names.ModuleGenerator,
    filename: @external_resource,
    splitter_opts: [separator: ~r/\s+/, split_opts: [trim: true]],
    converter: fn [index, name, hex, r, g, b] ->
      rgb = {LoadUtils.a2i(r), LoadUtils.a2i(g), LoadUtils.a2i(b)}

      %{
        index: index,
        name: LoadUtils.str2atom(name),
        descriptive_name: String.trim(name),
        hex: LoadUtils.hexstr2i(hex),
        rgb: rgb,
        source: "CSS standard"
      }
    end
end
