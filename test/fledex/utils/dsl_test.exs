# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.DslTest do
  defmodule Test do
  end

  defmodule TestWithColorNames do
    @behaviour Fledex.Color.Names.Interface
    defguard is_color_name(name) when name == :red or name == :green or name == :blue
    def names, do: [:red, :green, :blue]
    def colors, do: []
    def info(_name, _val), do: nil
  end

  use ExUnit.Case

  alias Fledex.Utils.Dsl

  describe "basic utility tests" do
    test "create_config" do
    end

    test "apply_effect" do
      block = %{
        name: %{
          effects: []
        }
      }

      assert Dsl.apply_effect(Test, [a: :blue], block) == %{
               name: %{effects: [{Test, [a: :blue]}]}
             }

      assert Dsl.apply_effect(Test, [b: :green], [block]) == %{
               name: %{effects: [{Test, [b: :green]}]}
             }

      assert_raise ArgumentError, fn ->
        Dsl.apply_effect(Test, %{}, block)
      end
    end

    test "configure_strip (debug only)" do
      block = %{name: %{}}
      assert Dsl.configure_strip(:name, :config, [], block) == block
    end

    test "ast_add_argument_to_func" do
      ast_without_arg =
        quote do
          :ok
        end

      assert {:fn, _a, [{:->, _b, [[{:_triggers, _c, _d}], :ok]}]} =
               Dsl.ast_add_argument_to_func(ast_without_arg)
    end

    test "ast_add_argument_to_func with arg" do
      ast_with_arg =
        quote do
          trigger -> :ok
        end

      assert_raise ArgumentError, fn -> Dsl.ast_add_argument_to_func(ast_with_arg) end
    end

    test "ast_add_argument_to_func_if_missing" do
      ast_with_arg =
        quote do
          _triggers -> :ok
        end

      assert {:fn, _a, [{:->, _b, [[{:_triggers, _c, _d}], :ok]}]} =
               Dsl.ast_add_argument_to_func_if_missing(ast_with_arg)
    end
  end

  describe "color name definition" do
    test "correct module order" do
      assert [{Fledex.Color.Names.Wiki, _colors1}, {Fledex.Color.Names.CSS, _colors2}] =
               Dsl.find_modules_with_names([:wiki, :css])

      assert [{Fledex.Color.Names.Wiki, _colors1}, {Fledex.Color.Names.CSS, _colors2}] =
               Dsl.find_modules_with_names([Fledex.Color.Names.Wiki, :css])

      assert [{Fledex.Color.Names.Wiki, _colors1}, {Fledex.Color.Names.CSS, _colors2}] =
               Dsl.find_modules_with_names([:wiki, Fledex.Color.Names.CSS])

      assert [{Fledex.Color.Names.Wiki, _colors1}, {Fledex.Color.Names.CSS, _colors2}] =
               Dsl.find_modules_with_names([Fledex.Color.Names.Wiki, Fledex.Color.Names.CSS])
    end

    test "correct module count" do
      modules_and_colors = Dsl.find_modules_with_names([:all])
      assert length(modules_and_colors) == 4
      modules_and_colors = Dsl.find_modules_with_names([:default])
      assert length(modules_and_colors) == 3
      modules_and_colors = Dsl.find_modules_with_names(nil)
      assert length(modules_and_colors) == 3
      modules_and_colors = Dsl.find_modules_with_names([:none])
      assert Enum.empty?(modules_and_colors)
      modules_and_colors = Dsl.find_modules_with_names([])
      assert Enum.empty?(modules_and_colors)
    end

    test "unknown color module" do
      import ExUnit.CaptureLog

      assert capture_log(fn ->
               assert [] = Dsl.find_modules_with_names(Test)
             end) =~ "Not a known color name"
    end

    test "custom color module" do
      assert [{TestWithColorNames, names}] = Dsl.find_modules_with_names(TestWithColorNames)
      assert names == [:blue, :green, :red]
    end

    test "custom module with correct only names" do
      [{Fledex.Color.Names.Wiki, wiki_names}, {TestWithColorNames, test_names}] =
        Dsl.find_modules_with_names([:wiki, TestWithColorNames])

      assert :red in wiki_names
      assert :green in wiki_names
      assert :blue in wiki_names
      assert :red not in test_names
      assert :green not in test_names
      assert :blue not in test_names
    end
  end
end
