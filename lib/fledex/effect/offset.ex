# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Offset do
  @moduledoc """
  An effect that will offset the colors
  """
  use Fledex.Effect.Interface

  alias Fledex.Color.Types

  @spec do_apply(
          [Types.colorint()],
          non_neg_integer(),
          config :: keyword(),
          triggers :: map(),
          context :: map()
        ) :: {[Types.colorint()], non_neg_integer(), map()}
  def do_apply(leds, count, config, triggers, _context) do
    offset = config[:offset] || 1

    zeros = Enum.map(1..offset//1, fn _index -> 0 end)
    {zeros ++ leds, count + offset, triggers}
  end
end
