# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.RotationTest do
  use ExUnit.Case

  alias Fledex.Effect.Rotation
  @context %{strip_name: :strip_name, animation_name: :animation_name, effect: 1}

  describe "rotation" do
    test "simple (default trigger name)" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [], triggers, @context)

      assert returned_leds == {[0x00FF00, 0x0000FF, 0xFF0000], 3, triggers}
    end

    test "with trigger name" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{counter: 1}

      returned_leds = Rotation.apply(leds, 3, [trigger_name: :counter], triggers, @context)

      assert returned_leds == {[0x00FF00, 0x0000FF, 0xFF0000], 3, triggers}
    end

    test "with right direction" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [direction: :right], triggers, @context)

      assert returned_leds == {[0x0000FF, 0xFF0000, 0x00FF00], 3, triggers}
    end

    test "with divisor" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 3, [divisor: 2, publish: false], triggers, @context)

      assert returned_leds == {[0xFF0000, 0x00FF00, 0x0000FF], 3, triggers}

      triggers = %{default: 2}
      returned_leds = Rotation.apply(leds, 3, [divisor: 2], triggers, @context)

      assert returned_leds == {[0x00FF00, 0x0000FF, 0xFF0000], 3, triggers}
    end

    test "with stretching" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      returned_leds =
        Rotation.apply(leds, 3, [divisor: 2, stretch: 6, publish: false], triggers, @context)

      assert returned_leds ==
               {[0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000], 6, triggers}
    end

    test "with zero length leds" do
      leds = []
      triggers = %{default: 1}

      returned_leds = Rotation.apply(leds, 0, [], triggers, @context)
      assert returned_leds == {[], 0, triggers}
    end
  end
end
