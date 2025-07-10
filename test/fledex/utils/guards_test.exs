# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Utils.GuardsTest do
  use ExUnit.Case

  import Fledex.Utils.Guards

  def create_in_range_case(line) do
    line
    |> String.split(",")
    |> Enum.map(fn item -> convert!(item) end)
    |> List.to_tuple()
  end

  def convert!("t"), do: true
  def convert!("true"), do: true
  def convert!("f"), do: false
  def convert!("false"), do: false
  def convert!(num), do: String.to_integer(num)

  describe "Test is_in_range" do
    setup do
      cases =
        File.read!("test/fledex/utils/in_range_guard_cases.csv")
        |> String.split("\n")
        |> Enum.reject(fn line ->
          String.length(String.trim(line)) == 0
        end)
        |> Enum.map(fn line -> create_in_range_case(line) end)

      %{cases: cases}
    end

    test "test all combinations", %{cases: cases} do
      Enum.each(cases, fn {value, inverted, min, max, expected} ->
        case value do
          _x when is_in_range(value, inverted, min, max) ->
            assert(expected)

          _x when not is_in_range(value, inverted, min, max) ->
            assert(not expected)
        end
      end)
    end
  end
end
