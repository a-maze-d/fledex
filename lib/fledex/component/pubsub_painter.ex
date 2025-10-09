# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.PubSubPainter do
  @behaviour Fledex.Component.Interface

  @impl true
  def configure(name, options) do
    trigger_name = Keyword.get(options, :trigger_name, :pixel_data)

    import Fledex
    import Fledex.Leds

    animation name do
      %{^trigger_name => {_leds, count}} = triggers when is_integer(count) ->
        {leds, counter} = triggers[trigger_name]
        leds(counter, leds, %{})

      _triggers ->
        leds()
    end
  end
end
