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
end

defimpl Fledex.Color, for: Integer do
  alias Fledex.Color.Types

  @spec to_colorint(Types.colorint()) :: Types.colorint()
  def to_colorint(colorint), do: colorint
end

defimpl Fledex.Color, for: Atom do
  alias Fledex.Color.Names
  alias Fledex.Color.Types

  @black 0x000000
  @doc """
  this fucntion tries to lookup the atom in the various
  color modules and return it as a `colorint`

  If no module can be found with the atom name then black will be returned (`0x000000`)
  """
  @spec to_colorint(atom) :: Types.colorint()
  def to_colorint(color_name) do
    Names.info(color_name, :hex) || @black
  end
end

defimpl Fledex.Color, for: Map do
  alias Fledex.Color
  alias Fledex.Color.Types

  @spec to_colorint(map) :: Types.colorint()
  def to_colorint(%{rgb: rgb}), do: Color.to_colorint(rgb)
end
