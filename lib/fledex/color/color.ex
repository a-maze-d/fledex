# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defprotocol Fledex.Color do
  # Note: the following function will result in some warnings with ElixirLS
  #       with the command line dialyzer it's not an issue. Therefore I disabled
  #       the dializer in ElixirLS
  @doc "convert an abstract colour to a concrete colorint"
  def to_colorint(color)
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
  alias Fledex.Color.Conversion.CalcUtils

  def to_colorint(colorint), do: colorint
  def to_rgb(colorint), do: CalcUtils.split_into_subpixels(colorint)
end

defimpl Fledex.Color, for: Atom do
  def to_colorint(color_name), do: apply(Fledex.Color.Names, color_name, [:hex])
  def to_rgb(color_name), do: apply(Fledex.Color.Names, color_name, [:rgb])
end

defimpl Fledex.Color, for: Map do
  def to_colorint(%{rgb: rgb}), do: Fledex.Color.to_colorint(rgb)
  def to_rgb(%{rgb: rgb}), do: Fledex.Color.to_rgb(rgb)
end
