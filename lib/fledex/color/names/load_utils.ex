# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.LoadUtils do
  @moduledoc """
  Some utility functions that can help when loading color names from a CSV file
  """

  # This function is used by the Generator, but is not intended to be used otherwise
  # it is for loading the CSV files in a decently generic way
  @doc false
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
    |> Enum.map(fn color -> {color.name, color} end)
    |> Map.new()
  end

  defp line_splitter(index, line, opts) do
    separator = Keyword.get(opts, :separator, ",")
    split_opts = Keyword.get(opts, :split_opts, parts: 11)
    [index] ++ String.split(line, separator, split_opts)
  end

  @doc """
  Converts a string (can be even unicode) into an asci atom

  It performs the following steps:
  * normalizes the string (NFD form)
  * replaces any non-alpha-numeric characters with underscores (except at the start and end)
  * downcases it
  * converts it to an atom
  """
  def str2atom(name) do
    name
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-zA-Z0-9]/, " ")
    |> String.trim()
    |> String.replace(~r/\s+/, "_")
    |> String.downcase(:ascii)
    |> String.to_atom()
  end

  @doc """
  Converts a hex string (potentially with a `#` sign) into an integer
  """
  def hexstr2i(hex_string) do
    hex_string
    |> String.replace("#", "")
    |> Integer.parse(16)
    |> elem(0)
  end

  @doc """
  Converts an asci string representing a byte into that byte

  The value is interpreted as a value between 0 and 255 except in the following
  special cases:
  * `%`: If the string contains a trailing percent sign, then
        the value is interpreted as a percent and stretched onto a byte
  * `°`: If the string contains a trailing degree sign, then
        the value is interpreted degree between 0 and 359 and mapped to a byte
  """
  def a2b(value) do
    value =
      String.trim(value)
      |> String.replace("—", "0")

    case Float.parse(value) do
      {value, "%"} -> trunc(value / 100 * 255)
      {value, "°"} -> trunc(value / 359 * 255)
      {value, _other} -> value
    end
  end

  @doc """
  Converts an asci string with an integer into an integer.

  Any non-digit charaters will be removed before the conversion
  """
  def a2i(value) do
    value
    |> String.replace(~r/[^0-9]/, "")
    |> Integer.parse()
    |> elem(0)
  end
end
