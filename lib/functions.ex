defmodule Fledex.Functions do
  import Bitwise
  alias Fledex.Pixeltypes.Hsv
  alias Fledex.Lib8tion.Scale8

def default_operator(hue) do
  hue
end

  def create_rainbow_circular(num_leds, initialHue \\ 0, op \\ &default_operator/1)
  def create_rainbow_circular(0, _, _), do: []
  def create_rainbow_circular(num_leds, initialHue, op) do
    hueChange = Kernel.trunc(65535 / num_leds)
    for n <- 0..(num_leds-1) do
      %Hsv{h: (initialHue + op.(n*hueChange>>>8)) &&& 0xFF, s: 240, v: 255}
    end
  end

  def hsv2rgb(leds) do
    Enum.map(leds, fn (hsv) ->
        Hsv.to_rgb(hsv)
    end)
  end

  def apply_correction(leds, {sr, sg, sb} = _scale) do
    Enum.map(leds, fn ({r, g, b}) -> {
          Scale8.scale8(r, sr),
          Scale8.scale8(g, sg),
          Scale8.scale8(b, sb)
        }
    end)
  end
end
