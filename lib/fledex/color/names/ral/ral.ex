# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.RAL do
  @moduledoc """
  This module defines all the named colors in the RAL Design System Plus, see:
  https://en.wikipedia.org/wiki/List_of_RAL_colours#RAL_Design_System+

  > **Note**
  > This module implements the `Fledex.Color.Names.Interface` behaviour.
  """
  alias Fledex.Color
  alias Fledex.Color.Conversion.Approximate
  alias Fledex.Color.Names.LoadUtils

  @external_resource Path.dirname(__DIR__) <> "/ral/ral_colors.csv"

  use Fledex.Color.Names.Dsl,
    filename: @external_resource,
    pattern: ~r/^.*$/i,
    drop: 0,
    splitter_opts: [separator: ~r/\t+/, split_opts: [trim: true]],
    converter: fn [index, name, _h, _l, _c, r, g, b, code] ->
      # I don't know how to convert the CIELAB 1931 colorspace
      # with Hue, Lightness, Chromacity to HSV or HSL. Is there
      # maybe even an overlap? Is it the same as the XYZ color space?
      # Is it the LAB model?
      # Maybe look at color conversion library
      # https://github.com/colormine/colormine/blob/master/colormine/src/main/org/colormine/colorspace/ColorSpaceConverter.java#L29
      # Thus, we only use the RGB values
      rgb = {LoadUtils.a2i(r), LoadUtils.a2i(g), LoadUtils.a2i(b)}

      %{
        index: index,
        name: LoadUtils.convert_to_atom(name),
        descriptive_name: String.trim(name),
        hex: Color.to_colorint(rgb),
        rgb: rgb,
        # convert the rgb to other color spaces
        # {LoadUtils.to_byte(h), LoadUtils.to_byte(s1), LoadUtils.to_byte(l1)},
        hsl: {0, 0, 0},
        hsv: Approximate.rgb2hsv(rgb),
        source: "RAL design system+: #{code}"
      }
    end,
    module: __MODULE__
end
