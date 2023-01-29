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

  def hsv2rgb(leds,
              conversion_function \\ &Fledex.Color.Conversion.Rainbow.hsv2rgb/2,
              color_correction \\ &Fledex.Color.Correction.color_correction_none/1
              ) do
    Enum.map(leds, fn (hsv) ->
      conversion_function.(hsv, color_correction)
    end)
  end
end
