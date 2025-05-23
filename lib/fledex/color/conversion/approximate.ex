# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.Approximate do
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.Types
  # alias Fledex.Color.Utils

  @hue_red 0
  @hue_orange 32
  @hue_yellow 64
  @hue_green 96
  @hue_aqua 128
  @hue_blue 160
  @hue_purple 192
  @hue_pink 224

  @spec rgb2hsv(Types.rgb()) :: Types.hsv()
  def rgb2hsv({r, g, b}) do
    desat = find_desaturation({r, g, b})
    s = calc_saturation(desat)

    {r, g, b} = {r - desat, g - desat, b - desat}

    if r + g + b == 0 do
      {0, 0, 255 - s}
    else
      # for desaturation
      {r, g, b} = scale_to_compensate({r, g, b}, s)
      total = r + g + b
      # for small value
      {r, g, b} = scale_to_compensate({r, g, b}, total)
      v = calc_value(total, desat)
      h = calc_hue({r, g, b})
      {h, s, v}
    end
  end

  defp calc_saturation(desat) do
    s = 255 - desat

    if s != 255 do
      255 - trunc(:math.sqrt((255 - s) * 256))
    else
      s
    end
  end

  defp calc_value(total, desat) do
    if total > 255 do
      255
    else
      v = qadd8(desat, total)
      if v != 255, do: trunc(:math.sqrt(v * 256)), else: v
    end
  end

  defp calc_hue({r, 0, _b}, r) do
    # pink-red-range
    (@hue_purple + @hue_pink) / 2 + CalcUtils.scale8(qsub8(r, 128), CalcUtils.frac_48_128())
  end

  defp calc_hue({r, g, _b}, r) when r - g > g do
    # red-orange-range
    @hue_red + CalcUtils.scale8(g, CalcUtils.frac_32_85())
  end

  defp calc_hue({r, g, _b}, r) do
    # orange-yellow-range
    @hue_orange + CalcUtils.scale8(qsub8(g - 85 + (171 - r), 4), CalcUtils.frac_32_85())
  end

  defp calc_hue({r, g, 0}, g) do
    # yellow-green-range
    @hue_yellow + (CalcUtils.scale8(qsub8(171, r), 47) + CalcUtils.scale8(qsub8(g, 171), 96)) / 2
  end

  defp calc_hue({_r, g, b}, g) when g - b > b do
    # green-aqua-range
    @hue_green + CalcUtils.scale8(b, CalcUtils.frac_32_85())
  end

  defp calc_hue({_r, g, b}, g) do
    # aqua-aquablue-range?
    @hue_aqua + CalcUtils.scale8(qsub8(b, 85), CalcUtils.frac_8_42())
  end

  defp calc_hue({0, _g, b}, b) do
    # aquablue-blue-range
    @hue_aqua + (@hue_blue - @hue_aqua) / 4 +
      CalcUtils.scale8(qsub8(b, 128), CalcUtils.frac_24_128())
  end

  defp calc_hue({r, _g, b}, b) when b - r > r do
    # blue-purple-range
    @hue_blue + CalcUtils.scale8(r, CalcUtils.frac_32_85())
  end

  defp calc_hue({r, _g, b}, b) do
    # purple-pink-range
    @hue_purple + CalcUtils.scale8(qsub8(r, 85), CalcUtils.frac_32_85())
  end

  defp calc_hue({r, g, b} = rgb) do
    rem(trunc(calc_hue(rgb, Enum.max([r, g, b]))) + 1, 256)
  end

  @spec scale_to_compensate(Types.rgb(), byte) :: Types.rgb()
  defp scale_to_compensate({r, g, b}, s) when s < 255 do
    s = if s == 0, do: 1, else: s
    scaleup = 65_535 / s
    r = trunc(r * scaleup / 256)
    g = trunc(g * scaleup / 256)
    b = trunc(b * scaleup / 256)
    {r, g, b}
  end

  defp scale_to_compensate({r, g, b}, _s), do: {r, g, b}

  @spec find_desaturation(Types.rgb()) :: byte
  defp find_desaturation({r, g, b}) do
    255
    |> adj_desat(r)
    |> adj_desat(g)
    |> adj_desat(b)
  end

  @spec adj_desat(byte, byte) :: byte
  defp adj_desat(desat, value)
  defp adj_desat(desat, value) when value < desat, do: value
  defp adj_desat(desat, _value), do: desat

  @spec qadd8(byte, byte) :: byte
  defp qadd8(i, j) when i + j > 255, do: 255

  defp qadd8(i, j) do
    i + j
  end

  @spec qsub8(byte, byte) :: byte
  defp qsub8(i, j) when i - j < 0, do: 0

  defp qsub8(i, j) do
    i - j
  end
end
