# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.BaseTest do
  use ExUnit.Case

  alias Fledex.Animation.Base
  alias Fledex.Animation.Interface
  alias Fledex.Leds

  describe "util functions" do
    test "ensure correct naming" do
      assert Interface.build_name(:testA, :animation, :testB) == :"Elixir.testA.animation.testB"
    end

    test "default_def_func" do
      assert Base.default_def_func(%{}) == Leds.leds()
      assert Base.default_def_func(%{trigger_name: 10}) == Leds.leds()
    end

    test "default_send_func" do
      assert Base.default_send_config_func(%{}) == %{}
      assert Base.default_send_config_func(%{trigger_name: 10}) == %{}
    end
  end
end
