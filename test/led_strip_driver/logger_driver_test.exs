defmodule Fledex.LedStripDriver.LoggerDriverTest do
  use ExUnit.Case
  alias Fledex.LedStripDriver

  describe "init" do
    test "defaults" do
      state = LedStripDriver.LoggerDriver.init(%{}, %{})
      assert state.led_strip.config.update_freq == 10
      assert state.led_strip.config.log_color_code == false
    end
  end
end
