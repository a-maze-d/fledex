# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Functions do
  import Bitwise

  alias Fledex.Color.Conversion
  alias Fledex.Color.Correction
  alias Fledex.Color.Types

  @spec step(boolean, byte) :: integer
  # Depending whether we want to reverse we move hue forward or backwards
  defp step(reversed, hue)
  defp step(false, hue), do: hue
  defp step(true, hue), do: -hue

  @spec create_rainbow_circular_hsv(pos_integer, byte, boolean) :: list(Types.hsv)
  def create_rainbow_circular_hsv(num_leds, initial_hue \\ 0, reversed \\ false)
  def create_rainbow_circular_hsv(0, _initial_hue, _reversed), do: []
  def create_rainbow_circular_hsv(num_leds, initial_hue, reversed) do
    hue_change = Kernel.trunc(65_535 / num_leds)
    for n <- 0..(num_leds - 1) do
      {(initial_hue + step(reversed, n * hue_change>>>8)) &&& 0xFF, 240, 255}
    end
  end

  @spec create_rainbow_circular_rgb(pos_integer, byte, boolean) :: list(Types.rgb)
  def create_rainbow_circular_rgb(num_leds, initial_hue \\ 0, reversed \\ false) do
    create_rainbow_circular_hsv(num_leds, initial_hue, reversed)
    |> hsv2rgb()
  end

  @spec create_gradient_rgb(pos_integer, Types.rgb, Types.rgb) :: list(Types.rgb)
  def create_gradient_rgb(num_leds, {sr, sg, sb} = _start_color, {er, eg, eb} = _end_color) when num_leds > 0 do
    rdist87 = (er - sr) <<< 7
    gdist87 = (eg - sg) <<< 7
    bdist87 = (eb - sb) <<< 7

    steps = num_leds + 1
    rdelta = (trunc(rdist87 / steps)) * 2
    gdelta = (trunc(gdist87 / steps)) * 2
    bdelta = (trunc(bdist87 / steps)) * 2

    r88 = sr <<< 8
    g88 = sg <<< 8
    b88 = sb <<< 8

    for n <- 1..steps - 1 do
      {(r88 + rdelta * n) >>> 8, (g88 + gdelta * n) >>> 8, (b88 + bdelta * n) >>> 8}
    end

  end

  @spec hsv2rgb(list(Types.hsv), (Types.hsv, (Types.rgb -> Types.rgb) -> Types.rgb), (Types.rgb -> Types.rgb)) :: list(Types.rgb)
  def hsv2rgb(leds,
              conversion_function \\ &Conversion.Rainbow.hsv2rgb/2,
              color_correction \\ &Correction.color_correction_none/1
              ) do
    Enum.map(leds, fn (hsv) ->
      conversion_function.(hsv, color_correction)
    end)
  end
end
