# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.LoadUtils do
  @moduledoc """
  Some utility functions that can help when loading color names from a CSV file
  """

  alias Fledex.Color.Names.Types

  @doc """
  This function is used by the Generator, but is not intended to be used otherwise it is for loading the CSV files in a decently generic way.

  You have to specify the following parameters:
  * `filename` (mandatory): The color file you want to process
  * `converter`(mandatory): This is a function needs to do the conversion from the different parts of a line into a [`color_struct_t`](`t:Fledex.Color.Names.Types.color_struct_t/0`) structure.

  You can in addition specify the following options:
  * `name_pattern` (default: `~r/^.*$/i`): which names you want to actually want to load. Any `descriptive_name` that does not match this pattern will be dropped. You can for example only load the rows starting with an `a`.
  * `drop` (default: 1): how many header rows should be dropped. This allows to remove the header in a CSV file.
  * `splitter_opts`(default: []): The ops that will be used when splitting a line into the different parts. On one side it should contain the `:separator` (defaults to `,` as used in a proper CSV) and any [`split_opts`](https://hexdocs.pm/elixir/String.html#t:split_opts/0) as used by `String.split/3`.
  * `module`(default: :unknown): The name of the module that created the color map. This will automatically be added to the [`color_struct_t`](`t:Fledex.Color.Names.Types.color_struct_t/0`) structure.
  * `comment_pattern` (default: `~r/^s*#.*$/`):  A pattern that will filter out any lines defined as comment lines (similar to code where the line might start with a `#`).
  """
  @spec load_color_file(String.t(), ([String.t() | integer] -> Types.color_struct_t()), keyword) ::
          %{atom => Types.color_struct_t()}
  def load_color_file(
        filename,
        converter,
        opts
      ) do
    name_pattern = Keyword.get(opts, :name_pattern, ~r/^.*$/i)
    drop = Keyword.get(opts, :drop, 1)
    splitter_opts = Keyword.get(opts, :splitter_opts, [])
    module = Keyword.get(opts, :module, :unknown)
    comment_pattern = Keyword.get(opts, :comment_pattern, ~r/^s*#.*$/)

    # Example how the structure of the CSV might look like
    # Name, Hex (RGB), Red (RGB), Green (RGB), Blue (RGB), Hue (HSL/HSV), Satur. (HSL),
    #   Light (HSL), Satur.(HSV), Value (HSV), Source
    filename
    |> File.stream!()
    # drop the first columns (like the header line)
    |> Stream.drop(drop)
    |> Stream.reject(fn line -> String.match?(line, comment_pattern) end)
    |> Stream.with_index()
    |> Stream.map(fn {line, index} -> line_splitter(index, line, splitter_opts) end)
    |> Stream.map(fn line -> converter.(line) end)
    |> Stream.map(fn map -> Map.put(map, :module, module) end)
    |> Stream.filter(fn element ->
      String.match?(Atom.to_string(element.name), name_pattern)
    end)
    |> Enum.map(fn color -> {color.name, color} end)
    |> Map.new()
  end

  @spec line_splitter(integer, String.t(), keyword) :: [String.t() | integer]
  defp line_splitter(index, line, opts) do
    separator = Keyword.get(opts, :separator, ",")
    split_opts = Keyword.get(opts, :split_opts, [])
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
  @spec str2atom(String.t()) :: atom
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
  @spec hexstr2i(String.t()) :: integer
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
  @spec a2b(String.t()) :: byte()
  def a2b(value) do
    value =
      String.trim(value)
      |> String.replace("—", "0")

    case Float.parse(value) do
      {value, "%"} -> trunc(value / 100 * 255)
      {value, "°"} -> trunc(value / 359 * 255)
      {value, _other} -> trunc(value)
    end
  end

  @doc """
  Converts an asci string with an integer into an integer.

  Any non-digit charaters will be removed before the conversion
  """
  @spec a2i(String.t()) :: integer
  def a2i(value) do
    value
    |> String.replace(~r/[^0-9]/, "")
    |> Integer.parse()
    |> elem(0)
  end
end
