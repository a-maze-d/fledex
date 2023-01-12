defmodule Fledex.Lib8tion.Scale8 do
  import Bitwise

  def scale8(value, scale) do
    (value * scale) >>> 8
  end
  def scale8_video(value, scale) do
    # uint8_t j = (((int)i * (int)scale) >> 8) + ((i&&scale)?1:0);
    # // uint8_t nonzeroscale = (scale != 0) ? 1 : 0;
    # // uint8_t j = (i == 0) ? 0 : (((int)i * (int)(scale) ) >> 8) + nonzeroscale;
    # return j;
    (value*scale) >>> 8 + if (value != 0 && scale != 0), do: 1, else: 0
  end
end
