defmodule Fledex.Utils do
  import Bitwise

  def scale8(value, scale) do
    (value * scale) >>> 8
  end
  # We needed this function very rarely and could replace it with a version
  # where the +0/1 was always 1. Therefore removed it
  # def scale8_video(value, scale) do
  #   # TODO: I think we have a bug here. Therefore the tests are now failing
  #   # Before it was: ((value*scale) >>> 8) + if (value != 0 && scale != 0),
  #   # do: 1, else: 0
  #   ((value*scale) >>> 8) + if (value != 0 && scale != 0), do: 1, else: 0
  # end

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
