defmodule Fledex.Effect.OffsetTest do
  use ExUnit.Case

  alias Fledex.Effect.Offset
  describe "0ffsetting" do
    test "simple" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      config = [offset: 3]
      triggers = %{john: 10}
      new_leds = Offset.apply(leds, 3, config, triggers)

      assert new_leds == [0x000000, 0x000000, 0x000000, 0xff0000, 0x00ff00, 0x0000ff]
    end
  end
end
