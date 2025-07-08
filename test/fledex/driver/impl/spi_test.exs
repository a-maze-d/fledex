# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.SpiTest do
  use ExUnit.Case

  alias Fledex.Color.Correction
  alias Fledex.Driver.Impl.Spi

  describe "test driver basic tests" do
    test "default init" do
      # we can only test the default device, since only that one has a
      # simulator configured.
      config = Spi.init([], [])
      assert Keyword.fetch!(config, :dev) == "spidev0.0"
      assert Keyword.fetch!(config, :mode) == 0
      assert Keyword.fetch!(config, :bits_per_word) == 8
      assert Keyword.fetch!(config, :speed_hz) == 1_000_000
      assert Keyword.fetch!(config, :delay_us) == 10
      assert Keyword.fetch!(config, :lsb_first) == false
      assert Keyword.fetch!(config, :color_correction) == Correction.no_color_correction()
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
      config = Spi.init([], [])
      Spi.clear_leds(0, config, &test_zero_transfer/3)
      Spi.clear_leds(100, config, &test_100_transfer/3)
      Spi.clear_leds({100, 0xFF0000}, config, &test_100red_transfer/3)

      Spi.terminate(:normal, config)
    end

    test "reinit" do
      config = Spi.init([], [])
      assert config == Spi.reinit(config, [], [])
      :ok = Spi.terminate(:normal, config)
    end

    test "transfer" do
      driver = Spi.init([], [])
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      {driver_response, response} = Spi.transfer(leds, 0, driver)
      assert response == <<255, 0, 0, 0, 255, 0, 0, 0, 255>>
      assert driver == driver_response
    end

    test "terminate" do
      driver = Spi.init([], [])
      assert :ok == Spi.terminate(:normal, driver)
    end
  end
end
