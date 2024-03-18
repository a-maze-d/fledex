# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.DslTest do
  defmodule Test do

  end
  use ExUnit.Case

  alias Fledex.Utils.Dsl

  describe "basic utility tests" do
    test "create_config" do

    end
    test "apply_effect" do
      block = %{name: %{
          effects: []
        }}
      assert Dsl.apply_effect(Test, [a: :blue], block) == %{name: %{effects: [{Test, [a: :blue]}]}}
      assert Dsl.apply_effect(Test, [b: :green], [block]) == %{name: %{effects: [{Test, [b: :green]}]}}
      assert_raise ArgumentError, fn ->
        Dsl.apply_effect(Test, %{}, block)
      end
    end
    test "configure_strip (debug only)" do
      block = %{name: %{}}
      assert Dsl.configure_strip(:name, :debug, block) == block
    end
  end
end
