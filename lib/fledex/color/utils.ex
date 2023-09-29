defmodule Fledex.Color.Utils do
  import Bitwise

  alias Fledex.Color.Names
  alias Fledex.Color.Types

  @spec frac8(0..255, 0..255) :: 0..255
  @doc """
    calculate a fraction mapped to a 8bit range
  """
  def frac8(n, d) do
    trunc((n * 256) / d)
  end

  @spec scale8_video_addition(boolean, 0..255, 0..255) :: 0|1
  defp scale8_video_addition(false, _value, _scale), do: 0
  defp scale8_video_addition(true, value, scale) when value != 0 and scale != 0, do: 1
  defp scale8_video_addition(_addition, _value, _scale), do: 0

  @spec scale8(0..255, 0..255, boolean) :: 0..255
  def scale8(value, scale, video \\ false)
  def scale8(0, _scale, _video), do: 0
  def scale8(value, scale, video) do
    addition = scale8_video_addition(video, value, scale)
    ((value * scale) >>> 8) + addition
  end

  @spec nscale8(Types.rgb, 0..255, boolean) :: Types.rgb
  def nscale8(rgb, scale, video \\ true)
  def nscale8({r, g, b}, scale, video) when is_integer(scale) do
    nscale8({r, g, b}, {scale, scale, scale}, video)
  end
  @spec nscale8(Types.rgb, Types.rgb, boolean) :: Types.rgb
  def nscale8({r, g, b}, {sr, sg, sb}, video) do
    {scale8(r, sr, video), scale8(g, sg, video), scale8(b, sb, video)}
  end
  @spec nscale8(Types.colorint, Types.rgb, boolean) :: Types.colorint
  def nscale8(color, rgb, video) do
    split_into_subpixels(color)
      |> nscale8(rgb, video)
      |> combine_subpixels()
  end

  @doc """
  Splits the rgb-integer value into it's subpixels and returns an
  `{r, g, b}` tupel
  """
  @spec split_into_subpixels(Types.colorint) :: Types.rgb
  def split_into_subpixels(elem) do
    r = elem |> Bitwise.&&&(0xFF0000) |> Bitwise.>>>(16)
    g = elem |> Bitwise.&&&(0x00FF00) |> Bitwise.>>>(8)
    b = elem |> Bitwise.&&&(0x0000FF)
    {r, g, b}
  end

  @doc """
  This function adds the given subpixels `[{r1, g1, b1}, {r2, g2, b2}, ...]` together.
  The result {r1+r2+..., g1+g2+..., b1+b2+...} is probably outside of the standard
  8bit range and will have to be rescaled
  """
  @spec add_subpixels(list(Types.rgb)) :: {pos_integer, pos_integer, pos_integer}
  def add_subpixels(elems) do
    Enum.reduce(elems, {0, 0, 0}, fn {r, g, b}, {accr, accg, accb} ->
      {r + accr, g + accg, b + accb}
    end)
  end

  @spec avg({pos_integer, pos_integer, pos_integer}, pos_integer) :: Types.rgb
  @doc """
  This function rescales the rgb values with count (default: 1) and combines
  them to a single integer
  """
  def avg({r, g, b}, count \\ 1) do
    r = Kernel.trunc(r / count)
    g = Kernel.trunc(g / count)
    b = Kernel.trunc(b / count)
    {r, g, b}
  end

  @spec cap({pos_integer, pos_integer, pos_integer}, Range.t) :: Types.rgb
  def cap({r, g, b}, min_max \\ 0..255) do
    {do_cap(r, min_max), do_cap(g, min_max), do_cap(b, min_max)}
  end

  @spec do_cap(pos_integer, Range.t) :: pos_integer
  defp do_cap(value, min..max) when min <= max do
    case value do
      value when value < min -> min
      value when value > max -> max
      value -> value
    end
  end

  @spec combine_subpixels(Types.rgb) :: Types.colorint
  def combine_subpixels({r, g, b}) do
    (r<<<16) + (g<<<8) + b
  end

  @spec convert_to_subpixels((Types.colorint | atom | Types.rgb | %{rgb: Types.rgb})) :: Types.rgb
  def convert_to_subpixels(rgb) do
    case rgb do
      %{rgb: x} -> x
      x when is_atom(x) -> Names.get_color_sub_pixels(x)
      x when is_integer(x) -> split_into_subpixels(x)
      x -> x
    end
  end
end
