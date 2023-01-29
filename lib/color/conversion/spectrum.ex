defmodule Fledex.Color.Conversion.Spectrum do
  alias Fledex.Utils
  alias Fledex.Color.Conversion.Raw

  def hsv2rgb({h, s, v}, extra_color_correction) do
    #     CHSV hsv2(hsv);
    # hsv2.hue = scale8( hsv2.hue, 191);
    # hsv2rgb_raw(hsv2, rgb);
    h = Utils.scale8(h, 191)
    Raw.hsv2rgb({h, s, v}, extra_color_correction)
  end
end
