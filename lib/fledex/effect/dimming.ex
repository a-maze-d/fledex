# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Dimming do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Color.Utils

  @impl true
  @spec apply(
        leds :: list(Types.colorint()),
        count :: non_neg_integer,
        config :: keyword,
        triggers :: map
      ) ::
        {list(Types.colorint()), non_neg_integer, map}
  def apply(leds, 0, _config, triggers), do: {leds, 0, triggers}
  def apply(leds, count, config, triggers) do
    case enabled?(config) do
      true ->
        do_apply(leds, count, config, triggers)
      false ->
        {leds, count, config}
    end
  end

  def do_apply(leds, count, config, triggers) do
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

    {leds, count, triggers}
  end

  @impl true
  @spec enable(config :: keyword, enable :: boolean) :: keyword
  def enable(config, enable) do
    Keyword.put(config, :enabled, enable)
  end

  @impl true
  @spec enabled?(config :: keyword) :: boolean
  def enabled?(config) do
    Keyword.get(config, :enabled, true)
  end
end
