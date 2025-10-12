# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.TNamesTest do
  use ExUnit.Case, async: false

  defmodule TestNames do
    @behaviour Fledex.Color.Names.Interface

    defguard is_color_name(name) when name == :maze

    def names do
      [:maze]
    end

    def colors do
      [
        %{
          index: 1,
          name: :maze,
          descriptive_name: "maze special color",
          hex: 0x747474,
          rgb: {0x74, 0x74, 0x74},
          hsl: {0, 0, 0},
          hsv: %Fledex.Color.HSV{h: 0, s: 0, v: 0},
          source: "",
          module: TestNames
        }
      ]
    end

    def info(:maze, :hex) do
      0x747474
    end

    def info(:maze, :all) do
      [color] = colors()
      color
    end

    def maze(what) do
      info(:maze, what)
    end
  end

  alias Fledex.Color.TNames

  def get_modules(modules_and_color) do
    Enum.map(modules_and_color, fn {module, _colors} -> module end)
  end

  describe "use names and config" do
    test "use once" do
      use TNames, colors: [:wiki, :css]
      assert length(TNames.modules_and_colors()) == 2
    end

    test "use multiple times" do
      use TNames, colors: [:wiki, :css]
      assert length(TNames.modules_and_colors()) == 2
      use TNames, colors: [:svg]
      assert length(TNames.modules_and_colors()) == 1
      use TNames, colors: []
      assert Enum.empty?(TNames.modules_and_colors())
    end

    test "colors parameter" do
      use TNames
      mac = TNames.modules_and_colors()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use TNames, colors: []
      mac = TNames.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use TNames, colors: :wiki
      mac = TNames.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use TNames, colors: :none
      mac = TNames.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use TNames, colors: [:wiki]
      mac = TNames.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use TNames, colors: [:none]
      mac = TNames.modules_and_colors()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use TNames, colors: [:wiki, Fledex.Color.Names.CSS]
      mac = TNames.modules_and_colors()
      assert length(mac) == 2
      assert get_modules(mac) == [Fledex.Color.Names.Wiki, Fledex.Color.Names.CSS]

      use TNames, colors: [TestNames]
      mac = TNames.modules_and_colors()
      assert length(mac) == 1
      assert get_modules(mac) == [TestNames]

      use TNames, colors: [:default]
      mac = TNames.modules_and_colors()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use TNames, colors: [:all]
      mac = TNames.modules_and_colors()
      assert length(mac) == 4

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG,
               Fledex.Color.Names.RAL
             ]
    end

    test "no colors definition" do
      use TNames, colors: :wiki
      assert Code.loaded?(Fledex.Color.TNames.Config)
      assert length(TNames.modules_and_colors()) == 1

      use TNames, colors: nil
      assert not Code.loaded?(Fledex.Color.TNames.Config)
      assert Enum.empty?(TNames.modules_and_colors())
    end

    test "specify non-existing module" do
      import ExUnit.CaptureLog

      assert capture_log(fn ->
               # <-- non-existant
               use TNames, colors: Test1
             end) =~ "Not a known color name"
    end

    test "specify color name module with wrong behaviour" do
      import ExUnit.CaptureLog

      defmodule Test2 do
      end

      assert capture_log(fn ->
               # <-- existant, but not implementing the behaviour
               use TNames, colors: Test2
             end) =~ "Not a known color name"
    end
  end

  describe "test apis" do
    test "names" do
      use TNames, colors: TestNames
      assert TNames.names() == [:maze]
    end

    defp get_name_starting_letter(color_map) do
      color_map
      |> Map.get(:name)
      |> Atom.to_string()
      |> String.first()
    end

    test "colors" do
      use TNames, colors: [:wiki, :ral]
      colors = TNames.colors()
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

      use TNames, colors: nil
      colors = TNames.colors()
      assert Enum.empty?(colors)
    end

    test "info" do
      use TNames, colors: TestNames
      assert TNames.info(:maze) == 0x747474
      assert TNames.info(:maze, :all) == TestNames.info(:maze, :all)

      use TNames, colors: nil
      assert TNames.info(:maze) == nil
      assert TNames.info(:maze, :all) == nil
    end

    test "guard" do
      use TNames
      assert TNames.is_color_name(:vermilion2) == true
      # all atoms are valid color names
      assert TNames.is_color_name(:non_existing) == true
      assert TNames.is_color_name(42) == false
    end
  end

  describe "color name utils" do
    test "modules" do
      alias Fledex.Color.Names.Utils
      assert length(Utils.modules()) == 4
    end
  end
end
