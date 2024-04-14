# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.AnimatorBaseTest do
  use ExUnit.Case

  alias Fledex.Animation.AnimatorBase
  alias Fledex.Animation.AnimatorInterface
  alias Fledex.Leds

  describe "util functions" do
    test "ensure correct naming" do
      assert AnimatorInterface.build_name(:testA, :animator, :testB) ==
               :"Elixir.testA.animator.testB"
    end

    test "default_def_func" do
      assert AnimatorBase.default_def_func(%{}) == Leds.leds()
      assert AnimatorBase.default_def_func(%{trigger_name: 10}) == Leds.leds()
    end

    test "default_send_func" do
      assert AnimatorBase.default_send_config_func(%{}) == %{}
      assert AnimatorBase.default_send_config_func(%{trigger_name: 10}) == %{}
    end
  end
end
