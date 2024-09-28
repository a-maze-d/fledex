# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Rotation do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Effect.Interface

  @impl true
  @spec apply(
        leds :: list(Types.colorint()),
        count :: non_neg_integer,
        config :: keyword,
        triggers :: map
      ) ::
        {list(Types.colorint()), non_neg_integer, map, Interface.effect_state_t()}
  def apply(leds, 0, _config, triggers), do: {leds, 0, triggers, :stop}
  def apply(leds, count, config, triggers) do
    case enabled?(config) do
      true ->
        do_apply(leds, count, config, triggers)
      false ->
        {leds, count, config, :static}
    end
  end

  defp do_apply(leds, count, config, triggers) do
    left = Keyword.get(config, :direction, :left) != :right
    trigger_name = Keyword.get(config, :trigger_name, :default)
    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    stretch = Keyword.get(config, :stretch, 0)
    {leds, count} = stretch({leds, count}, stretch)
    offset = trunc(offset / divisor)
    remainder = rem(offset, count)
    effect_state = if offset == 0 and remainder == 0, do: :stop_start, else: :progress
    {rotate(leds, count, remainder, left), count, triggers, effect_state}
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

  @doc """
  Helper function mainy intended for internal use to rotate the sequence of values by an `offset`.

  The rotation can happen with the offset to the left or to the right.
  """
  @spec rotate(list(Types.colorint()), non_neg_integer, pos_integer, boolean) ::
          list(Types.colorint())
  def rotate(vals, _count, 0, _rotate_left), do: vals

  def rotate(vals, count, offset, rotate_left) do
    offset = if rotate_left, do: offset, else: count - offset
    Enum.slide(vals, 0..rem(offset - 1 + count, count), count)
  end

  # stretch the number of led_count to be the same as stretch
  # we ignore the stretching if a too small number is specified
  # (we don't support shrinking, i.e. negative stretching)
  def stretch({leds, led_count}, stretch)
      when stretch == led_count or
             stretch < led_count do
    {leds, led_count}
  end

  def stretch({leds, led_count}, stretch) when stretch > led_count do
    missing = stretch - led_count
    missng_leds = Enum.map(1..missing, fn _index -> 0x000000 end)
    {leds ++ missng_leds, stretch}
  end
end
