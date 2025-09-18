# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.CSS do
  @moduledoc ~S"""
  This module defines all the named colors in the CSS standard, see:
  https://drafts.csswg.org/css-color/#named-colors

  Prefer to not use this module directly, but use `Fledex.Color.Names` instead.

  > **Note**
  > This module implements the `Fledex.Color.Names.Interface` behaviour.
  """
  alias Fledex.Color.Conversion.Approximate
  alias Fledex.Color.Names.LoadUtils

  @external_resource Path.dirname(__DIR__) <> "/css/css_colors.csv"

  use Fledex.Color.Names.Dsl,
    filename: @external_resource,
    pattern: ~r/^.*$/i,
    drop: 1,
    splitter_opts: [separator: ~r/\s+/, split_opts: [trim: true]],
    converter: fn [index, name, hex, r, g, b] ->
      rgb = {LoadUtils.a2i(r), LoadUtils.a2i(g), LoadUtils.a2i(b)}

      %{
        index: index,
        name: LoadUtils.convert_to_atom(name),
        descriptive_name: String.trim(name),
        hex: LoadUtils.clean_and_convert(hex),
        rgb: rgb,
        # convert the rgb to other color spaces
        # {LoadUtils.to_byte(h), LoadUtils.to_byte(s1), LoadUtils.to_byte(l1)},
        hsl: {0, 0, 0},
        hsv: Approximate.rgb2hsv(rgb),
        source: "CSS standard"
      }
    end,
    module: __MODULE__
end
