defmodule Fledex.Color_Test do
  use ExUnit.Case
  alias Fledex.Color.Correction
  alias Fledex.Color.Correction.Color
  alias Fledex.Color.Correction.Temperature


  describe "color correction tests" do
    test "no_color_correction" do
      assert Correction.define_correction(255, Color.uncorrectedColor, Temperature.uncorrectedTemperature) == {255, 255, 255}
    end
  end
end
