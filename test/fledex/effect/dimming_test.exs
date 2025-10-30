# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.DimmingTest do
  use ExUnit.Case, async: false

  alias Fledex.Effect.Dimming
  @context %{strip_name: :strip_name, animation_name: :animation_name, effect: 1}
  describe "rotation" do
    test "simple (default trigger name)" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 128}

      returned_leds = Dimming.apply(leds, 3, [], triggers, @context)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], 3, triggers}
    end

    test "with trigger name" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{counter: 128}

      returned_leds = Dimming.apply(leds, 3, [trigger_name: :counter], triggers, @context)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], 3, triggers}
    end

    test "with divisor" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 256}

      returned_leds = Dimming.apply(leds, 3, [divisor: 2], triggers, @context)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], 3, triggers}

      triggers = %{default: 257}
      returned_leds = Dimming.apply(leds, 3, [divisor: 2], triggers, @context)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], 3, triggers}

      triggers = %{default: 258}
      {leds, _count, _triggers} = Dimming.apply(leds, 3, [divisor: 2], triggers, @context)

      assert [0x7E0000, 0x007E00, 0x00007E] != leds
    end
  end
end
