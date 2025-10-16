# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.NamesTest do
  use ExUnit.Case, async: false

  alias Fledex.Color.Names

  def get_modules(modules_and_color) do
    Enum.map(modules_and_color, fn {module, _colors} -> module end)
  end

  describe "use names and config" do
    test "use once" do
      use Names, colors: [:wiki, :css]
      assert length(Names.modules_and_colors()) == 2
    end

    test "use multiple times" do
      use Names, colors: [:wiki, :css]
      assert length(Names.modules_and_colors()) == 2
      use Names, colors: [:svg]
      assert length(Names.modules_and_colors()) == 1
      use Names, colors: []
      assert Enum.empty?(Names.modules_and_colors())
    end

    test "colors parameter" do
      use Names
      mac = Names.modules_and_colors()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use Names, colors: []
      mac = Names.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Names, colors: :wiki
      mac = Names.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use Names, colors: :none
      mac = Names.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Names, colors: [:wiki]
      mac = Names.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use Names, colors: [:none]
      mac = Names.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Names, colors: [:wiki, Fledex.Color.Names.CSS]
      mac = Names.modules_and_colors()
      assert length(mac) == 2
      assert get_modules(mac) == [Fledex.Color.Names.Wiki, Fledex.Color.Names.CSS]

      use Names, colors: [TestColorModule]
      mac = Names.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [TestColorModule]

      use Names, colors: [:default]
      mac = Names.modules_and_colors()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use Names, colors: [:all]
      mac = Names.modules_and_colors()
      assert length(mac) == 4

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG,
               Fledex.Color.Names.RAL
             ]
    end

    test "no colors definition" do
      use Names, colors: :wiki
      assert Fledex.Config.exists?()
      assert length(Names.modules_and_colors()) == 1

      use Names, colors: nil
      assert not Fledex.Config.exists?()
      assert Enum.empty?(Names.modules_and_colors())
    end

    # it's a bit unclear to me where the logging is going :-(
    test "specify non-existing module" do
      import ExUnit.CaptureLog
      require Logger

      assert capture_log(fn ->
               # non-existant color module
               Code.compile_string("""
                 alias Fledex.Color.Names
                 Code.ensure_loaded(Names)
                 use Names, colors: Test1
               """)
             end) =~ "Not a known color name"
    end

    test "specify color name module with wrong behaviour" do
      import ExUnit.CaptureLog

      assert capture_log(fn ->
               # existant, but not implementing the behaviour
               Code.compile_string("""
                   alias Fledex.Color.Names
                   Code.ensure_loaded(Names)

                   defmodule Test2 do
                   end

                   use Names, colors: Test2
               """)
             end) =~ "Not a known color name"
    end
  end

  describe "test apis" do
    test "names" do
      use Names, colors: TestColorModule
      assert Names.names() == [:maze]
    end

    defp get_name_starting_letter(color_map) do
      color_map
      |> Map.get(:name)
      |> Atom.to_string()
      |> String.first()
    end

    test "colors" do
      use Names, colors: [:wiki, :ral]
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

      use Names, colors: nil
      colors = Names.colors()
      assert Enum.empty?(colors)
    end

    test "info" do
      use Names, colors: TestColorModule
      assert Names.info(:maze) == 0x747474
      assert Names.info(:maze, :all) == TestColorModule.info(:maze, :all)

      use Names, colors: nil
      assert Names.info(:maze) == nil
      assert Names.info(:maze, :all) == nil
    end

    test "guard" do
      use Names
      assert Names.is_color_name(:vermilion2) == true
      # all atoms are valid color names
      assert Names.is_color_name(:non_existing) == true
      assert Names.is_color_name(42) == false
    end
  end

  describe "color name utils" do
    test "modules" do
      alias Fledex.Color.Names.Utils
      assert length(Utils.modules()) == 4
    end
  end
end
