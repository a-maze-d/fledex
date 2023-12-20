defmodule Fledex.Effect.Wanish do
  @behaviour Fledex.Effect.Interface

  @impl true
  def apply(leds, config, triggers) do
    trigger_name = Keyword.get(config, :trigger_name, :default)
    left = Keyword.get(config, :direction, :left) != :right

    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    offset = trunc(offset / divisor)

    switch_off(leds, offset, left)
  end

  defp switch_off(leds, amount, left) do
    count = length(leds)
    range = 0..(count - 1)
    range = if left, do: range, else: Enum.reverse(range)
    Enum.zip(range, leds)
      |> Enum.map(fn {index, led} ->
        if index < amount, do: 0x000000, else: led
    end)
  end
end
