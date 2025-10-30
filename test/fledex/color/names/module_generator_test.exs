# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.ModuleGeneratorTest do
  use ExUnit.Case, async: false

  alias Fledex.Color
  alias Fledex.Color.Names.LoadUtils
  alias Fledex.Color.Names.Wiki
  alias Fledex.Color.Names.WikiUtils

  alias Fledex.Leds

  defmodule TestNames do
    use Fledex.Color.Names.ModuleGenerator,
      filename: WikiUtils.file_name(),
      name_pattern: ~r/^[a].*$/i,
      drop: 1,
      splitter_opts: [separator: ",", split_opts: [parts: 11]],
      converter: &WikiUtils.converter/1,
      module: __MODULE__
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
      # We onlyl load the colors with a, so all the "other functions are those that we define
      # in addition to the color names and those are:
      # `info/1`, `info/2`, `names/0`, `colors/0`
      assert {96, 4} = {a_func, o_func}

      # check one concrete example that it exists in the correct arities
      assert {:android_green, 0} in functions
      assert {:android_green, 1} in functions
      assert {:android_green, 2} in functions
    end
  end

  describe "color names loading tests" do
    test "loading color file" do
      colors =
        LoadUtils.load_color_file(
          WikiUtils.file_name(),
          &WikiUtils.converter/1,
          module: __MODULE__,
          name_pattern: ~r/^.*$/i,
          drop: 1,
          splitter_opts: [separator: ",", split_opts: [parts: 11]]
        )

      assert colors != %{}

      assert Map.get(colors, :vermilion2) ==
               %{
                 hex: 14_235_678,
                 hsl: %Fledex.Color.HSL{h: 5, s: 193, l: 122},
                 hsv: %Fledex.Color.HSV{h: 5, s: 219, v: 216},
                 index: 828,
                 name: :vermilion2,
                 rgb: {216, 56, 30},
                 descriptive_name: "Vermilion2",
                 source: "",
                 module: __MODULE__
               }
    end

    test "helper functions" do
      assert LoadUtils.str2atom(" Test String#") == :test_string
      assert LoadUtils.hexstr2i("#808080") == 0x808080
      assert LoadUtils.a2b("—") == 0
      assert LoadUtils.a2b("90°") == 63
      assert LoadUtils.a2b("25%") == 63
      assert LoadUtils.a2i("12_b") == 12
      assert LoadUtils.a2i("ab12_b") == 12
      assert LoadUtils.a2i("1ab2") == 12
      assert Color.to_colorint({0x80, 0x80, 0x80}) == 0x808080
    end
  end

  describe "wiki color names generation" do
    test "test quick access functions" do
      alias Fledex.Color.Names.Wiki

      assert 14_235_678 == Wiki.vermilion2()
      assert 14_235_678 == Wiki.vermilion2(:hex)
      assert Fledex.Color.Names.Wiki == Wiki.vermilion2(:module)

      assert Enum.find_index(Wiki.names(), fn x -> x == :vermilion2 end) != nil
      assert Enum.find_index(Wiki.colors(), fn x -> x.name == :vermilion2 end) != nil

      assert {216, 56, 30} == Wiki.info(:vermilion2, :rgb)
      assert %Fledex.Color.HSL{h: 5, s: 193, l: 122} == Wiki.info(:vermilion2, :hsl)
      assert %Fledex.Color.HSV{h: 5, s: 219, v: 216} == Wiki.info(:vermilion2, :hsv)
      assert 828 == Wiki.info(:vermilion2, :index)
      assert "Vermilion2" == Wiki.info(:vermilion2, :descriptive_name)
      assert "" == Wiki.info(:vermilion2, :source)
      assert "Crayola" == Wiki.info(:absolute_zero, :source)
    end
  end

  describe "color names usage tests" do
    test "color name guard (wiki guard)" do
      import Fledex.Color.Names.Wiki
      assert is_color_name(:vermilion2) == true
      assert is_color_name(:non_existing) == false
    end

    test "Leds addition" do
      alias Fledex.Color.Names.Wiki

      leds =
        Leds.leds(3)
        |> Wiki.red()
        |> Wiki.green()
        |> Wiki.blue()

      assert Leds.get_light(leds, 1) == 0xFF0000
      assert Leds.get_light(leds, 2) == 0x00FF00
      assert Leds.get_light(leds, 3) == 0x0000FF

      leds =
        Leds.leds(3)
        |> Wiki.blue(offset: 3)
        |> Wiki.green(offset: 2)
        |> Wiki.red(offset: 1)

      assert Leds.get_light(leds, 1) == 0xFF0000
      assert Leds.get_light(leds, 2) == 0x00FF00
      assert Leds.get_light(leds, 3) == 0x0000FF
    end
  end
end
