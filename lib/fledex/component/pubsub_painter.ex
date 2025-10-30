# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.PubSubPainter do
  @moduledoc """
  This components receives some color information through PubSub and
  colors the leds accordingly.

  > #### Note {: .warning}
  >
  > This component is not fully working and therefore shouldn't be used yet.
  """
  @behaviour Fledex.Component.Interface

  alias Fledex.Component.Interface

  @impl Interface
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
