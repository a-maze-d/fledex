defmodule Fledex.Animation.BaseAnimationTest do
  use ExUnit.Case

  alias Fledex.Animation.BaseAnimation
  alias Fledex.Leds

  describe "util functions" do
    test "ensure correct naming" do
      assert BaseAnimation.build_animator_name(:testA, :testB) == :testA_testB
    end
    test "default_def_func" do
      assert BaseAnimation.default_def_func(%{}) == Leds.leds()
      assert BaseAnimation.default_def_func(%{trigger_name: 10}) == Leds.leds()
    end
    test "default_send_func" do
      assert BaseAnimation.default_send_config_func(%{}) == %{}
      assert BaseAnimation.default_send_config_func(%{trigger_name: 10}) == %{}
    end
  end
end
