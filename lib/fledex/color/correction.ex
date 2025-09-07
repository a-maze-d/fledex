# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Correction do
  import Bitwise

  alias Fledex.Color, as: Protocol
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.Types

  defmodule Color do
    @moduledoc """
    Color correction starting points
    """
    @doc """
    Typical values for SMD5050 LEDs (255, 176, 240)
    """
    def typical_smd5050, do: 0xFFB0F0

    @doc """
    Use this if you don't know the led type, it will be configured
    to the most appropriate value for led strips.
    """
    def typical_led_strip, do: 0xFFB0F0

    @doc """
    Typical values for 8 mm "pixels on a string"
    """
    def typical_8mm_pixel, do: 0xFFE08C

    @doc """
    same as `typical_8mm_pixel`
    """
    def typical_pixel_string, do: 0xFFE08C

    @doc """
    To be used if you don't want to correct the color, i.e. all with full intensity (255, 255, 255)
    """
    def uncorrected_color, do: 0xFFFFFF
  end

  defmodule Temperature do
    @moduledoc """
    Color temperature values

    These color values are separated into two groups: black body radiators
    and gaseous light sources.

    Black body radiators emit a (relatively) continuous spectrum,
    and can be described as having a Kelvin 'temperature'. This includes things
    like candles, tungsten lightbulbs, and sunlight.

    Gaseous light sources emit discrete spectral bands, and while we can
    approximate their aggregate hue with RGB values, they don't actually
    have a proper Kelvin temperature.

    See wikipedia:
    * [Color temperature](https://en.wikipedia.org/wiki/Color_temperature)
    * [Black body radiation](https://en.wikipedia.org/wiki/Black-body_radiation)
    * [Gas discharge lamp](https://en.wikipedia.org/wiki/Gas-discharge_lamp)
    """

    @doc """
    Black Body Radiator: 1900K (255, 147, 41)
    """
    def candle, do: 0xFF9329

    @doc """
    Black Body Radiator: 2600K (255, 197, 143)
    """
    def tungsten_40w, do: 0xFFC58F

    @doc """
    Black Body Radiator: 2850K (255, 214, 170)
    """
    def tungsten_100w, do: 0xFFD6AA

    @doc """
    Black Body Radiator: 3200K (255, 241, 224)
    """
    def halogen, do: 0xFFF1E0

    @doc """
    Black Body Radiator: 5200K (255, 250, 244)
    """
    def carbon_arc, do: 0xFFFAF4

    @doc """
    Black Body Radiator: 5400K (255, 255, 251)
    """
    def high_noon_sun, do: 0xFFFFFB

    @doc """
    Black Body Radiator: 6000K (255, 255, 255)
    """
    def direct_sunlight, do: 0xFFFFFF

    @doc """
    Black Body Radiator: 7000K (201, 226, 255)
    """
    def overcast_sky, do: 0xC9E2FF

    @doc """
    Black Body Radiator: 20000K (64, 156, 255)
    """
    def clear_blue_sky, do: 0x409CFF

    @doc """
    Gaseous Light Source: Warm (yellower) flourescent light bulbs, 0 K, (255, 244, 229)
    """
    def warm_fluorescent, do: 0xFFF4E5

    @doc """
    Gaseous Light Source: Standard flourescent light bulbs, 0 K, (244, 255, 250)
    """
    def standard_fluorescent, do: 0xF4FFFA

    @doc """
    Gaseous Light Source: Cool white (bluer) flourescent light bulbs, 0 K, (212, 235, 255)
    """
    def cool_white_fluorescent, do: 0xD4EBFF

    @doc """
    Gaseous Light Source: Full spectrum flourescent light bulbs, 0 K, (255, 244, 242)
    """
    def full_spectrum_fluorescent, do: 0xFFF4F2

    @doc """
    Gaseous Light Source: Grow light flourescent light bulbs, 0 K, (255, 239, 247)
    """
    def grow_light_fluorescent, do: 0xFFEFF7

    @doc """
    Gaseous Light Source: Black light flourescent light bulbs, 0 K, (167, 0, 255)
    """
    def black_light_fluorescent, do: 0xA700FF

    @doc """
    Gaseous Light Source: Mercury vapor light bulbs, 0 K, (216, 247, 255)
    """
    def mercury_vapor, do: 0xD8F7FF

    @doc """
    Gaseous Light Source: Sodium vapor light bulbs, 0 K, (255, 209, 178)
    """
    def sodium_vapor, do: 0xFFD1B2

    @doc """
    Gaseous Light Source: Metal-halide light bulbs: 0 K, (242, 252, 255)
    """
    def metal_halide, do: 0xF2FCFF

    @doc """
    Gaseous Light Source: High-pressure sodium light bulbs, 0 K, (255, 183, 76)
    """
    def high_pressure_sodium, do: 0xFFB74C

    @doc """
    Uncorrected temperature, (255, 255, 255)
    """
    def uncorrected_temperature, do: 0xFFFFFF
  end

  @spec define_correction(byte, Types.colorint(), Types.colorint()) :: Types.rgb()
  def define_correction(scale \\ 255, color_correction, temperature_correction)

  def define_correction(scale, color_correction, temperature_correction) when scale > 0 do
    {ccr, ccg, ccb} = Protocol.to_rgb(color_correction)
    {tcr, tcg, tcb} = Protocol.to_rgb(temperature_correction)

    r = calculate_single_color_correction(scale, ccr, tcr)
    g = calculate_single_color_correction(scale, ccg, tcg)
    b = calculate_single_color_correction(scale, ccb, tcb)

    {r, g, b}
  end

  def define_correction(_scale, _color_correction, _temperature_correction) do
    {0, 0, 0}
  end

  @spec no_color_correction() :: Types.rgb()
  def no_color_correction do
    # yes we could hard code this, but this is rarely used and therefore not performant
    # relevant. And this is more clear on what it means to not have any color correction.
    define_correction(Color.uncorrected_color(), Temperature.uncorrected_temperature())
  end

  @doc """
  This function corrects an led color with the specified correction.

  The `correction` probably should be created by composing the different aspects
  by using `define_correction/3`
  """
  @spec apply_rgb_correction(list(Types.rgb()), byte | Types.rgb()) :: list(Types.rgb())
  def apply_rgb_correction(leds, {255, 255, 255}), do: leds
  def apply_rgb_correction(leds, 0xFFFFFF), do: leds

  def apply_rgb_correction(leds, correction) do
    Enum.map(leds, fn led ->
      CalcUtils.nscale8(led, correction, false)
    end)
  end

  # MARK: public helper functions
  @doc """
  Calculate the color correction for a single base color.

  It expects the scale, the color correction and color temperature for the
  base color to calculate the correction for that base color.
  """
  @spec calculate_single_color_correction(byte, byte, byte) :: byte
  def calculate_single_color_correction(scale, cc, ct) when cc > 0 and ct > 0 do
    work = (cc + 1) * (ct + 1) * scale
    work = work / 0x10000
    Kernel.trunc(work) &&& 0xFF
  end

  def calculate_single_color_correction(_scale, _cc, _ct), do: 0
end
