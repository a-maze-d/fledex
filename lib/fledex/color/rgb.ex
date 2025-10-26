# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.RGB do
  import Bitwise

  alias Fledex.Color
  alias Fledex.Color.Types

  defstruct r: 0, g: 0, b: 0
  @type t :: %__MODULE__{r: 0..255, g: 0..255, b: 0..255}

  @doc """
  creates a new RGB structure from any kind of color structure
  """
  @spec new(Types.color()) :: t()
  def new({r, g, b} = _color), do: %__MODULE__{r: r, g: g, b: b}

  def new(color) when is_integer(color) do
    r = color |> Bitwise.&&&(0xFF0000) |> Bitwise.>>>(16)
    g = color |> Bitwise.&&&(0x00FF00) |> Bitwise.>>>(8)
    b = color |> Bitwise.&&&(0x0000FF)
    %__MODULE__{r: r, g: g, b: b}
  end

  def new(color) do
    Color.to_colorint(color)
    |> new()
  end

  @spec to_tuple(t()) :: Types.rgb()
  def to_tuple(%__MODULE__{r: r, g: g, b: b} = _rgb) do
    {r, g, b}
  end

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
end
