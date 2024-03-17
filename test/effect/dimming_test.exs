# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.DimmingTest do
  use ExUnit.Case

  alias Fledex.Effect.Dimming

  describe "rotation" do
    test "simple (default trigger name)" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 128}

      returned_leds = Dimming.apply(leds, 3, [], triggers)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], triggers, :progress}
    end
    test "with trigger name" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{counter: 128}

      returned_leds = Dimming.apply(leds, 3, [trigger_name: :counter], triggers)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], triggers, :progress}
    end
    test "with divisor" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 256}

      returned_leds = Dimming.apply(leds, 3, [divisor: 2], triggers)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], triggers, :progress}

      triggers = %{default: 257}
      returned_leds = Dimming.apply(leds, 3, [divisor: 2], triggers)

      assert returned_leds == {[0x7E0000, 0x007E00, 0x00007E], triggers, :progress}

      triggers = %{default: 258}
      returned_leds = Dimming.apply(leds, 3, [divisor: 2], triggers)

      assert returned_leds != [0x7E0000, 0x007E00, 0x00007E]
    end
  end
end
