defmodule Leds do

  @enforce_keys [:count, :leds, :opts]
  defstruct count: 0, leds: %{}, opts: nil, meta: %{index: 1} #, fill: :none
  def new() do
    new(0)
  end
  def new(count) do
    new(count, nil)
  end
  def new(count, opts) do
    new(count, %{}, opts)
  end
  def new(count, leds, opts) do
    new(count, leds, opts, %{index: 1})
  end
  def new(count, leds, opts, meta) do
    %Leds{count: count, leds: leds, opts: opts, meta: meta}
  end
  def light(leds, rgb) do
    do_update(leds, rgb)
  end
  def light(leds, led, offset) do
    do_update(leds, led, offset)
  end
  @doc """
  :offset is 1 indexed. Offset needs to be >0 if it's bigger than the :count
  then the led will be stored, but ignored
  """
  def update(leds, led) do
    do_update(leds, led)
  end
  def update(leds, led, offset) when offset > 0 do
    do_update(leds,led,offset)
  end
  def update(_leds, _led, offset) do
    raise ArgumentError, message: "the offset needs to be > 0 (found: #{offset})"
  end
  # iex(61)> Enum.slide(vals, 0..rem(o-1 + Enum.count(vals),Enum.count(vals)), Enum.count(vals))
  # [1, 2, 3, 4, 5, 6, 7, 8, 9]
  defp do_update(%Leds{meta: meta} = leds, rgb) when is_integer(rgb) do
    index = meta[:index]  || 1
    do_update(leds, rgb, index)
  end
  defp do_update(%Leds{count: count, leds: leds, opts: opts, meta: meta}, rgb, offset) when is_integer(rgb) do
    Leds.new(count, Map.put(leds, offset, rgb), opts, %{meta | index: offset+1})
  end
  defp do_update(%Leds{count: count1, leds: leds1, opts: opts1, meta: meta1}, %Leds{count: count2, leds: leds2}, offset) do
    # remap the indicies (1 indexed)
    remapped_new_leds = Map.new(Enum.map(leds2, fn {key, value} ->
      index = offset + key - 1
      {index, value}
    end))
    leds = Map.merge(leds1, remapped_new_leds)
    Leds.new(count1, leds, opts1, %{meta1 | index: offset+count2})
  end
  defp do_update(leds, led, offset) do
    raise ArgumentError, message: "unknown data #{inspect leds}, #{inspect led}, #{inspect offset}"
  end

  def to_binary(%Leds{count: count, leds: _leds, opts: _opts, meta: _meta}=leds) do
    Enum.reduce(1..count, <<>>, fn index, acc ->
      acc <> <<get_light(leds, index)>>
    end)
  end

  def to_list(%Leds{count: count, leds: _leds, opts: _opts, meta: _meta} = leds) do
    Enum.reduce(1..count, [], fn index, acc ->
      acc ++ [get_light(leds, index)]
    end)
  end

  def get_light(%Leds{leds: leds} = _leds, index) do
    case Map.fetch(leds, index) do
      {:ok, value} -> value
      _ -> 0
    end
  end

end
