# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.DslTest do
  use ExUnit.Case

  defmodule TestNames do
    use Fledex.Color.Names.Dsl, pattern: ~r/^[a].*$/i
  end

  describe "check function creation" do
    test "we created color functions with different arities" do
      # we just `use`ed the DSL module in our TestNames module and that
      # should create a lot of functions for the different colors.
      functions = TestNames.__info__(:functions)

      {a_func, o_func} =
        Enum.reduce(functions, {0, 0}, fn {name, _arity}, {a_func, o_func} ->
          if String.first(Atom.to_string(name)) == "a" do
            {a_func + 1, o_func}
          else
            {a_func, o_func + 1}
          end
        end)

      # check how many color names (starting with a) we found and how many other functions
      assert {96, 2} = {a_func, o_func}

      # check one concrete example that it exists in the correct arities
      assert {:android_green, 0} in functions
      assert {:android_green, 1} in functions
      assert {:android_green, 2} in functions
    end
  end
end
