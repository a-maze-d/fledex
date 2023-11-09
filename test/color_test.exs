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
end
