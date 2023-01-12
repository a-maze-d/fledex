defmodule Leds do
  defstruct count: 0, leds: %{}

  @doc """
  :offset is 1 indexed. Offset needs to be >0 if it's bigger than the :count then the led will be istored, but gnored
  """
  def update(leds, led, offset) when offset > 0 do
    do_update(leds,led,offset)
  end
  def update(_leds, _led, offset) do
    raise ArgumentError, message: "the offset needs to be > 0 (found: #{offset})"
  end
  # iex(61)> Enum.slide(vals, 0..rem(o-1 + Enum.count(vals),Enum.count(vals)), Enum.count(vals))
  # [1, 2, 3, 4, 5, 6, 7, 8, 9]
  defp do_update(%Leds{count: count, leds: leds}, rgb, offset) when is_integer(rgb) do
    %Leds{count: count, leds: Map.put(leds, offset, rgb)}
  end
  defp do_update(%Leds{count: count, leds: leds}, %Leds{leds: new_leds}, offset) do
    # remap the indicies (1 indexed)
    remapped_new_leds = Map.new(Enum.map(new_leds, fn {key, value} ->
      index = offset + key - 1
      {index, value}
    end))
    leds = Map.merge(leds, remapped_new_leds)
    %Leds{count: count, leds: leds}
  end
  defp do_update(_leds, _led, _offset) do
    raise ArgumentError, message: "unknown data "
  end
end
