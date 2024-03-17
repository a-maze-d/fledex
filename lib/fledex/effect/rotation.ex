# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Rotation do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Effect.Interface

  @impl true
  @spec apply(leds :: list(Types.colorint), count :: non_neg_integer, config :: keyword, triggers :: map)
      :: {list(Types.colorint), map, Interface.effect_state_t}
  def apply(leds, count, config, triggers) do
    left = Keyword.get(config, :direction, :left) != :right
    trigger_name = Keyword.get(config, :trigger_name, :default)
    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    offset = trunc(offset / divisor)
    remainder = rem(offset, count)
    effect_state = if offset == 0 and remainder == 0, do: :stop_start, else: :progress
    {rotate(leds, count, remainder, left), triggers, effect_state}
  end

  @doc """
  Helper function mainy intended for internal use to rotate the sequence of values by an `offset`.

  The rotation can happen with the offset to the left or to the right.
  """
  @spec rotate(list(Types.colorint), non_neg_integer, pos_integer, boolean) :: list(Types.colorint)
  def rotate(vals, _count, 0, _rotate_left), do: vals
  def rotate(vals, count, offset, rotate_left) do
    offset = if rotate_left, do: offset, else: count - offset
    Enum.slide(vals, 0..rem(offset - 1 + count, count), count)
  end
end
