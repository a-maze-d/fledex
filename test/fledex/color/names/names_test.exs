# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.NamesTest do
  use ExUnit.Case

  alias Fledex.Color
  alias Fledex.Color.Names
  alias Fledex.Color.Names.LoadUtils
  alias Fledex.Color.Names.Wiki
  alias Fledex.Color.Names.WikiUtils
  alias Fledex.Leds

  describe "color names loading tests" do
    test "loading color file" do
      colors =
        LoadUtils.load_color_file(
          Wiki.file(),
          ~r/^.*$/i,
          1,
          [separator: ",", split_opts: [parts: 11]],
          &WikiUtils.converter/1,
          __MODULE__
        )

      assert colors != %{}

      assert Map.get(colors, :vermilion2) ==
               %{
                 hex: 14_235_678,
                 hsl: {5, 193, 122},
                 hsv: {5, 219, 216},
                 index: 828,
                 name: :vermilion2,
                 rgb: {216, 56, 30},
                 descriptive_name: "Vermilion2",
                 source: "",
                 module: __MODULE__
               }
    end

    test "helper functions" do
      assert LoadUtils.convert_to_atom(" Test String#") == :test_string
      assert LoadUtils.clean_and_convert("#808080") == 0x808080
      assert LoadUtils.to_byte("—") == 0
      assert LoadUtils.to_byte("90°") == 63
      assert LoadUtils.to_byte("25%") == 63
      assert LoadUtils.a2i("12_b") == 12
      assert LoadUtils.clean("ab12_b") == "12"
      assert Color.to_colorint({0x80, 0x80, 0x80}) == 0x808080
    end
  end

  describe "color names access tests" do
    test "defined color modules" do
      color_name_modules = Names.color_name_modules()
      assert length(color_name_modules) == 4
      assert List.first(color_name_modules) == {Fledex.Color.Names.Wiki, :core}
      assert List.last(color_name_modules) == {Fledex.Color.Names.RAL, :optional}
    end

    test "calling by name" do
      assert Names.vermilion2(:all) == %{
               hex: 14_235_678,
               hsl: {5, 193, 122},
               hsv: {5, 219, 216},
               index: 828,
               name: :vermilion2,
               descriptive_name: "Vermilion2",
               source: "",
               rgb: {216, 56, 30},
               module: Fledex.Color.Names.Wiki
             }
    end

    test "calling by name with atom" do
      assert Names.info(:vermilion2, :all) == %{
               hex: 14_235_678,
               hsl: {5, 193, 122},
               hsv: {5, 219, 216},
               index: 828,
               name: :vermilion2,
               descriptive_name: "Vermilion2",
               source: "",
               rgb: {216, 56, 30},
               module: Fledex.Color.Names.Wiki
             }
    end

    test "test quick access functions" do
      assert 14_235_678 == Names.vermilion2()
      assert 14_235_678 == Names.vermilion2(:hex)
      assert {216, 56, 30} == Names.vermilion2(:rgb)
      assert {5, 193, 122} == Names.vermilion2(:hsl)
      assert {5, 219, 216} == Names.vermilion2(:hsv)
      assert 828 == Names.vermilion2(:index)
      assert "Vermilion2" == Names.vermilion2(:descriptive_name)
      assert "" == Names.vermilion2(:source)
      assert "Crayola" == Names.absolute_zero(:source)

      assert Enum.find_index(Names.names(), fn x -> x == :vermilion2 end) != nil
      assert Enum.find_index(Names.colors(), fn x -> x.name == :vermilion2 end) != nil
    end

    test "test quick access functions (with atom)" do
      assert 14_235_678 == Names.info(:vermilion2)
      assert 14_235_678 == Names.info(:vermilion2, :hex)
      assert {216, 56, 30} == Names.info(:vermilion2, :rgb)
      assert :vermilion2 == Names.info(:vermilion2, :name)
      assert {5, 193, 122} == Names.info(:vermilion2, :hsl)
      assert {5, 219, 216} == Names.info(:vermilion2, :hsv)
      assert 828 == Names.info(:vermilion2, :index)
      assert "Vermilion2" == Names.info(:vermilion2, :descriptive_name)
      assert "" == Names.info(:vermilion2, :source)
      assert "Crayola" == Names.info(:absolute_zero, :source)
      assert nil == Names.info(:non_existing_color_name, :hex)

      assert :vermilion2 in Names.names()
    end
  end

  describe "color names usage tests" do
    test "color name import" do
      import Fledex.Color.Names
      assert 14_235_678 == vermilion2()
    end

    test "color name guard (names guard)" do
      import Fledex.Color.Names
      assert is_color_name(:vermilion2) == true
      assert is_color_name(:non_existing) == true
    end

    test "color name guard (wiki guard)" do
      import Fledex.Color.Names.Wiki
      assert is_color_name(:vermilion2) == true
      assert is_color_name(:non_existing) == false
    end

    test "Leds addition" do
      leds = Leds.leds(3) |> Names.red() |> Names.green() |> Names.blue()
      assert Leds.get_light(leds, 1) == 0xFF0000
      assert Leds.get_light(leds, 2) == 0x00FF00
      assert Leds.get_light(leds, 3) == 0x0000FF

      leds =
        Leds.leds(3) |> Names.blue(offset: 3) |> Names.green(offset: 2) |> Names.red(offset: 1)

      assert Leds.get_light(leds, 1) == 0xFF0000
      assert Leds.get_light(leds, 2) == 0x00FF00
      assert Leds.get_light(leds, 3) == 0x0000FF
    end

    test "non-existing color name atoms default to black" do
      alias Fledex.Color
      alias Fledex.Leds

      leds =
        Leds.leds(3)
        |> Leds.light(:non_existing)
        |> Leds.light(Color.to_rgb(:non_existing))
        |> Leds.light(Color.to_colorint(:non_existing))

      assert Leds.get_light(leds, 1) == 0x000000
      assert Leds.get_light(leds, 2) == 0x000000
      assert Leds.get_light(leds, 3) == 0x000000
    end
  end
end
