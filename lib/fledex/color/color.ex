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
  def to_rgb({r, g, b}), do: {r, g, b}
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

  def to_colorint(colorint), do: colorint
  def to_rgb(colorint), do: split_into_subpixels(colorint)
end

defimpl Fledex.Color, for: Atom do
  alias Fledex.Color.Types

  @spec color_name_modules :: list(module())
  defp color_name_modules do
    Fledex.Color.Names.color_name_modules()
    # we allow all types `:core` and `:optional`
    |> Enum.map(fn {module, _type, _name} -> module end)
  end

  @spec find_module(atom) :: module() | nil
  defp find_module(color_name) do
    Enum.reduce_while(color_name_modules(), nil, fn module, acc ->
      case function_exported?(module, color_name, 1) do
        true -> {:halt, module}
        false -> {:cont, acc}
      end
    end)
  end

  @black 0x000000
  @black_rgb {0, 0, 0}
  @spec get_color_from_module(module | nil, atom, :hex) :: Types.colorint()
  @spec get_color_from_module(module | nil, atom, :rgb) :: Types.rgb()
  defp get_color_from_module(nil, _color_name, :hex), do: @black
  defp get_color_from_module(nil, _color_name, :rgb), do: @black_rgb

  defp get_color_from_module(module, color_name, type) do
    apply(module, color_name, [type])
  end

  @spec get_color(atom, :hex) :: Types.colorint()
  @spec get_color(atom, :rgb) :: Types.rgb()
  defp get_color(color_name, type) do
    color_name
    |> find_module()
    |> get_color_from_module(color_name, type)
  end

  @doc """
  this fucntion tries to lookup the atom in the various
  color modules and return it as a `colorint`

  If no module can be found with the atom name then black will be returned (`0x000000`)
  """
  def to_colorint(color_name) do
    get_color(color_name, :hex)
  end

  @doc """
  this fucntion tries to lookup the atom in the various
  color modules and return it as an `{r, g, b}` tuple

  If no module can be found with the atom name then black will be returned (`{0, 0, 0}`)
  """
  def to_rgb(color_name) do
    get_color(color_name, :rgb)
  end
end

defimpl Fledex.Color, for: Map do
  def to_colorint(%{rgb: rgb}), do: Fledex.Color.to_colorint(rgb)
  def to_rgb(%{rgb: rgb}), do: Fledex.Color.to_rgb(rgb)
end
