# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defprotocol Fledex.Color do
  @moduledoc """
  Protocol that can be implemented to convert from some kind of color representation

  The conversionto can either happen to a color integer (`colorint`) with 3x 8bit or to a 3 element `{r, g, n}` tuple
  representing the colors `r`, `g`, and `b`.
  """

  alias Fledex.Color.Types

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

  alias Fledex.Color.Types

  @max_value 255
  @doc """
  Merges the rgb colors together to a single integer
  """
  @spec to_colorint(Types.rgb()) :: Types.colorint()
  def to_colorint({r, g, b}) do
    (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)
  end

  @doc """
  This function does nothing, since the data is already in the correct format
  """
  @spec to_rgb(Types.rgb()) :: Types.rgb()
  def to_rgb(rgb), do: rgb
end

defimpl Fledex.Color, for: Integer do
  alias Fledex.Color.Types

  @spec split_into_subpixels(Types.colorint()) :: Types.rgb()
  defp split_into_subpixels(elem) do
    r = elem |> Bitwise.&&&(0xFF0000) |> Bitwise.>>>(16)
    g = elem |> Bitwise.&&&(0x00FF00) |> Bitwise.>>>(8)
    b = elem |> Bitwise.&&&(0x0000FF)
    {r, g, b}
  end

  @spec to_colorint(Types.colorint()) :: Types.colorint()
  def to_colorint(colorint), do: colorint

  @spec to_rgb(Types.colorint()) :: Types.rgb()
  def to_rgb(colorint), do: split_into_subpixels(colorint)
end

defimpl Fledex.Color, for: Atom do
  alias Fledex.Color.Names
  alias Fledex.Color.Types

  @doc """
  this fucntion tries to lookup the atom in the various
  color modules and return it as a `colorint`

  If no module can be found with the atom name then black will be returned (`0x000000`)
  """
  @spec to_colorint(atom) :: Types.colorint()
  def to_colorint(color_name) do
    get_color(color_name, :hex)
  end

  @doc """
  this fucntion tries to lookup the atom in the various
  color modules and return it as an `{r, g, b}` tuple

  If no module can be found with the atom name then black will be returned (`{0, 0, 0}`)
  """
  @spec to_rgb(atom) :: Types.rgb()
  def to_rgb(color_name) do
    get_color(color_name, :rgb)
  end

  @black 0x000000
  @black_rgb {0, 0, 0}
  @doc false
  # get the color from the named color
  @spec get_color(atom, :hex) :: Types.colorint()
  @spec get_color(atom, :rgb) :: Types.rgb()
  defp get_color(color_name, type) do
    color = Names.info(color_name, type)

    case {color, type} do
      {nil, :hex} -> @black
      {nil, :rgb} -> @black_rgb
      {color, _type} -> color
    end
  end
end

defimpl Fledex.Color, for: Map do
  alias Fledex.Color.Types

  @spec to_colorint(map) :: Types.colorint()
  def to_colorint(%{rgb: rgb}), do: Fledex.Color.to_colorint(rgb)

  @spec to_rgb(map) :: Types.rgb()
  def to_rgb(%{rgb: rgb}), do: Fledex.Color.to_rgb(rgb)
end
