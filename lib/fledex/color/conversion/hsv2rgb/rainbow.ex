# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.Rainbow do
  @moduledoc """
  Module defininig an `hsv2rgb/2` conversion following the rainbow
  color map.

  This does give more enphasis to yellow. An alternative color map
  would be the Spectrum color map, which has very little yellow
  which often feels less natural.
  """
  import Bitwise

  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.HSV
  alias Fledex.Color.Types

  @k255 255
  @k171 171
  @k170 170
  @k85 85

  @doc """
  Fledex uses by default a Rainbow color conversion from HSV to RGB

  Fledex does also provide a `Fledex.Color.Conversion.Spectrum` color
  conversion, but more effort from your side is required to use them. See this
  [great article](https://github.com/FastLED/FastLED/wiki/FastLED-HSV-Colors)
  to understand the difference between the two
  """
  @spec hsv2rgb(Types.hsv(), (Types.rgb() -> Types.rgb())) :: Types.rgb()
  def hsv2rgb(%HSV{h: h, s: s, v: v}, extra_color_correction) do
    # based on: https://github.com/FastLED/FastLED/blob/95d0a5582b2052729f345719e65edf7a4b9e7098/src/hsv2rgb.cpp#L267
    determine_rgb(h)
    |> extra_color_correction.()
    |> desaturate(s)
    |> scale_brightness(v)
  end

  # MARK: private utility functions
  @third div(256, 3)
  @twothird div(256 * 2, 3)
  @spec determine_rgb(byte) :: Types.rgb()
  defp determine_rgb(h) do
    main = {(h &&& 0x80) > 0, (h &&& 0x40) > 0, (h &&& 0x20) > 0}
    offset = h &&& 0x1F
    offset8 = offset <<< 3

    third = CalcUtils.scale8(offset8, @third)
    twothird = CalcUtils.scale8(offset8, @twothird)
    build_rgb(main, third, twothird)
  end

  @spec build_rgb({boolean, boolean, boolean}, byte, byte) :: Types.rgb()
  defp build_rgb({false, false, false}, third, _twothird) do
    {@k255 - third, third, 0}
  end

  defp build_rgb({false, false, true}, third, _twothird) do
    {@k171, @k85 + third, 0}
  end

  defp build_rgb({false, true, false}, third, twothird) do
    {@k171 - twothird, @k170 + third, 0}
  end

  defp build_rgb({false, true, true}, third, _twothird) do
    {0, @k255 - third, third}
  end

  defp build_rgb({true, false, false}, _third, twothird) do
    {0, @k171 - twothird, @k85 + twothird}
  end

  defp build_rgb({true, false, true}, third, _twothird) do
    {third, 0, @k255 - third}
  end

  defp build_rgb({true, true, false}, third, _twothird) do
    {@k85 + third, 0, @k171 - third}
  end

  defp build_rgb({true, true, true}, third, _twothird) do
    {@k170 + third, 0, @k85 - third}
  end

  @spec desaturate(Types.rgb(), byte) :: Types.rgb()
  defp desaturate({r, g, b}, 255), do: {r, g, b}
  defp desaturate(_na, 0), do: {255, 255, 255}

  defp desaturate({r, g, b}, s) do
    desat = 255 - s
    desat = CalcUtils.scale8(desat, desat, true)
    satscale = 255 - desat
    {r, g, b} = CalcUtils.nscale8({r, g, b}, satscale, true)

    {r + desat, g + desat, b + desat}
  end

  # scales the brightness (the v part of HSV, aka HSB)
  @spec scale_brightness(Types.rgb(), byte) :: Types.rgb()
  defp scale_brightness(rgb, 255), do: rgb
  defp scale_brightness(_na, v) when (v * v) >>> 8 == 0, do: {0, 0, 0}

  defp scale_brightness({r, g, b}, v) do
    val = CalcUtils.scale8(v, v, true)
    CalcUtils.nscale8({r, g, b}, val, true)
  end
end
