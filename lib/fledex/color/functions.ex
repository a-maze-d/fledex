# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Functions do
  @moduledoc """
  A collection of color functions (namely rainbow and gradient)
  """
  import Bitwise

  alias Fledex.Color.Conversion.Rainbow
  alias Fledex.Color.HSV
  alias Fledex.Color.RGB
  alias Fledex.Color.Types

  @doc """
  This function creates a sequence of HSV values with the rainbow colors spread over `num_leds`
  leds.
  """
  @spec create_rainbow_circular_hsv(pos_integer, byte, boolean) :: list(Types.hsv())
  def create_rainbow_circular_hsv(num_leds, initial_hue \\ 0, reversed \\ false)
  def create_rainbow_circular_hsv(0, _initial_hue, _reversed), do: []

  def create_rainbow_circular_hsv(num_leds, initial_hue, reversed) do
    hue_change = div(65_535, num_leds)

    for n <- 0..(num_leds - 1)//1 do
      %HSV{h: initial_hue + step(reversed, (n * hue_change) >>> 8) &&& 0xFF, s: 240, v: 255}
    end
  end

  @doc """
  This function creates a sequence of RGB values with the rainbow colors

  The options are:
    * `:reversed`: The rainbow can go from red (start color) to blue (end color) or the other
      way around.
    * `:initial_hue`: The starting color in degree mapped to a byte (e.g. `0..255`
        corresponds to `0..258`). (default: 0)

  Additional options that can be specified are those specified in `hsv2rgb/2`
  """
  @spec create_rainbow_circular_rgb(pos_integer, keyword) :: list(Types.rgb())
  def create_rainbow_circular_rgb(num_leds, opts \\ []) do
    reversed = Keyword.get(opts, :reversed, false)
    initial_hue = Keyword.get(opts, :initial_hue, 0)
    conv_opts = Keyword.drop(opts, [:reversed, :initial_hue])

    create_rainbow_circular_hsv(num_leds, initial_hue, reversed)
    |> hsv2rgb(conv_opts)
  end

  @doc """
  This function creates a gradient from a `start_color` to an `end_color` spread over `num_leds`
  """
  @spec create_gradient_rgb(pos_integer, RGB.t(), RGB.t()) :: list(Types.rgb())
  def create_gradient_rgb(
        num_leds,
        %RGB{r: sr, g: sg, b: sb} = _start_color,
        %RGB{r: er, g: eg, b: eb} = _end_color
      )
      when num_leds > 0 do
    rdist87 = (er - sr) <<< 7
    gdist87 = (eg - sg) <<< 7
    bdist87 = (eb - sb) <<< 7

    steps = num_leds + 1
    rdelta = div(rdist87, steps) * 2
    gdelta = div(gdist87, steps) * 2
    bdelta = div(bdist87, steps) * 2

    r88 = sr <<< 8
    g88 = sg <<< 8
    b88 = sb <<< 8

    for n <- 1..(steps - 1) do
      %RGB{r: (r88 + rdelta * n) >>> 8, g: (g88 + gdelta * n) >>> 8, b: (b88 + bdelta * n) >>> 8}
    end
  end

  @doc """
  A conversion function that can be configured to have the desired behavior. Several
  implementations exist for the hsv2rgb conversion with slightly differen results.

  The options are:
  * `:conversion_functions`: the desired conversion function
      (default:`Fledex.Color.Conversion.Rainbow.hsv2rgb/2`)
  * `:color_correction`: allows for a color correction, see
      `color_correction_none/1` (default) and `color_correction_g2`
  """
  @spec hsv2rgb(list(Types.hsv()), keyword) :: list(Types.rgb())
  def hsv2rgb(leds, opts \\ []) do
    conversion_function = Keyword.get(opts, :conversion_function, &Rainbow.hsv2rgb/2)
    color_correction = Keyword.get(opts, :color_correction, &color_correction_none/1)

    Enum.map(leds, fn hsv ->
      conversion_function.(hsv, color_correction)
    end)
  end

  @doc """
  Color correction function: that halfs the intensity of green
  """
  @spec color_correction_g2(Types.rgb()) :: Types.rgb()
  def color_correction_g2({r, g, b}) do
    {r, g >>> 2, b}
  end

  @doc """
  Color correction function: that doesn't do anything, i.e. keeps the colors as they are
  """
  @spec color_correction_none(Types.rgb()) :: Types.rgb()
  def color_correction_none({r, g, b}) do
    {r, g, b}
  end

  # MARK: private helper functions
  @spec step(boolean, byte) :: integer
  # Depending whether we want to reverse we move hue forward or backwards
  defp step(reversed, hue)
  defp step(false, hue), do: hue
  defp step(true, hue), do: -hue
end
