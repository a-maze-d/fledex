# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.BellCurveTest do
  use ExUnit.Case, async: false

  alias Fledex.Effect.BellCurve
  @context %{strip_name: :strip_name, animation_name: :animation_name, effect: 1}
  @expected_leds [
    0x5A0000,
    0x5E0000,
    0x610000,
    0x630000,
    0x640000,
    0x640000,
    0x630000,
    0x610000,
    0x5E0000
  ]
  @leds [
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000,
    0xFF0000
  ]
  describe "bell curve" do
    test "correct filtering" do
      # We have 9 leds and those should be dimmed with the following values:
      # Fledex.Effect.BellCurve.calculate_window(9, [multiplier: 10]) |> Enum.sort
      # [
      #   {0, 91},
      #   {1, 95},
      #   {2, 98},
      #   {3, 100},
      #   {4, 101},
      #   {5, 101},
      #   {6, 100},
      #   {7, 98},
      #   {8, 95},
      #   {9, 91}
      # ]
      triggers = %{default: 128}
      result = BellCurve.do_apply(@leds, 9, [multiplier: 10], triggers, @context)

      assert result == {@expected_leds, 9, triggers}
    end

    test "caching test" do
      triggers = %{default: 128}
      assert !Map.has_key?(triggers, :bell_values)

      {_leds, _count, triggers} =
        BellCurve.do_apply(@leds, 9, [cache: true, multiplier: 10], triggers, @context)

      assert Map.has_key?(triggers, :bell_values)

      {_leds, _count, triggers} =
        BellCurve.do_apply(@leds, 9, [cache: false, multiplier: 10], triggers, @context)

      assert !Map.has_key?(triggers, :bell_values)
    end
  end
end
