# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Offset do
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
  def apply(leds, count, config, triggers) do
    offset = config[:offset] || 1

    zeros = Enum.map(Enum.to_list(1..offset), fn _index -> 0 end)
    {zeros ++ leds, count + offset, triggers, :static}
  end
end
