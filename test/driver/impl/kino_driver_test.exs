defmodule Fledex.Driver.Impl.KinoDriverTest do
  use Kino.LivebookCase, async: true

  require Logger

  alias Fledex.Color.Correction
  alias Fledex.Driver.Impl.KinoDriver

  describe "null driver basic tests" do
    test "default init" do
      config = KinoDriver.init(%{})
      assert config.update_freq == 1
      assert config.frame != nil
      assert config.color_correction == Correction.no_color_correction()
    end
    test "reinit" do
      config = KinoDriver.init(%{})
      config_reinit = KinoDriver.reinit(config)
      assert config.frame != config_reinit.frame
    end
    test "transfer" do
      config = KinoDriver.init(%{})
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      {response_config, _response_other} = KinoDriver.transfer(leds, 0, config)
      assert response_config == config
      assert_output(
        %{
          type: :frame_update,
          update: {
            :replace,
            [
              %{
                chunk: false,
                text: "<span style=\"color: #FF0000\">█</span><span style=\"color: #00FF00\">█</span><span style=\"color: #0000FF\">█</span>",
                type: :markdown
              }
            ]
          }
        }
      )
    end
    test "terminate" do
      assert KinoDriver.terminate(:normal, %{}) == :ok
    end
  end
end
