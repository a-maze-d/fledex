# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.Spectrum do
  @moduledoc """
  Spectrum color conversion from HSV to RGB

  > **Note**
  > Fledex uses by default the `Fledex.Color.Conversion.Rainbow` color conversion
  """
  alias Fledex.Color.Conversion.CalcUtils

  alias Fledex.Color.HSV
  alias Fledex.Color.Types

  @spec hsv2rgb(Types.hsv(), (Types.rgb() -> Types.rgb())) :: Types.rgb()
  def hsv2rgb(%HSV{h: h, s: _s, v: _v} = hsv, extra_color_correction) do
    # based on https://github.com/FastLED/FastLED/blob/95d0a5582b2052729f345719e65edf7a4b9e7098/src/hsv2rgb.cpp#L236
    h = CalcUtils.scale8(h, 191)
    hsv2rgb_raw(%{hsv | h: h}, extra_color_correction)
  end

  # MARK: private utility functions
  @hsv_section_3 0x40
  @spec hsv2rgb_raw(Types.hsv(), any) :: Types.rgb()
  defp hsv2rgb_raw(%HSV{h: h, s: s, v: v}, _extra_color_correction) do
    # based on: https://github.com/FastLED/FastLED/blob/95d0a5582b2052729f345719e65edf7a4b9e7098/src/hsv2rgb.cpp#L51
    invsat = 255 - s
    brightness_floor = trunc(v * invsat / 256)

    color_amplitude = v - brightness_floor

    section = trunc(h / @hsv_section_3)
    offset = rem(h, @hsv_section_3)

    rampup = offset
    rampdown = @hsv_section_3 - 1 - offset

    rampup_amp_adj = trunc(rampup * color_amplitude / (256 / 4))
    rampdown_amp_adj = trunc(rampdown * color_amplitude / (256 / 4))

    rampup_adj_with_floor = rampup_amp_adj + brightness_floor
    rampdown_adj_with_floor = rampdown_amp_adj + brightness_floor

    set_colors(section, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor)
  end

  @spec set_colors(byte, byte, byte, byte) :: Types.rgb()
  def set_colors(section, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor)

  def set_colors(0, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {rampdown_adj_with_floor, rampup_adj_with_floor, brightness_floor}
  end

  def set_colors(1, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {brightness_floor, rampdown_adj_with_floor, rampup_adj_with_floor}
  end

  def set_colors(_na, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {rampup_adj_with_floor, brightness_floor, rampdown_adj_with_floor}
  end
end
