defmodule Fledex.LedStripDriver.SpiDriverTest do
  use ExUnit.Case

  alias Fledex.Color.Correction
  alias Fledex.LedStripDriver.SpiDriver

  describe "test driver basic tests" do
    test "default init" do
      # we can only test the default device, since only that one has a
      # simulator configured.
      config = SpiDriver.init(%{})
      assert config.dev == "spidev0.0"
      assert config.mode == 0
      assert config.bits_per_word == 8
      assert config.speed_hz == 1_000_000
      assert config.delay_us == 10
      assert config.lsb_first == false
      assert config.color_correction == Correction.no_color_correction()
      assert config.ref != nil
    end
    test "reinit" do
      config = %{
        dev: "spidev0.0",
        mode: 0,
        bits_per_word: 8,
        speed_hz: 1_000_000,
        delay_us: 10,
        lsb_first: false,
        color_correction: Correction.no_color_correction(),
        ref: nil
      }
      assert config == SpiDriver.reinit(config)
    end
    test "transfer" do
        driver = SpiDriver.init(%{})
        leds = [0xff0000, 0x00ff00, 0x0000ff]
        {driver_response, response} = SpiDriver.transfer(leds, 0, driver)
        assert response == <<255, 0, 0, 0, 255, 0, 0, 0 , 255>>
        assert driver == driver_response
    end
    test "terminate" do
      driver = SpiDriver.init(%{})
      assert :ok == SpiDriver.terminate(:normal, driver)
    end
  end
end
