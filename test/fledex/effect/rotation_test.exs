# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.RotationTest do
  use ExUnit.Case

  alias Fledex.Effect.Rotation

  describe "rotation" do
    test "simple (default trigger name)" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [], triggers)

      assert returned_leds == {[0x00ff00, 0x0000ff, 0xff0000], triggers, :progress}
    end
    test "with trigger name" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{counter: 1}

      returned_leds = Rotation.apply(leds, 3, [trigger_name: :counter], triggers)

      assert returned_leds == {[0x00ff00, 0x0000ff, 0xff0000], triggers, :progress}
    end
    test "with right direction" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [direction: :right], triggers)

      assert returned_leds == {[0x0000ff, 0xff0000, 0x00ff00], triggers, :progress}
    end
    test "with divisor" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [divisor: 2], triggers)

      assert returned_leds == {[0xff0000, 0x00ff00, 0x0000ff], triggers, :stop_start}

      triggers = %{default: 2}
      returned_leds = Rotation.apply(leds, 3, [divisor: 2], triggers)

      assert returned_leds == {[0x00ff00, 0x0000ff, 0xff0000], triggers, :progress}
    end
  end
end
