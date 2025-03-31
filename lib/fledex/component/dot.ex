# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.Dot do
  @behaviour Fledex.Component.Interface
  import Fledex.Utils.Guards

  @impl true
  def configure(name, options) when is_atom(name) and is_list(options) do
    use Fledex
    color = Keyword.fetch!(options, :color)
    count = Keyword.fetch!(options, :count)
    trigger_name = Keyword.fetch!(options, :trigger_name)
    zero_indexed = Keyword.get(options, :zero_indexed, true)

    animation name do
      triggers when is_map(triggers) and is_map_key(triggers, trigger_name) ->
        trigger = triggers[trigger_name]

        case trigger do
          trigger when is_in_range(trigger, zero_indexed, 0, count) ->
            leds(count) |> light(color, offset: trigger + correct_index(zero_indexed))

          _triggers ->
            leds()
        end

      _triggers ->
        leds()
    end
  end

  defp correct_index(true), do: 1
  defp correct_index(false), do: 0
end
