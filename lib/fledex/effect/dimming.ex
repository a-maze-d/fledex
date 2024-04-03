# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Dimming do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Color.Utils
  alias Fledex.Effect.Interface

  @impl true
  @spec apply(
          leds :: list(Types.colorint()),
          count :: non_neg_integer,
          config :: keyword,
          triggers :: map
        ) ::
          {list(Types.colorint()), map, Interface.effect_state_t()}
  def apply(leds, _count, config, triggers) do
    trigger_name = config[:trigger_name] || :default
    divisor = config[:divisor] || 1
    step = triggers[trigger_name] || 0
    step = trunc(step / divisor)
    step = rem(step, 255)

    leds =
      Enum.map(leds, fn led ->
        led
        |> Utils.to_rgb()
        |> Utils.nscale8(255 - step, false)
        |> Utils.to_colorint()
      end)

    effect_state = if step == 0, do: :stop_start, else: :progress
    {leds, triggers, effect_state}
  end
end
