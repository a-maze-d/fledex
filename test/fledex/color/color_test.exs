# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.ColorTest do
  use ExUnit.Case, async: true

  alias Fledex.Color.Conversion.Approximate
  alias Fledex.Color.Conversion.Rainbow
  alias Fledex.Color.Conversion.Raw
  alias Fledex.Color.Conversion.Spectrum

  alias Fledex.Color.Correction
  alias Fledex.Color.Correction.Color
  alias Fledex.Color.Correction.Temperature

  alias Fledex.Color.LoadUtils
  alias Fledex.Color.Names
  alias Fledex.Color.Utils

  alias Fledex.Leds

  describe "color correction tests" do
    test "no_color_correction" do
      assert Correction.define_correction(
        255,
        Color.uncorrected_color,
        Temperature.uncorrected_temperature
      ) == {255, 255, 255}
    end
  end

  describe "color conversion tests" do
    test "approximate" do
      assert {15, 168, 255} == Approximate.rgb2hsv({216, 56, 30})
      assert {0, 0, 0} == Approximate.rgb2hsv({0, 0, 0})
    end
    test "rainbow" do
      assert {173, 14, 5} == Rainbow.hsv2rgb({5, 219, 216}, fn rgb -> rgb end)
      assert {173, 10, 0} == Rainbow.hsv2rgb({5, 255, 216}, fn rgb -> rgb end)
      assert {183, 183, 183} == Rainbow.hsv2rgb({5, 0, 216}, fn rgb -> rgb end)
      assert {0, 0, 0} == Rainbow.hsv2rgb({5, 0, 5}, fn rgb -> rgb end)
    end
    test "raw" do
      assert {198, 44, 30} == Raw.hsv2rgb({5, 219, 216}, fn rgb -> rgb end)
    end
    test "spectrum" do
      assert {204, 38, 30} == Spectrum.hsv2rgb({5, 219, 216}, fn rgb -> rgb end)
    end
    test "set_colors" do
      assert Raw.set_colors(0, 128, 150, 182) == {182, 150, 128}
      assert Raw.set_colors(1, 128, 150, 182) == {128, 182, 150}
      assert Raw.set_colors(2, 128, 150, 182) == {150, 128, 182}
    end
  end

  describe "color names tests" do
    test "loading color file" do
      colors = LoadUtils.load_color_file(LoadUtils.names_file)
      assert colors != []

      assert Enum.slice(Names.colors(), 828..828) == [%{
        hex: 14_235_678,
        hsl: {5, 193, 122},
        hsv: {5, 219, 216},
        index: 828,
        name: :vermilion2,
        rgb: {216, 56, 30},
        descriptive_name: "Vermilion2",
        source: ""
      }]
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
        rgb: {216, 56, 30}
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
        rgb: {216, 56, 30}
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

      assert :vermilion2 in Names.names()
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
    test "color name import" do
      import Fledex.Color.Names
      assert 14_235_678 == vermilion2()
    end
    test "color name guard" do
      import Fledex.Color.Names, only: [is_color_name: 1]
      assert is_color_name(:vermilion2) == true
      assert is_color_name(:non_existing) == false
    end
    test "Leds addition" do
      leds = Leds.leds(3) |> Names.red |> Names.green |> Names.blue
      assert Leds.get_light(leds, 1) == 0xff0000
      assert Leds.get_light(leds, 2) == 0x00ff00
      assert Leds.get_light(leds, 3) == 0x0000ff

      leds = Leds.leds(3) |> Names.blue(3) |> Names.green(2) |> Names.red(1)
      assert Leds.get_light(leds, 1) == 0xff0000
      assert Leds.get_light(leds, 2) == 0x00ff00
      assert Leds.get_light(leds, 3) == 0x0000ff
    end
  end
  describe "test color corrections" do
    test "color" do
      assert Correction.Color.typical_smd5050   == 0xFFB0F0
      assert Correction.Color.typical_led_strip == 0xFFB0F0
      assert Correction.Color.typical_8mm_pixel == 0xFFE08C
      assert Correction.Color.typical_pixel     == 0xFFE08C
      assert Correction.Color.uncorrected_color == 0xFFFFFF
    end
    test "temperature" do
      assert Correction.Temperature.candle                    == 0xFF9329
      assert Correction.Temperature.tungsten_40w              == 0xFFC58F
      assert Correction.Temperature.tungsten_100w             == 0xFFD6AA
      assert Correction.Temperature.halogen                   == 0xFFF1E0
      assert Correction.Temperature.carbon_arc                == 0xFFFAF4
      assert Correction.Temperature.high_noon_sun             == 0xFFFFFB
      assert Correction.Temperature.direct_sunlight           == 0xFFFFFF
      assert Correction.Temperature.overcast_sky              == 0xC9E2FF
      assert Correction.Temperature.clear_blue_sky            == 0x409CFF
      assert Correction.Temperature.warm_fluorescent          == 0xFFF4E5
      assert Correction.Temperature.standard_fluorescent      == 0xF4FFFA
      assert Correction.Temperature.cool_white_fluorescent    == 0xD4EBFF
      assert Correction.Temperature.full_spectrum_fluorescent == 0xFFF4F2
      assert Correction.Temperature.grow_light_fluorescent    == 0xFFEFF7
      assert Correction.Temperature.black_light_fluorescent   == 0xA700FF
      assert Correction.Temperature.mercury_vapor             == 0xD8F7FF
      assert Correction.Temperature.sodium_vapor              == 0xFFD1B2
      assert Correction.Temperature.metal_halide              == 0xF2FCFF
      assert Correction.Temperature.high_pressure_sodium      == 0xFFB74C
      assert Correction.Temperature.uncorrected_temperature   == 0xFFFFFF
    end
    test "correction functions" do
      assert Correction.color_correction_g2({0xFF, 0xFF, 0xFF}) == {0xFF, 0x3F, 0xFF}
      assert Correction.define_correction(0, 0xFFFFFF, 0xFFFFFF) == {0, 0, 0}
      assert Correction.apply_rgb_correction([{0x7F, 0x7F, 0x7f}], 0xFFFFFF) == [{0x7F, 0x7F, 0x7F}]
      assert Correction.calculate_color_correction(0x10, 0, 0) == 0
    end
  end
  describe "color conversions" do
    test "approximate rgb2hsv" do
    # Wikipedia has the following table:
    # https://en.wikipedia.org/wiki/HSL_and_HSV
    # This should take us around the whole Hue scale. But note, we do have an approximation, so not 100% accurate
    # Color 	      R 	    G 	    B 	    H 	   H2 	    C 	    C2 	    V 	    L 	    I 	Y′601 	SHSV 	  SHSL 	  SHSI
    # #FFFFFF 	1.000 	1.000 	1.000 	n/a 	  n/a 	  0.000 	0.000 	1.000 	1.000 	1.000 	1.000 	0.000 	0.000 	0.000
    # #808080 	0.500 	0.500 	0.500 	n/a 	  n/a 	  0.000 	0.000 	0.500 	0.500 	0.500 	0.500 	0.000 	0.000 	0.000
    # #000000 	0.000 	0.000 	0.000 	n/a 	  n/a 	  0.000 	0.000 	0.000 	0.000 	0.000 	0.000 	0.000 	0.000 	0.000
    # #FF0000 	1.000 	0.000 	0.000 	0.0° 	  0.0° 	  1.000 	1.000 	1.000 	0.500 	0.333 	0.299 	1.000 	1.000 	1.000
    # #BFBF00 	0.750 	0.750 	0.000 	60.0° 	60.0° 	0.750 	0.750 	0.750 	0.375 	0.500 	0.664 	1.000 	1.000 	1.000
    # #008000 	0.000 	0.500 	0.000 	120.0° 	120.0° 	0.500 	0.500 	0.500 	0.250 	0.167 	0.293 	1.000 	1.000 	1.000
    # #80FFFF 	0.500 	1.000 	1.000 	180.0° 	180.0° 	0.500 	0.500 	1.000 	0.750 	0.833 	0.850 	0.500 	1.000 	0.400
    # #8080FF 	0.500 	0.500 	1.000 	240.0° 	240.0° 	0.500 	0.500 	1.000 	0.750 	0.667 	0.557 	0.500 	1.000 	0.250
    # #BF40BF 	0.750 	0.250 	0.750 	300.0° 	300.0° 	0.500 	0.500 	0.750 	0.500 	0.583 	0.457 	0.667 	0.500 	0.571
    # #A0A424 	0.628 	0.643 	0.142 	61.8° 	61.5° 	0.501 	0.494 	0.643 	0.393 	0.471 	0.581 	0.779 	0.638 	0.699
    # #411BEA 	0.255 	0.104 	0.918 	251.1° 	250.0° 	0.814 	0.750 	0.918 	0.511 	0.426 	0.242 	0.887 	0.832 	0.756
    # #1EAC41 	0.116 	0.675 	0.255 	134.9° 	133.8° 	0.559 	0.504 	0.675 	0.396 	0.349 	0.460 	0.828 	0.707 	0.667
    # #F0C80E 	0.941 	0.785 	0.053 	49.5° 	50.5° 	0.888 	0.821 	0.941 	0.497 	0.593 	0.748 	0.944 	0.893 	0.911
    # #B430E5 	0.704 	0.187 	0.897 	283.7° 	284.8° 	0.710 	0.636 	0.897 	0.542 	0.596 	0.423 	0.792 	0.775 	0.686
    # #ED7651 	0.931 	0.463 	0.316 	14.3° 	13.2° 	0.615 	0.556 	0.931 	0.624 	0.570 	0.586 	0.661 	0.817 	0.446
    # #FEF888 	0.998 	0.974 	0.532 	56.9° 	57.4° 	0.466 	0.454 	0.998 	0.765 	0.835 	0.931 	0.467 	0.991 	0.363
    # #19CB97 	0.099 	0.795 	0.591 	162.4° 	163.4° 	0.696 	0.620 	0.795 	0.447 	0.495 	0.564 	0.875 	0.779 	0.800
    # #362698 	0.211 	0.149 	0.597 	248.3° 	247.3° 	0.448 	0.420 	0.597 	0.373 	0.319 	0.219 	0.750 	0.601 	0.533
    # #7E7EB8 	0.495 	0.493 	0.721 	240.5° 	240.4° 	0.228 	0.227 	0.721 	0.607 	0.570 	0.520 	0.316 	0.290 	0.135
    assert Approximate.rgb2hsv(Utils.to_rgb(0xffffff)) == {0, 0, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x808080)) == {0, 0, 181}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x000000)) == {0, 0, 0}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xff0000)) == {0, 255, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xbfbf00)) == {63, 255, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x008000)) == {96, 255, 181}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x80ffff)) == {195, 74, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x8080ff)) == {195, 74, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xbf40bf)) == {0, 127, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xa0a424)) == {71, 159, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x411bea)) == {182, 172, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x1eac41)) == {116, 168, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xf0c80e)) == {43, 196, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xb430e5)) == {248, 145, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xed7651)) == {32, 111, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0xfef888)) == {55, 69, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x19c897)) == {147, 175, 255}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x362698)) == {172, 157, 252}
    assert Approximate.rgb2hsv(Utils.to_rgb(0x7e7eb8)) == {160, 76, 255}
    end
  end
end
