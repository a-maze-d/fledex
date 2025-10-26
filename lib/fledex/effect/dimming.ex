# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Dimming do
  use Fledex.Effect.Interface

  alias Fledex.Color
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.RGB

  def do_apply(leds, count, config, triggers, _context) do
    trigger_name = config[:trigger_name] || :default
    divisor = config[:divisor] || 1
    step = triggers[trigger_name] || 0
    step = trunc(step / divisor)
    step = rem(step, 255)

    leds =
      Enum.map(leds, fn led ->
        led
        |> RGB.new()
        |> RGB.to_tuple()
        |> CalcUtils.nscale8(255 - step, false)
        |> Color.to_colorint()
      end)

    {leds, count, triggers}
  end
end
