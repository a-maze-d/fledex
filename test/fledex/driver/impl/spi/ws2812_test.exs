# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi.Ws2812Test do
  use ExUnit.Case, async: false

  alias Fledex.Color.Correction
  alias Fledex.Driver.Impl.Spi.Utils
  alias Fledex.Driver.Impl.Spi.Ws2812

  describe "test driver basic tests" do
    test "default init" do
      # we can only test the default device, since only that one has a
      # simulator configured.
      config = Ws2812.init([], [])
      assert Keyword.fetch!(config, :dev) == "spidev0.0"
      assert Keyword.fetch!(config, :mode) == 0
      assert Keyword.fetch!(config, :bits_per_word) == 8
      assert Keyword.fetch!(config, :speed_hz) == 2_600_000
      assert Keyword.fetch!(config, :delay_us) == 300
      assert Keyword.fetch!(config, :lsb_first) == false
      assert Keyword.fetch!(config, :color_correction) == Correction.no_color_correction()
      assert Keyword.fetch!(config, :type) == :grb
      assert Keyword.fetch!(config, :ref) != nil
    end

    def test_zero_transfer(_leds, _counter, config) do
      assert false
      {config, <<>>}
    end

    def test_100_transfer(leds, counter, config) do
      assert Enum.count(leds) == 100
      assert counter == 100

      Enum.each(leds, fn led ->
        assert led == 0x000000
      end)

      {config, <<>>}
    end

    def test_100red_transfer(leds, counter, config) do
      assert Enum.count(leds) == 100
      assert counter == 100

      Enum.each(leds, fn led ->
        assert led == 0xFF0000
      end)

      {config, <<>>}
    end

    test "clear_leds" do
      config = Ws2812.init([], [])
      Utils.clear_leds(0, config, &test_zero_transfer/3)
      Utils.clear_leds(100, config, &test_100_transfer/3)
      Utils.clear_leds({100, 0xFF0000}, config, &test_100red_transfer/3)

      Ws2812.terminate(:normal, config)
    end

    test "change_config" do
      config = Ws2812.init([], [])
      assert config == Ws2812.change_config(config, [], [])
      :ok = Ws2812.terminate(:normal, config)
    end

    test "transfer rgb" do
      driver = Ws2812.init([], [])
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      # every bit gets split up into 3 bits. 0 = 100, 1 = 110
      expected = <<
        # 255, 0, 0
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        # 0, 255, 0
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        # 0, 0, 255
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24
      >>

      {driver_response, response} = Ws2812.transfer(leds, 0, driver)
      assert response == expected
      assert driver == driver_response
    end

    test "transfer grb" do
      driver = Ws2812.init([type: :rgb], [])
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      # every bit gets split up into 3 bits. 0 = 100, 1 = 110
      expected = <<
        # 255, 0, 0
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        # 0, 255, 0
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        # 0, 0, 255
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24
      >>

      {driver_response, response} = Ws2812.transfer(leds, 0, driver)
      assert response == expected
      assert driver == driver_response
    end

    test "transfer grbw" do
      driver = Ws2812.init([type: :grbw], [])
      leds = [0xFFFF0000, 0x0000FF00, 0x000000FF]
      # every bit gets split up into 3 bits. 0 = 100, 1 = 110
      expected = <<
        # 255, 0, 0, 255
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        # 0, 255, 0, 0
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        # 0, 0, 255, 0
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24
      >>

      {driver_response, response} = Ws2812.transfer(leds, 0, driver)
      assert response == expected
      assert driver == driver_response
    end

    test "transfer rgbw1w2" do
      driver = Ws2812.init([type: :rgbw1w2], [])
      leds = [0x80FFFF0000, 0x800000FF00, 0x000000FF]
      # every bit gets split up into 3 bits. 0 = 100, 1 = 110
      expected = <<
        # 255, 0, 0, 255
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b110100100100100100100100::24,
        # 0, 255, 0, 0
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110100100100100100100100::24,
        # 0, 0, 255, 0
        0b100100100100100100100100::24,
        0b100100100100100100100100::24,
        0b110110110110110110110110::24,
        0b100100100100100100100100::24,
        0b100100100100100100100100::24
      >>

      {driver_response, response} = Ws2812.transfer(leds, 0, driver)
      assert response == expected
      assert driver == driver_response
    end

    test "terminate" do
      driver = Ws2812.init([], [])
      assert :ok == Ws2812.terminate(:normal, driver)
    end
  end
end
