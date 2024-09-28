# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.WanishTest do
  use ExUnit.Case

  alias Fledex.Effect.Wanish

  describe "wanish effect" do
    test "without trigger name" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{counter: 1}

      {returned_leds, 3, _triggers} = Wanish.apply(leds, 3, [], triggers)

      assert returned_leds == [0xFF0000, 0x00FF00, 0x0000FF]
    end

    test "with trigger name" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{counter: 1}

      {returned_leds, 3, _triggers} =
        Wanish.apply(leds, 3, [trigger_name: :counter], triggers)

      assert returned_leds == [0x000000, 0x00FF00, 0x0000FF]
    end

    test "with right direction" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      {returned_leds, 3, _triggers} =
        Wanish.apply(leds, 3, [trigger_name: :default, direction: :right], triggers)

      assert returned_leds == [0xFF0000, 0x00FF00, 0x000000]
    end

    test "with divisor" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      triggers = %{default: 1}

      {returned_leds, 3, _triggers} =
        Wanish.apply(leds, 3, [trigger_name: :default, divisor: 2], triggers)

      assert returned_leds == [0xFF0000, 0x00FF00, 0x0000FF]

      triggers = %{default: 2}

      {returned_leds, 3, _triggers} =
        Wanish.apply(leds, 3, [trigger_name: :default, divisor: 2], triggers)

      assert returned_leds == [0x000000, 0x00FF00, 0x0000FF]
    end

    test "with reappear" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      reappear_key = :dummy
      config = [trigger_name: :default, reappear: true, reappear_key: reappear_key]

      expected_results = [
        {[0x000000, 0x00FF00, 0x0000FF], nil},
        {[0x000000, 0x000000, 0x0000FF], true},
        {[0x000000, 0x000000, 0x000000], true},
        {[0x000000, 0x000000, 0x0000FF], true},
        {[0x000000, 0x00FF00, 0x0000FF], nil},
        {[0xFF0000, 0x00FF00, 0x0000FF], nil},
        {[0x000000, 0x00FF00, 0x0000FF], nil}
      ]

      Enum.reduce(expected_results, %{}, fn {expected_result, expected_reappear_key}, triggers ->
        triggers = Map.update(triggers, :default, 1, fn value -> value + 1 end)
        {returned_leds, 3, triggers} = Wanish.apply(leds, 3, config, triggers)
        assert returned_leds == expected_result
        assert triggers[reappear_key] == expected_reappear_key
        triggers
      end)
    end

    test "with reappear and divisor" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      reappear_key = :dummy
      config = [trigger_name: :default, divisor: 2, reappear: true, reappear_key: reappear_key]

      expected_results = [
        [0xFF0000, 0x00FF00, 0x00FF],
        [0x000000, 0x00FF00, 0x00FF],
        [0x000000, 0x00FF00, 0x00FF],
        [0x000000, 0x000000, 0x00FF],
        [0x000000, 0x000000, 0x00FF],
        [0x000000, 0x000000, 0x0000],
        [0x000000, 0x000000, 0x0000],
        [0x000000, 0x000000, 0x00FF],
        [0x000000, 0x000000, 0x00FF],
        [0x000000, 0x00FF00, 0x00FF],
        [0x000000, 0x00FF00, 0x00FF],
        [0xFF0000, 0x00FF00, 0x00FF],
        [0xFF0000, 0x00FF00, 0x00FF],
        [0x000000, 0x00FF00, 0x00FF]
      ]

      Enum.reduce(expected_results, %{}, fn expected_result, triggers ->
        triggers = Map.update(triggers, :default, 1, fn value -> value + 1 end)
        {returned_leds, 3, triggers} = Wanish.apply(leds, 3, config, triggers)
        assert returned_leds == expected_result
        triggers
      end)
    end

    test "don't run" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]

      config = [
        trigger_name: :default,
        divisor: 2,
        reappear: true,
        reappear_key: :dummy,
        switch_on_off_func: fn offset, triggers ->
          {:stop, offset, triggers}
        end
      ]

      {returned_leds, 3, triggers} = Wanish.apply(leds, 3, config, %{})
      assert returned_leds == leds
      assert triggers == %{}
    end
  end
end
