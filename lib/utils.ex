defmodule Fledex.Utils do
  import Bitwise

  defp scale8_video_addition(false, _value, _scale), do: 0
  defp scale8_video_addition(true, value, scale) when value != 0 and scale != 0, do: 1
  defp scale8_video_addition(_, _, _), do: 0

  def scale8(value, scale, video \\ false)
  def scale8(0, _scale, _video), do: 0
  def scale8(value, scale, video) do
    addition = scale8_video_addition(video, value, scale)
    ((value * scale) >>> 8) + addition
  end

  def nscale8(rgb, scale, video \\ true)
  def nscale8({r,g,b}, scale, video) when is_integer(scale) do
    nscale8({r,g,b}, {scale, scale, scale}, video)
  end
  def nscale8({r,g,b}, {sr,sg,sb}, video) do
    {scale8(r, sr, video), scale8(g, sg, video), scale8(b, sb, video)}
  end

  @doc """
  Splits the rgb-integer value into it's subpixels and returns an
  `{r,g,b}` tupel
  """
  def split_into_subpixels(elem) do
    r = elem |> Bitwise.&&&(0xFF0000) |> Bitwise.>>>(16)
    g = elem |> Bitwise.&&&(0x00FF00) |> Bitwise.>>>(8)
    b = elem |> Bitwise.&&&(0x0000FF)
    {r, g, b}
  end

  @doc """
  This function adds the given subpixels `[{r1,g1,b1}, {r2,g2,b2}, ...]` together.
  The result {r1+r2+..., g1+g2+..., b1+b2+...} is probably outside of the standard
  8bit range and will have to be rescaled
  """
  def add_subpixels(elems) do
    Enum.reduce(elems, {0,0,0}, fn {r,g,b}, {accr, accg, accb} ->
      {r+accr, g+accg, b+accb}
    end)
  end

  @doc """
  This function rescales the rgb values with count (default: 1) and combines
  them to a single integer
  """
  def avg_and_combine({r,g,b}, count \\ 1) do
    r = Kernel.trunc(r/count)
    g = Kernel.trunc(g/count)
    b = Kernel.trunc(b/count)
    (r<<<16) + (g<<<8) + b
  end
end
