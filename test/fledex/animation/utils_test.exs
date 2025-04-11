# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.UtilsTest do
  use ExUnit.Case

  alias Fledex.Animation.Utils
  alias Fledex.Leds

  describe "util functions" do
    test "ensure correct naming" do
      assert Utils.build_name(:testA, :animator, :testB) ==
               :"Elixir.testA.animator.testB"
    end

    test "default_def_func" do
      assert Utils.default_def_func(%{}) == Leds.leds()
      assert Utils.default_def_func(%{trigger_name: 10}) == Leds.leds()
    end

    test "default_send_func" do
      assert Utils.default_send_config_func(%{}) == []
      assert Utils.default_send_config_func(%{trigger_name: 10}) == []
    end
  end
end
