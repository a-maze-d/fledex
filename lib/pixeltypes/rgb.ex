defmodule Fledex.Pixeltypes.Rgb do
  alias Fledex.Pixeltypes.Hsv

  defstruct r: 0, g: 0, b: 0

  def from_hsv(hsv) do
    Hsv.to_rgb(hsv)
  end
end
