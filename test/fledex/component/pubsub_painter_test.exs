# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.PubSubPainterTest do
  use ExUnit.Case

  alias Fledex.Component.PubSubPainter

  describe "painting test" do
    test "paint received data" do
      options = [
        trigger_name: :pixel_data
      ]

      config = PubSubPainter.configure(:john, options)

      leds = config.john.def_func.(%{john: 10})
      assert leds.count == 0

      pixel_data = [16_711_680, 65_280, 255]
      leds = config.john.def_func.(%{pixel_data: {pixel_data, 74}})

      assert leds.count == 74
      assert Enum.map(leds.leds, fn {_key, value} -> value end) == pixel_data
      assert leds.opts == %{server_name: nil, namespace: nil}
      assert leds.meta == %{index: 1}
    end
  end
end
