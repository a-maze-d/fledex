defmodule Fledex.Color.Conversion.Spectrum do
  use Fledex.Color.Types

  alias Fledex.Color.Conversion.Raw
  alias Fledex.Color.Utils

  @spec hsv2rgb(hsv, (rgb -> rgb)) :: rgb
  def hsv2rgb({h, s, v}, extra_color_correction) do
    #     CHSV hsv2(hsv);
    # hsv2.hue = scale8( hsv2.hue, 191);
    # hsv2rgb_raw(hsv2, rgb);
    h = Utils.scale8(h, 191)
    Raw.hsv2rgb({h, s, v}, extra_color_correction)
  end
end
