defmodule Fledex.Effect.Dimming do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Utils

  @impl true
  def apply(leds, _count, config, triggers) do
    trigger_name = config[:trigger_name] || :default
    divisor = config[:divisor] || 1
    step = triggers[trigger_name] || 0
    step = rem(step, 255)
    step = trunc(step / divisor)

    Enum.map(leds, fn led ->
      led
        |> Utils.to_rgb()
        |> Utils.nscale8(255 - step, false)
        |> Utils.to_colorint()
    end)
  end
end
