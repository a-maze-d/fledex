# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Wanish do
  use Fledex.Effect.Interface

  # This function is a bit complicated. It calculates how many pixels should be switched off or not
  # It starts with just getting the appropriate counter, rescaling it and circuling between to the number
  # of leds. If we also want to reappear, it gets a bit complicated. The following table should help to
  # understand the algorithm illustrating the case of 3 (=count) leds (* = led on, o = led off).
  # Note: The actual direction is not determined here.
  # counter | leds  | counter%count | offset        | direction
  # -------------------------------------------------------------
  #   0     | ***   | 0             | 0             | ->
  #   1     | o**   | 1             | 1             | ->
  #   2     | oo*   | 2             | 2             | ->
  #   3     | ooo   | 0             | 3 / count - 0 | <- / ->
  #   4     | oo*   | 1             | 2 / count - 1 | <-
  #   5     | o**   | 2             | 1 / count - 2 | <-
  #   6     | ***   | 0             | 0 / count - 3 | -> / <-
  #   7     | o**   | 1             | 1             | ->
  # ...
  # As can be seen we have two cycles. We can decide on when we indicate the change. We change it
  # when our offset is 2 (because with an offset of 3 the direction doesn't matter but it's
  # nice to be aligned with the modulo).
  # We change back the direction when our offset is at 1 (here again, the direction doesn't matter
  # in the next round, to align it to the modulo). This becomes a bit more complicated if we have
  # a divisor, since the same state appears twice. Therefore we take the remainder of the divisor
  # into consideration  defp do_apply(leds, _count, _config, nil, triggers, _context), do: {leds, triggers}
  def do_apply(leds, count, config, triggers, _context) do
    trigger_name = Keyword.get(config, :trigger_name)
    left = Keyword.get(config, :direction, :left) != :right
    reappear = Keyword.get(config, :reappear, false)
    # reappear does not make sense without circulate
    circulate = Keyword.get(config, :circulate, reappear)
    reappear_key = Keyword.get(config, :reappear_key, String.to_atom("#{trigger_name}_reappear"))

    divisor = Keyword.get(config, :divisor, 1)
    offset = triggers[trigger_name] || 0
    remainder = divisor - (rem(offset, divisor) + 1)

    offset = trunc(offset / divisor)

    switch_on_off_func =
      Keyword.get(config, :switch_on_off_func, fn offset, triggers ->
        {:run, offset, triggers}
      end)

    {task, offset, triggers} = switch_on_off_func.(offset, triggers)

    if task == :run do
      offset = calculate_offset(count, offset, circulate, reappear, reappear_key, triggers)
      triggers = adjust_triggers(count, remainder, offset, reappear_key, triggers)
      {switch_off(leds, offset, left), count, triggers}
    else
      {leds, count, triggers}
    end
  end

  defp calculate_offset(count, offset, circulate, reappear, reappear_key, triggers) do
    offset = if circulate, do: rem(offset, count), else: offset
    offset = if reappear and triggers[reappear_key], do: count - offset, else: offset
    offset
  end

  defp adjust_triggers(count, remainder, offset, reappear_key, triggers)

  defp adjust_triggers(count, 0, offset, reappear_key, triggers) when offset == count - 1 do
    Map.put(triggers, reappear_key, true)
  end

  defp adjust_triggers(_count, 0, 1, reappear_key, triggers)
       when is_map_key(triggers, reappear_key) do
    Map.drop(triggers, [reappear_key])
  end

  defp adjust_triggers(_count, _remainder, _offset, _reappear_key, triggers) do
    triggers
  end

  defp switch_off(leds, amount, left) do
    leds
    |> reverse_if_necessary(left)
    |> Enum.with_index(0)
    |> Enum.map(fn {led, index} ->
      if index < amount, do: 0x000000, else: led
    end)
    |> reverse_if_necessary(left)
  end

  defp reverse_if_necessary(leds, left)
  defp reverse_if_necessary(leds, true), do: leds
  defp reverse_if_necessary(leds, false), do: Enum.reverse(leds)
end
