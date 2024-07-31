# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.NullTest do
  use ExUnit.Case, async: true

  alias Fledex.Driver.Impl.Null

  describe "null driver basic tests" do
    test "init" do
      assert Null.init([]) == []
    end

    test "reinit" do
      assert Null.reinit([], []) == []
    end

    test "transfer" do
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      assert Null.transfer(leds, 0, []) == {[], :ok}
    end

    test "terminate" do
      assert Null.terminate(:normal, []) == :ok
    end
  end
end
