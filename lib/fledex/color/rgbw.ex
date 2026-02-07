# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.RGBW do
  @moduledoc """
  This module represents an RGBW color. `Fledex` does commonly use a `{r, g, b}`-tuple, but
  this module allows to also set the white (`:w1`) or even a secondary white color (`:w2`)
  led commonly found in modern led strips
  (e.g. [WS2813B-RGBW](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2813-RGBW-datasheet.pdf)).

  It also provides the necessary conversion functions to the `0xw2w2w1w1rrggbb`
  ([`colorint`](`t:Fledex.Color.Types.colorint/0`)) and`{r,g,b}` (tuple) representations.
  """
  import Bitwise

  alias Fledex.Color
  alias Fledex.Color.RGB
  alias Fledex.Color.Types

  defstruct r: 0, g: 0, b: 0, w1: 0, w2: 0
  @type t :: %__MODULE__{r: byte(), g: byte(), b: byte(), w1: byte(), w2: byte()}

  defimpl Fledex.Color do
    alias Fledex.Color.RGBW

    @max_value 255

    @doc """
    Merges the rgbw1w2 colors together to a single integer
    """
    @spec to_colorint(RGBW.t()) :: Types.colorint()
    def to_colorint(%RGBW{r: r, g: g, b: b, w1: w1, w2: w2} = _rgbw) do
      (min(w2, @max_value) <<< 32) + (min(w1, @max_value) <<< 24) + (min(r, @max_value) <<< 16) +
        (min(g, @max_value) <<< 8) + min(b, @max_value)
    end
  end

  @doc """
  creates a new RGB structure from any kind of color structure
  """
  @spec new(Types.color()) :: t()
  def new({r, g, b} = _color), do: %__MODULE__{r: r, g: g, b: b}

  def new(color) when is_integer(color) do
    {r, g, b} = to_tuple(color)

    w1 =
      color
      |> Bitwise.&&&(0xFF000000)
      |> Bitwise.>>>(24)

    w2 =
      color
      |> Bitwise.&&&(0xFF00000000)
      |> Bitwise.>>>(32)

    %__MODULE__{r: r, g: g, b: b, w1: w1, w2: w2}
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
    RGB.to_tuple(color)
  end

  def to_tuple(color) do
    Color.to_colorint(color)
    |> to_tuple()
  end
end
