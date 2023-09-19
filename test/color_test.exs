defmodule Fledex.ColorTest do
  use ExUnit.Case
  use Fledex.Color.Names

  alias Fledex.Color.Correction
  alias Fledex.Color.Correction.Color
  alias Fledex.Color.Correction.Temperature

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
      colors = load_color_file()
      assert colors != []
    end
  end
end
