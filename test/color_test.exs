defmodule Fledex.ColorTest do
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
    end
    test "rainbow" do
      assert {173, 14, 5} == Rainbow.hsv2rgb({5, 219, 216}, fn rgb -> rgb end)
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
        rgb: {216, 56, 30}
      }]
    end
    test "calling by name" do
      color = Names.vermilion2()
      assert color == %{
        hex: 14_235_678,
        hsl: {5, 193, 122},
        hsv: {5, 219, 216},
        index: 828,
        name: :vermilion2,
        rgb: {216, 56, 30}
      }
    end
    test "test quick access functions" do
      assert 14_235_678 == Names.get_color_int(:vermilion2)
      assert {216, 56, 30} == Names.get_color_sub_pixels(:vermilion2)
      assert :vermilion in Names.names()
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
end
