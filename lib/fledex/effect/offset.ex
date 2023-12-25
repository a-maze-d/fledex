defmodule Fledex.Effect.Offset do
  @behaviour Fledex.Effect.Interface

  @impl true
  def apply(leds, _count, config, _triggers) do
    offset = config[:offset] || 1

    zeros = Enum.map(Enum.to_list(1..offset), fn _index -> 0 end)
    zeros ++ leds
  end
end
