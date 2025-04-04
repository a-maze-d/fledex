# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defprotocol Fledex.Color do
  # Note: the following function will result in some warnings with ElixirLS
  #       with the command line dialyzer it's not an issue. Therefore I disabled
  #       the dializer in ElixirLS
  @doc "convert an abstract colour to a concrete colorint"
  def to_colorint(color)
end

defimpl Fledex.Color, for: Tuple do
  import Bitwise

  @max_value 255
  def to_colorint({r, g, b}) do
    (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)
  end
end

defimpl Fledex.Color, for: Integer do
  def to_colorint(colorint), do: colorint
end

defimpl Fledex.Color, for: Atom do
  def to_colorint(color_name), do: apply(Fledex.Color.Names, color_name, [:hex])
end
