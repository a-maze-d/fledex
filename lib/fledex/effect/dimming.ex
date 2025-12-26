# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Dimming do
  @moduledoc """
  This is an effect that will dim all the leds.

  This is a dynamic effect, because the dimming is connected to a trigger and hence the dimming will happen gradually.

  ## Options
  * `:trigger_name`: The name of the trigger to which the dimming effect will be attached to.
  * `:divisor`: The divisor allows to speed up (or slow down) the dimming effect. See also `Fledex.Effect.Rotation`.

  ## Future option ideas:
  * `:direction`: Allow the dimming effect to not only go from bright to dim (`:dim`, the default), but also the other direcion (`:bright`)
  * `:max_val`: limits the maximum amount of brightnss allowed
  * `:min_val`: limits the minimum amount of dimness allowed
  * `:cycle`: cycle between bright --> dim and back.
  """

  use Fledex.Effect.Interface

  alias Fledex.Color
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.RGB
  alias Fledex.Color.Types

  @doc false
  @spec do_apply(
          [Types.colorint()],
          non_neg_integer(),
          config :: keyword(),
          triggers :: map(),
          context :: map()
        ) :: {[Types.colorint()], non_neg_integer(), map()}
  def do_apply(leds, count, config, triggers, _context) do
    trigger_name = config[:trigger_name] || :default
    divisor = config[:divisor] || 1
    step = triggers[trigger_name] || 0
    step = trunc(step / divisor)
    step = rem(step, 255)

    leds =
      Enum.map(leds, fn led ->
        led
        |> RGB.to_tuple()
        |> CalcUtils.nscale8(255 - step, false)
        |> Color.to_colorint()
      end)

    {leds, count, triggers}
  end
end
