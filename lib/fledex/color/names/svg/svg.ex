# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.SVG do
  alias Fledex.Color.Conversion.Approximate
  alias Fledex.Color.Names.LoadUtils

  @external_resource Path.dirname(__DIR__) <> "/svg/svg_colors.csv"

  use Fledex.Color.Names.Dsl,
    filename: @external_resource,
    pattern: ~r/^.*$/i,
    drop: 1,
    splitter_opts: [separator: ~r/\s+/, split_opts: [trim: true]],
    converter: fn all ->
      # IO.puts(inspect all)
      [index, name, r, g, b] =
        case all do
          [index, name, r, g, b] -> [index, name, r, g, b]
          [index, name, _rgb, r, g, b] -> [index, name, r, g, b]
        end

      rgb = {
        r |> LoadUtils.clean() |> LoadUtils.a2i(),
        g |> LoadUtils.clean() |> LoadUtils.a2i(),
        b |> LoadUtils.clean() |> LoadUtils.a2i()
      }

      %{
        index: index,
        name: LoadUtils.convert_to_atom(name),
        descriptive_name: String.trim(name),
        hex: LoadUtils.to_colorint(rgb),
        rgb: rgb,
        # TODO: convert the rgb to other color spaces
        # {LoadUtils.to_byte(h), LoadUtils.to_byte(s1), LoadUtils.to_byte(l1)},
        hsl: {0, 0, 0},
        hsv: Approximate.rgb2hsv(rgb),
        source: "SVG standard"
      }
    end,
    module: __MODULE__
end
