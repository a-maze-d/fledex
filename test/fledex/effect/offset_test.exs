# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.OffsetTest do
  use ExUnit.Case

  alias Fledex.Effect.Offset
  @context %{strip_name: :strip_name, animation_name: :animation_name, effect: 1}

  describe "0ffsetting" do
    test "simple" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      config = [offset: 3]
      triggers = %{john: 10}
      new_leds = Offset.apply(leds, 3, config, triggers, @context)

      assert new_leds ==
               {[0x000000, 0x000000, 0x000000, 0xFF0000, 0x00FF00, 0x0000FF], 6, triggers}
    end
  end
end
