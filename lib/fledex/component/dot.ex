# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.Dot do
  @behaviour Fledex.Component.Interface

  @impl true
  def configure(name, options) when is_atom(name) and is_list(options) do
    use Fledex
    color = Keyword.fetch!(options, :color)
    count = Keyword.fetch!(options, :count)
    trigger_name = Keyword.fetch!(options, :trigger_name)
    zero_indexed = Keyword.get(options, :zero_indexed, true)

    animation name do
      %{^trigger_name => trigger} = triggers when is_integer(trigger) ->
        case triggers[trigger_name] + correct_index(zero_indexed) do
          trigger when is_integer(trigger) and trigger > 0 and trigger <= count ->
            leds(count) |> light(color, trigger)

          _trigger ->
            leds()
        end

      _triggers ->
        leds()
    end
  end

  defp correct_index(true), do: 1
  defp correct_index(false), do: 0
end
