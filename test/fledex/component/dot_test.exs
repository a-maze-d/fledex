# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.DotTest do
  use ExUnit.Case
  alias Fledex.Component.Dot
  alias Fledex.Leds

  describe "test component dot" do
    test "default creation" do
      config = Fledex.component(:name, Dot, color: :green, count: 3, trigger_name: :trigger)

      assert %{
               name: %{
                 def_func: _whatever,
                 effects: [],
                 options: [],
                 type: :animation
               }
             } = config
    end

    test "function with wrong trigger" do
      config = Fledex.component(:name, Dot, color: :green, count: 3, trigger_name: :trigger)

      assert config.name.def_func.(%{wrong_trigger: 10}) == Leds.leds()
      assert config.name.def_func.(%{trigger: -10}) == Leds.leds()
      assert config.name.def_func.(%{trigger: 10}) == Leds.leds()
      assert config.name.def_func.(%{trigger: "text"}) == Leds.leds()
    end

    test "function with correct trigger" do
      config = Fledex.component(:name, Dot, color: 0xFF0000, count: 3, trigger_name: :trigger)

      leds = config.name.def_func.(%{trigger: 0})
      assert leds.count == 3
      assert Leds.to_list(leds) == [0xFF0000, 0x000000, 0x000000]

      leds = config.name.def_func.(%{trigger: 1})
      assert leds.count == 3
      assert Leds.to_list(leds) == [0x000000, 0xFF0000, 0x000000]

      leds = config.name.def_func.(%{trigger: 2})
      assert leds.count == 3
      assert Leds.to_list(leds) == [0x000000, 0x000000, 0xFF0000]
    end

    test "settings" do
      config =
        Fledex.component(
          :name,
          Dot,
          color: 0xFF0000,
          count: 3,
          trigger_name: :trigger,
          zero_indexed: false
        )

      leds = config.name.def_func.(%{trigger: 1})
      assert leds.count == 3
      assert Leds.to_list(leds) == [0xFF0000, 0x000000, 0x000000]
    end
  end
end
