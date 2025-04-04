# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Utils do
  @moduledoc """
  Most functions are reimplementations from FastLED. Here is a detailed
  explanation of those functions:
  https://github.com/FastLED/FastLED/wiki/High-performance-math
  """
  import Fledex.Color.Names.Guards

  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.Names
  alias Fledex.Color.Types

  # @max_value 255
  # @doc """
  # This function converts a color to a single (color) integer value
  # """
  # @spec to_colorint(Types.color()) :: Types.colorint()
  # def to_colorint({r, g, b} = _color),
  #   do: (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)

  # def to_colorint(color) when is_integer(color), do: color
  # def to_colorint(color) when is_color_name(color), do: apply(Names, color, [:hex])

  @doc """
  This function splits a color into it's rgb components
  """
  @spec to_rgb(Types.color() | %{rgb: Types.rgb()} | %{rgb: Types.colorint()}) :: Types.rgb()
  def to_rgb(%{rgb: x} = _color), do: to_rgb(x)
  def to_rgb({r, g, b} = _color), do: {r, g, b}
  def to_rgb(color) when is_color_name(color), do: apply(Names, color, [:rgb])
  def to_rgb(color) when is_integer(color), do: CalcUtils.split_into_subpixels(color)
end
