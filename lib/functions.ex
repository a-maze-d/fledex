defmodule Fledex.Functions do
  import Bitwise
  alias Fledex.Color.Utils

  def default_operator(hue) do
    hue
  end

  def create_rainbow_circular_hsv(num_leds, initialHue \\ 0, op \\ &default_operator/1)
  def create_rainbow_circular_hsv(0, _, _), do: []
  def create_rainbow_circular_hsv(num_leds, initialHue, op) do
    hueChange = Kernel.trunc(65535 / num_leds)
    for n <- 0..(num_leds-1) do
      {(initialHue + op.(n*hueChange>>>8)) &&& 0xFF, 240, 255}
    end
  end

  def hsv2rgb(leds,
              conversion_function \\ &Fledex.Conversion.Rainbow.hsv2rgb/2,
              color_correction \\ &Fledex.Color.Correction.color_correction_none/1
              ) do
    Enum.map(leds, fn (hsv) ->
      conversion_function.(hsv, color_correction)
    end)
  end

  def apply_rgb_correction(leds, {sr, sg, sb} = _scale) do
    Enum.map(leds, fn ({r, g, b}) -> {
          Utils.scale8(r, sr),
          Utils.scale8(g, sg),
          Utils.scale8(b, sb)
        }
    end)
  end
end
