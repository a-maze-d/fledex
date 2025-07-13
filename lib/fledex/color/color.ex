# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defprotocol Fledex.Color do
  alias Fledex.Color.Types

  @moduledoc """
  Protocol that can be implemented to convert from some kind of color representation
  to a color integer (`colorint`) with 3x8bit or to a 3 element tuple representing the colors
  `r`, `g`, and `b`.
  """

  # Note: the following function will result in some warnings with ElixirLS
  #       with the command line dialyzer it's not an issue. Therefore I disabled
  #       the dializer in ElixirLS

  @doc "convert an abstract color to a concrete colorint"
  @spec to_colorint(term) :: Types.colorint()
  def to_colorint(color)

  @doc "convert an abstract color to a concrete rgb tuple"
  @spec to_rgb(term) :: Types.rgb()
  def to_rgb(color)
end

defimpl Fledex.Color, for: Tuple do
  import Bitwise

  @max_value 255
  def to_colorint({r, g, b}) do
    (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)
  end

  def to_rgb({r, g, b}), do: {r, g, b}
end

defimpl Fledex.Color, for: Integer do
  alias Fledex.Color.Types

  @doc """
  Splits the rgb-integer value into it's subpixels and returns an
  `{r, g, b}` tupel
  """
  @spec split_into_subpixels(Types.colorint()) :: Types.rgb()
  def split_into_subpixels(elem) do
    r = elem |> Bitwise.&&&(0xFF0000) |> Bitwise.>>>(16)
    g = elem |> Bitwise.&&&(0x00FF00) |> Bitwise.>>>(8)
    b = elem |> Bitwise.&&&(0x0000FF)
    {r, g, b}
  end

  def to_colorint(colorint), do: colorint
  def to_rgb(colorint), do: split_into_subpixels(colorint)
end

defimpl Fledex.Color, for: Atom do
  def to_colorint(color_name), do: apply(Fledex.Color.Names, color_name, [:hex])
  def to_rgb(color_name), do: apply(Fledex.Color.Names, color_name, [:rgb])
end

defimpl Fledex.Color, for: Map do
  def to_colorint(%{rgb: rgb}), do: Fledex.Color.to_colorint(rgb)
  def to_rgb(%{rgb: rgb}), do: Fledex.Color.to_rgb(rgb)
end
