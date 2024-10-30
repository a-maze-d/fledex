# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Offset do
  use Fledex.Effect.Interface

  def do_apply(leds, count, config, triggers, _context) do
    offset = config[:offset] || 1

    zeros = Enum.map(Enum.to_list(1..offset), fn _index -> 0 end)
    {zeros ++ leds, count + offset, triggers}
  end
end
