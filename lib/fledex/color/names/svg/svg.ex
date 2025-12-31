# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.SVG do
  @moduledoc ~S"""
  This module defines all the named colors in the SVG standard, see:
  https://www.w3.org/TR/SVG11/types.html#ColorKeywords

  > #### Note {: .info}
  >
  > * This module implements the `@behaviour` [`Fledex.Color.Names.Interface`](`m:Fledex.Color.Names.Interface`) (check it out for more details).
  > * Every color has it's own function as explained in `Fledex.Color.Names.Interface` and supports the following options (`:all`, `:descriptive_name`, `:hex`, `:index`, `:name`, `:rgb`, `:source`, `:module`)
  > * A list of all available colors from this module can be found in the documentation under [Colors](colors.md#svg).
  """
  alias Fledex.Color
  alias Fledex.Color.Names.LoadUtils

  # @external_resource Path.dirname(__DIR__) <> "/svg/svg_colors.csv"

  use Fledex.Color.Names.ModuleGenerator,
    filename: "svg_colors.csv",
    splitter_opts: [separator: ~r/\s+/, split_opts: [trim: true]],
    converter: fn all ->
      [index, name, r, g, b] =
        case all do
          [index, name, r, g, b] -> [index, name, r, g, b]
          [index, name, _rgb, r, g, b] -> [index, name, r, g, b]
        end

      rgb = {
        LoadUtils.a2i(r),
        LoadUtils.a2i(g),
        LoadUtils.a2i(b)
      }

      %{
        index: index,
        name: LoadUtils.str2atom(name),
        descriptive_name: String.trim(name),
        hex: Color.to_colorint(rgb),
        rgb: rgb,
        source: "SVG standard"
      }
    end
end
