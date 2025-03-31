# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.LoadUtils do
  import Bitwise

  def load_color_file(
        names_file,
        names_pattern,
        drop,
        splitter_opts,
        converter,
        module
      ) do
    # Example how the structure of the CSV might look like
    # Name, Hex (RGB), Red (RGB), Green (RGB), Blue (RGB), Hue (HSL/HSV), Satur. (HSL),
    #   Light (HSL), Satur.(HSV), Value (HSV), Source
    names_file
    |> File.stream!()
    # drop the first columns (like the header line)
    |> Stream.drop(drop)
    |> Stream.with_index()
    |> Stream.map(fn {line, index} -> line_splitter(index, line, splitter_opts) end)
    |> Stream.map(fn line -> converter.(line) end)
    |> Stream.map(fn map -> Map.put(map, :module, module) end)
    |> Stream.filter(fn element -> String.match?(element.descriptive_name, names_pattern) end)
    |> Enum.to_list()
  end

  def line_splitter(index, line, opts) do
    separator = Keyword.get(opts, :separator, ",")
    split_opts = Keyword.get(opts, :split_opts, parts: 11)
    [index] ++ String.split(line, separator, split_opts)
  end

  def convert_to_atom(name) do
    name
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-zA-Z0-9]/, " ")
    |> String.trim()
    |> String.replace(~r/\s+/, "_")
    |> String.downcase(:ascii)
    |> String.to_atom()
  end

  def clean_and_convert(hex_string) do
    hex_string = String.replace(hex_string, "#", "")
    {hex_int, _rest} = Integer.parse(hex_string, 16)
    hex_int
  end

  def to_byte(value) do
    value =
      String.trim(value)
      |> String.replace("—", "0")

    case Float.parse(value) do
      {value, "%"} -> trunc(value / 100 * 255)
      {value, "°"} -> trunc(value / 360 * 255)
      {value, _other} -> value
    end
  end

  def a2i(value) do
    value = clean(value)
    {int, _rest} = Integer.parse(value)
    int
  end

  def clean(integer_string) do
    String.replace(integer_string, ~r/[^0-9]/, "")
  end

  @max_value 255
  def to_colorint({r, g, b} = _color) do
    (min(r, @max_value) <<< 16) + (min(g, @max_value) <<< 8) + min(b, @max_value)
  end
end
