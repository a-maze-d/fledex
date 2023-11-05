defmodule Fledex.LedStripDriver.LoggerDriverTest do
  use ExUnit.Case, async: true

  alias Fledex.LedStripDriver.LoggerDriver

  describe "init" do
    test "defaults" do
      config = LoggerDriver.init(%{})
      assert config.update_freq == 10
      assert config.log_color_code == false
    end
    test "init_args" do
      config = LoggerDriver.init(%{
        update_freq: 12,
        log_color_code: true
      })
      assert config.update_freq == 12
      assert config.log_color_code == true

    end
  end
end
