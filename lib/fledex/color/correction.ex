# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Correction do
  @moduledoc """
  Definitions and functions to perform color corrections
  """
  import Bitwise

  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.RGB
  alias Fledex.Color.Types

  defmodule Color do
    @moduledoc """
    Color correction depending on the hardware used
    """

    @doc """
    Typical values for SMD5050 LEDs (255, 176, 240)
    """
    @spec typical_smd5050 :: 0xFFB0F0
    def typical_smd5050, do: 0xFFB0F0

    @doc """
    Use this if you don't know the led type, it will be configured
    to the most appropriate value for led strips.
    """
    @spec typical_led_strip :: 0xFFB0F0
    def typical_led_strip, do: 0xFFB0F0

    @doc """
    Typical values for 8 mm "pixels on a string"
    """
    @spec typical_8mm_pixel :: 0xFFE08C
    def typical_8mm_pixel, do: 0xFFE08C

    @doc """
    same as `typical_8mm_pixel`
    """
    @spec typical_pixel_string :: 0xFFE08C
    def typical_pixel_string, do: 0xFFE08C

    @doc """
    To be used if you don't want to correct the color, i.e. all with full intensity (255, 255, 255)
    """
    @spec uncorrected_color :: 0xFFFFFF
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
    @spec candle :: 0xFF9329
    def candle, do: 0xFF9329

    @doc """
    Black Body Radiator: 2600K (255, 197, 143)
    """
    @spec tungsten_40w :: 0xFFC58F
    def tungsten_40w, do: 0xFFC58F

    @doc """
    Black Body Radiator: 2850K (255, 214, 170)
    """
    @spec tungsten_100w :: 0xFFD6AA
    def tungsten_100w, do: 0xFFD6AA

    @doc """
    Black Body Radiator: 3200K (255, 241, 224)
    """
    @spec halogen :: 0xFFF1E0
    def halogen, do: 0xFFF1E0

    @doc """
    Black Body Radiator: 5200K (255, 250, 244)
    """
    @spec carbon_arc :: 0xFFFAF4
    def carbon_arc, do: 0xFFFAF4

    @doc """
    Black Body Radiator: 5400K (255, 255, 251)
    """
    @spec high_noon_sun :: 0xFFFFFB
    def high_noon_sun, do: 0xFFFFFB

    @doc """
    Black Body Radiator: 6000K (255, 255, 255)
    """
    @spec direct_sunlight :: 0xFFFFFF
    def direct_sunlight, do: 0xFFFFFF

    @doc """
    Black Body Radiator: 7000K (201, 226, 255)
    """
    @spec overcast_sky :: 0xC9E2FF
    def overcast_sky, do: 0xC9E2FF

    @doc """
    Black Body Radiator: 20000K (64, 156, 255)
    """
    @spec clear_blue_sky :: 0x409CFF
    def clear_blue_sky, do: 0x409CFF

    @doc """
    Gaseous Light Source: Warm (yellower) flourescent light bulbs, 0 K, (255, 244, 229)
    """
    @spec warm_fluorescent :: 0xFFF4E5
    def warm_fluorescent, do: 0xFFF4E5

    @doc """
    Gaseous Light Source: Standard flourescent light bulbs, 0 K, (244, 255, 250)
    """
    @spec standard_fluorescent :: 0xF4FFFA
    def standard_fluorescent, do: 0xF4FFFA

    @doc """
    Gaseous Light Source: Cool white (bluer) flourescent light bulbs, 0 K, (212, 235, 255)
    """
    @spec cool_white_fluorescent :: 0xD4EBFF
    def cool_white_fluorescent, do: 0xD4EBFF

    @doc """
    Gaseous Light Source: Full spectrum flourescent light bulbs, 0 K, (255, 244, 242)
    """
    @spec full_spectrum_fluorescent :: 0xFFF4F2
    def full_spectrum_fluorescent, do: 0xFFF4F2

    @doc """
    Gaseous Light Source: Grow light flourescent light bulbs, 0 K, (255, 239, 247)
    """
    @spec grow_light_fluorescent :: 0xFFEFF7
    def grow_light_fluorescent, do: 0xFFEFF7

    @doc """
    Gaseous Light Source: Black light flourescent light bulbs, 0 K, (167, 0, 255)
    """
    @spec black_light_fluorescent :: 0xA700FF
    def black_light_fluorescent, do: 0xA700FF

    @doc """
    Gaseous Light Source: Mercury vapor light bulbs, 0 K, (216, 247, 255)
    """
    @spec mercury_vapor :: 0xD8F7FF
    def mercury_vapor, do: 0xD8F7FF

    @doc """
    Gaseous Light Source: Sodium vapor light bulbs, 0 K, (255, 209, 178)
    """
    @spec sodium_vapor :: 0xFFD1B2
    def sodium_vapor, do: 0xFFD1B2

    @doc """
    Gaseous Light Source: Metal-halide light bulbs: 0 K, (242, 252, 255)
    """
    @spec metal_halide :: 0xF2FCFF
    def metal_halide, do: 0xF2FCFF

    @doc """
    Gaseous Light Source: High-pressure sodium light bulbs, 0 K, (255, 183, 76)
    """
    @spec high_pressure_sodium :: 0xFFB74C
    def high_pressure_sodium, do: 0xFFB74C

    @doc """
    Uncorrected temperature, (255, 255, 255)
    """
    @spec uncorrected_temperature :: 0xFFFFFF
    def uncorrected_temperature, do: 0xFFFFFF
  end

  @doc """
  This function allows to combine several aspects of corrections together to a single
  correction.

  The elements are:
  * scale: Whether we want to have the full intensity (default 255, i.e. full intensity)
  * color_correction: Probably one of the corrections defined in
    `Fledex.Color.Correction.Color`
  * temperature_correction: Probably one of the corrections defined in
    `Fledex.Color.Correction.Temperature`
  """
  @spec define_correction(byte, Types.colorint(), Types.colorint()) :: Types.rgb()
  def define_correction(scale \\ 255, color_correction, temperature_correction)

  def define_correction(scale, color_correction, temperature_correction) when scale > 0 do
    %RGB{r: ccr, g: ccg, b: ccb} = RGB.new(color_correction)
    %RGB{r: tcr, g: tcg, b: tcb} = RGB.new(temperature_correction)

    r = calculate_single_color_correction(scale, ccr, tcr)
    g = calculate_single_color_correction(scale, ccg, tcg)
    b = calculate_single_color_correction(scale, ccb, tcb)

    {r, g, b}
  end

  def define_correction(_scale, _color_correction, _temperature_correction) do
    {0, 0, 0}
  end

  @doc """
  This defines a color correction without correction. I.e. the rgb colors will be with
  full brightness `{255, 255, 255}`
  """
  @spec no_color_correction() :: Types.rgb()
  def no_color_correction do
    # yes we could hard code this, but this is rarely used and therefore not performance
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
