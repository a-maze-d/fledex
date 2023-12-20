defmodule Fledex.Effect.WanishTest do
  use ExUnit.Case

  alias Fledex.Effect.Wanish

  describe "wanish effect" do
    test "simple (default trigger name)" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Wanish.apply(leds, [], triggers)

      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end
    test "with trigger name" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{counter: 1}

      returned_leds = Wanish.apply(leds, [trigger_name: :counter], triggers)

      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end
    test "with right direction" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Wanish.apply(leds, [direction: :right], triggers)

      assert returned_leds == [0xff0000, 0x00ff00, 0x000000]
    end
    test "with divisor" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      returned_leds = Wanish.apply(leds, [divisor: 2], triggers)

      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]

      triggers = %{default: 2}
      returned_leds = Wanish.apply(leds, [divisor: 2], triggers)

      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end

  end
end
