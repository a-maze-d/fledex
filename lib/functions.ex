defmodule Fledex.Functions do
  import Bitwise

  # The operator is there to distinguish between two modes
  #         if (reversed) hueOffset -= hueChange; <-- this is the defaeult operator
  #         else hueOffset += hueChange;

  defp step(false, hue), do: hue
  defp step(true, hue), do: -hue


  def create_rainbow_circular_hsv(num_leds, initialHue \\ 0, reversed \\ false)
  def create_rainbow_circular_hsv(0, _, _), do: []
  def create_rainbow_circular_hsv(num_leds, initialHue, reversed) do
    hueChange = Kernel.trunc(65535 / num_leds)
    for n <- 0..(num_leds-1) do
      {(initialHue + step(reversed, n*hueChange>>>8)) &&& 0xFF, 240, 255}
    end
  end

  def create_rainbow_circular_rgb(num_leds, initialHue \\ 0, reversed \\ false) do
    create_rainbow_circular_hsv(num_leds, initialHue, reversed)
    |> hsv2rgb()
  end
  def create_gradient_rgb(num_leds, {sr, sg, sb} = _start_color, {er, eg, eb} = _end_color) when num_leds > 0 do
    rdist87 = (er-sr) <<< 7
    gdist87 = (eg-sg) <<< 7
    bdist87 = (eb-sb) <<< 7

    steps = num_leds+1
    rdelta = (trunc(rdist87 / steps))*2
    gdelta = (trunc(gdist87 / steps))*2
    bdelta = (trunc(bdist87 / steps))*2

    r88 = sr <<< 8
    g88 = sg <<< 8
    b88 = sb <<< 8

    for n <- 1..steps-1 do
      {(r88 + rdelta*n) >>> 8, (g88 + gdelta*n) >>> 8, (b88 + bdelta*n) >>> 8}
    end

  end
  def hsv2rgb(leds,
              conversion_function \\ &Fledex.Color.Conversion.Rainbow.hsv2rgb/2,
              color_correction \\ &Fledex.Color.Correction.color_correction_none/1
              ) do
    Enum.map(leds, fn (hsv) ->
      conversion_function.(hsv, color_correction)
    end)
  end
end
