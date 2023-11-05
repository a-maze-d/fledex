defmodule Fledex.ColorTest do
  use ExUnit.Case, async: true

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

  describe "color names tests" do
    test "loading color file" do
      colors = LoadUtils.load_color_file()
      assert colors != []
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
  end
end
