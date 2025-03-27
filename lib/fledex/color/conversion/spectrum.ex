# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.Spectrum do
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.Conversion.Raw
  alias Fledex.Color.Types

  @spec hsv2rgb(Types.hsv(), (Types.rgb() -> Types.rgb())) :: Types.rgb()
  def hsv2rgb({h, s, v}, extra_color_correction) do
    #     CHSV hsv2(hsv);
    # hsv2.hue = scale8( hsv2.hue, 191);
    # hsv2rgb_raw(hsv2, rgb);
    h = CalcUtils.scale8(h, 191)
    Raw.hsv2rgb({h, s, v}, extra_color_correction)
  end
end
