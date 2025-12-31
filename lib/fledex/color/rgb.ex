# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.RGB do
  @moduledoc """
  This module represents an RGB color. `Fledex` does commonly use a `{r, g, b}`-tuple, but
  this module makes the purpose more clear.

  It also provides the necessary conversion functions to the 0xrrggbb ([`colorint`](`t:Fledex.Color.Types.colorint/0`)) and`{r,g,b}` (tuple) representations.
  """
  import Bitwise

  alias Fledex.Color
  alias Fledex.Color.Types

  defstruct r: 0, g: 0, b: 0
  @type t :: %__MODULE__{r: 0..255, g: 0..255, b: 0..255}

  defimpl Fledex.Color do
    alias Fledex.Color.RGB

    @max_value 255

    @doc """
    Merges the rgb colors together to a single integer
    """
    @spec to_colorint(RGB.t()) :: Types.colorint()
    def to_colorint(%RGB{r: r, g: g, b: b} = _rgb) do
      (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)
    end
  end

  @doc """
  creates a new RGB structure from any kind of color structure
  """
  @spec new(Types.color()) :: t()
  def new({r, g, b} = _color), do: %__MODULE__{r: r, g: g, b: b}

  def new(color) when is_integer(color) do
    {r, g, b} = to_tuple(color)
    %__MODULE__{r: r, g: g, b: b}
  end

  def new(color) do
    Color.to_colorint(color)
    |> new()
  end

  @doc """
  Converts an `Fledex.Color.RGB` color to a rgb tuple
  """
  @spec to_tuple(t() | Types.color()) :: Types.rgb()
  def to_tuple(%__MODULE__{r: r, g: g, b: b} = _rgb) do
    {r, g, b}
  end

  def to_tuple(color) when is_integer(color) do
    r =
      color
      |> Bitwise.&&&(0xFF0000)
      |> Bitwise.>>>(16)

    g =
      color
      |> Bitwise.&&&(0x00FF00)
      |> Bitwise.>>>(8)

    b = color |> Bitwise.&&&(0x0000FF)

    {r, g, b}
  end

  def to_tuple(color) do
    Color.to_colorint(color)
    |> to_tuple()
  end
end
