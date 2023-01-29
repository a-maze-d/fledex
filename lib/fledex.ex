defmodule Fledex do
  import Bitwise
  alias Fledex.Pixeltypes.Hsv
  alias Fledex.Pixeltypes.Rgb
  alias Fledex.Lib8tion.Scale8

def default_operator(hue) do
  hue
end

  def create_rainbow_circular(num_leds, initialHue \\ 0, op \\ &default_operator/1)
  def create_rainbow_circular(0, _, _), do: []
  def create_rainbow_circular(num_leds, initialHue, op) do
    hueChange = Kernel.trunc(65535 / num_leds)
    # hueOffset = 0
  #   void fill_rainbow_circular(struct CHSV* targetArray, int numToFill, uint8_t initialhue, bool reversed)
  # {
  #     if (numToFill == 0) return;  // avoiding div/0

  #     CHSV hsv;
  #     hsv.hue = initialhue;
  #     hsv.val = 255;
  #     hsv.sat = 240;

  #     const uint16_t hueChange = 65535 / (uint16_t) numToFill;  // hue change for each LED, * 256 for precision (256 * 256 - 1)
  #     uint16_t hueOffset = 0;  // offset for hue value, with precision (*256)


    for n <- 0..(num_leds-1) do
      %Hsv{h: (initialHue + op.(n*hueChange>>>8)) &&& 0xFF, s: 240, v: 255}
    end
  #     for (int i = 0; i < numToFill; ++i) {
  #         targetArray[i] = hsv;
  #         if (reversed) hueOffset -= hueChange;
  #         else hueOffset += hueChange;
  #         hsv.hue = initialhue + (uint8_t)(hueOffset >> 8);  // assign new hue with precise offset (as 8-bit)
  #     }
  # }
  end

  def convert_to_rgb(leds) do
    Enum.map(leds, fn (hsv) ->
        Hsv.to_rgb(hsv)
    end)
  end

  def apply_correction(leds, {sr, sg, sb} = _scale) do
    Enum.map(leds, fn (rgb) ->
        %Rgb{
          r: Scale8.scale8(rgb.r, sr),
          g: Scale8.scale8(rgb.g, sg),
          b: Scale8.scale8(rgb.b, sb)
          }
    end)
  end
end
