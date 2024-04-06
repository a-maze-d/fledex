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

    animation name do
      triggers when is_map(triggers) and is_map_key(triggers, trigger_name) ->
        leds(count) |> light(color, triggers[trigger_name])

      _triggers ->
        leds()
    end
  end
end
