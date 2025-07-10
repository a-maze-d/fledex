# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Rotation do
  use Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Utils.PubSub

  def do_apply(leds, count, config, triggers, context) do
    left = Keyword.get(config, :direction, :left) != :right
    publish = Keyword.get(config, :publish, true)
    trigger_name = Keyword.get(config, :trigger_name, :default)
    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    stretch = Keyword.get(config, :stretch, 0)
    {leds, count} = stretch({leds, count}, stretch)
    offset = trunc(offset / divisor)
    remainder = rem(offset, count)
    _ignore = if publish and remainder == 0, do: PubSub.broadcast_state(:stop_start, context)
    {rotate(leds, count, remainder, left), count, triggers}
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
