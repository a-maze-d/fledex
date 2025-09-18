# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.CalcUtils do
  @moduledoc """
  Most functions are reimplementations from FastLED. Here is a detailed
  explanation of those functions:
  https://github.com/FastLED/FastLED/wiki/High-performance-math
  """
  @compile {:inline}
  import Bitwise
  alias Fledex.Color
  alias Fledex.Color.Types

  @doc """
    calculate a fraction mapped to a 8bit range
  """
  @spec frac8(0..255, 0..255) :: 0..255
  def frac8(n, d) do
    trunc(n * 256 / d)
  end

  @frac_48_128 trunc(48 * 256 / 128)
  @doc false
  def frac_48_128, do: @frac_48_128

  @frac_32_85 trunc(32 * 256 / 85)
  @doc false
  def frac_32_85, do: @frac_32_85

  @frac_24_128 trunc(24 * 257 / 128)
  @doc false
  def frac_24_128, do: @frac_24_128

  @frac_8_42 trunc(8 * 256 / 42)
  @doc false
  def frac_8_42, do: @frac_8_42

  @spec scale8_video_addition(boolean, 0..255, 0..255) :: 0 | 1
  defp scale8_video_addition(false, _value, _scale), do: 0
  defp scale8_video_addition(true, value, scale) when value != 0 and scale != 0, do: 1
  defp scale8_video_addition(_addition, _value, _scale), do: 0

  @doc """
  This function scales a value into a specific range. the video parameter
  indicates whether the returned value should be correct to not return 0
  """
  @spec scale8(0..255, 0..255, boolean) :: 0..255
  def scale8(value, scale, video \\ false)
  def scale8(0, _scale, _video), do: 0

  def scale8(value, scale, video) do
    addition = scale8_video_addition(video, value, scale)
    ((value * scale) >>> 8) + addition
  end

  @doc """
  same as #scale8, except that it does it for all 3 rgb value
  at the same time.
  """
  @spec nscale8(Types.rgb(), 0..255, boolean) :: Types.rgb()
  def nscale8(rgb, scale, video \\ true)

  def nscale8({r, g, b}, scale, video) when is_integer(scale) do
    nscale8({r, g, b}, {scale, scale, scale}, video)
  end

  @spec nscale8(Types.rgb(), Types.rgb(), boolean) :: Types.rgb()
  def nscale8({r, g, b}, {sr, sg, sb}, video) do
    {scale8(r, sr, video), scale8(g, sg, video), scale8(b, sb, video)}
  end

  @spec nscale8(Types.colorint(), Types.rgb(), boolean) :: Types.colorint()
  def nscale8(color, rgb, video) do
    Color.to_rgb(color)
    |> nscale8(rgb, video)
    |> Color.to_colorint()
  end

  @doc """
  This function adds the given subpixels `[{r1, g1, b1}, {r2, g2, b2}, ...]` together.
  The result {r1+r2+..., g1+g2+..., b1+b2+...} is probably outside of the standard
  8bit range and will have to be rescaled
  """
  @spec add_subpixels(list(Types.rgb())) :: {pos_integer, pos_integer, pos_integer}
  def add_subpixels(elems) do
    Enum.reduce(elems, {0, 0, 0}, fn {r, g, b}, {accr, accg, accb} ->
      {r + accr, g + accg, b + accb}
    end)
  end

  @doc """
  This function calculates the average of the given "rgb" values
  """
  @spec avg(list(Types.rgb())) :: Types.rgb()
  def avg(elems) do
    count = length(elems)
    {r, g, b} = add_subpixels(elems)
    {trunc(r / count), trunc(g / count), trunc(b / count)}
  end

  @doc """
  This function combines (adds) the given rgb values and caps them to the given range
  (by default 0..255)
  """
  @spec cap(list(Types.rgb()), Range.t()) :: Types.rgb()
  def cap(elems, min_max \\ 0..255) do
    {r, g, b} = add_subpixels(elems)
    {do_cap(r, min_max), do_cap(g, min_max), do_cap(b, min_max)}
  end

  @spec do_cap(pos_integer, Range.t()) :: pos_integer
  defp do_cap(value, min..max//1) when min <= max do
    case value do
      value when value < min -> min
      value when value > max -> max
      value -> value
    end
  end
end
