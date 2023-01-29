defmodule Fledex.Color.Utils do
  import Bitwise

  def scale8(value, scale) do
    (value * scale) >>> 8
  end
  def scale8_video(value, scale) do
    (value*scale) >>> 8 + if (value != 0 && scale != 0), do: 1, else: 0
  end
end
