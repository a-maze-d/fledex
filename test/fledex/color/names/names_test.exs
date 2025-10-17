# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.NamesTest do
  use ExUnit.Case, async: false

  require Fledex.Color.Names
  alias Fledex.Color.Names

  alias Fledex.Config

  describe "test apis" do
    test "names" do
      use Config, colors: TestColorModule
      assert Names.names() == [:maze]
    end

    defp get_name_starting_letter(color_map) do
      color_map
      |> Map.get(:name)
      |> Atom.to_string()
      |> String.first()
    end

    test "colors" do
      use Config, colors: [:wiki, :ral]
      colors = Names.colors()
      assert Enum.empty?(colors) == false
      assert List.first(colors) |> get_name_starting_letter() == "a"
      assert List.last(colors) |> get_name_starting_letter() == "z"

      assert Enum.reduce(colors, {nil, nil}, fn color, {left, right} ->
               case color[:module] do
                 Fledex.Color.Names.RAL -> {left, Fledex.Color.Names.RAL}
                 Fledex.Color.Names.Wiki -> {Fledex.Color.Names.Wiki, right}
                 _ -> {left, right}
               end
             end) == {Fledex.Color.Names.Wiki, Fledex.Color.Names.RAL}

      use Config, colors: nil
      colors = Names.colors()
      assert Enum.empty?(colors)
    end

    test "info" do
      use Config, colors: TestColorModule
      assert Names.info(:maze) == 0x747474
      assert Names.info(:maze, :hex) == 0x747474
      assert Names.info(:maze, :all) == TestColorModule.info(:maze, :all)

      use Config, colors: nil
      assert Names.info(:maze) == nil
      assert Names.info(:maze, :all) == nil

      # invalid parameters
      assert Names.info(:maze, "hex") == nil
      assert Names.info("maze", :hex) == nil
    end

    test "guard" do
      use Config
      assert Names.is_color_name(:vermilion2) == true
      # all atoms are valid color names
      assert Names.is_color_name(:non_existing) == true
      assert Names.is_color_name(42) == false
    end
  end

  describe "color name utils" do
    test "modules" do
      alias Fledex.Config
      assert length(Config.known_color_modules()) == 4
    end
  end
end
