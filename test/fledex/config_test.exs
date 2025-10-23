# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.ConfigTest do
  use ExUnit.Case

  alias Fledex.Color.Names
  alias Fledex.Config

  def get_modules(modules_and_color) do
    Enum.map(modules_and_color, fn {module, _colors} -> module end)
  end

  describe "use config: " do
    test "use once" do
      use Config, colors: [:wiki, :css]
      assert length(Config.configured_color_modules()) == 2
    end

    test "use multiple times" do
      use Config, colors: [:wiki, :css]
      assert length(Config.configured_color_modules()) == 2
      use Config, colors: [:svg]
      assert length(Config.configured_color_modules()) == 1
      use Config, colors: []
      assert Enum.empty?(Config.configured_color_modules())
    end

    test "with colors parameter" do
      use Config
      mac = Config.configured_color_modules()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use Config, colors: []
      mac = Config.configured_color_modules()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Config, colors: :wiki
      mac = Config.configured_color_modules()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use Config, colors: :none
      mac = Config.configured_color_modules()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Config, colors: [:wiki]
      mac = Config.configured_color_modules()
      assert length(mac) == 1
      assert get_modules(mac) == [Fledex.Color.Names.Wiki]

      use Config, colors: [:none]
      mac = Config.configured_color_modules()
      assert Enum.empty?(mac)
      assert get_modules(mac) == []

      use Config, colors: [:wiki, Fledex.Color.Names.CSS]
      mac = Config.configured_color_modules()
      assert length(mac) == 2
      assert get_modules(mac) == [Fledex.Color.Names.Wiki, Fledex.Color.Names.CSS]

      use Config, colors: [TestColorModule]
      mac = Config.configured_color_modules()
      assert length(mac) == 1
      assert get_modules(mac) == [TestColorModule]

      use Config, colors: [:default]
      mac = Config.configured_color_modules()
      assert length(mac) == 3

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG
             ]

      use Config, colors: [:all]
      mac = Config.configured_color_modules()
      assert length(mac) == 4

      assert get_modules(mac) == [
               Fledex.Color.Names.Wiki,
               Fledex.Color.Names.CSS,
               Fledex.Color.Names.SVG,
               Fledex.Color.Names.RAL
             ]
    end

    test "with no colors definition" do
      use Config, colors: :wiki
      assert Fledex.Config.exists?()
      assert length(Config.configured_color_modules()) == 1

      use Config, colors: nil
      assert not Fledex.Config.exists?()
      assert Enum.empty?(Config.configured_color_modules())
    end

    test "with color import" do
      use Config, colors: :wiki
      assert red() == 0xFF0000
    end

    # it's a bit unclear to me where the logging is going :-(
    test "with specifying non-existing module" do
      import ExUnit.CaptureLog
      require Logger

      assert capture_log(fn ->
               # non-existant color module
               Code.compile_string("""
                 alias Fledex.Config
                 Code.ensure_loaded(Config)
                 use Config, colors: Test1
               """)
             end) =~ "Not a known color name"
    end

    test "with specifying color name module with wrong behaviour" do
      import ExUnit.CaptureLog

      assert capture_log(fn ->
               # existant, but not implementing the behaviour
               Code.compile_string("""
                   alias Fledex.Config
                   Code.ensure_loaded(Config)

                   defmodule Test2 do
                   end

                   use Config, colors: Test2
               """)
             end) =~ "Not a known color name"
    end

    test "when redefining config with overlapping colors" do
      import ExUnit.CaptureIO

      code = """
          alias Fledex.Config
          alias Fledex.Color.Names.Wiki
          alias Fledex.Color.Names.CSS

          Code.ensure_loaded(Config)
          Code.ensure_loaded(Wiki)
          Code.ensure_loaded(CSS)

          use Config, colors: :wiki
          red()
          use Config, colors: :css
          red()
      """

      io =
        capture_io(:stderr, fn ->
          response =
            try do
              :elixir_compiler.string(to_charlist(code), "no_file", fn _a, _b -> :ok end)
              {:ok, ""}
            rescue
              x in CompileError ->
                %CompileError{description: description} = x
                {:rescue, description}
            end

          assert response == {:rescue, "cannot compile file (errors have been logged)"}
        end)

      assert io =~ "error"

      assert io =~
               "function red/0 imported from both Fledex.Color.Names.CSS and Fledex.Color.Names.Wiki, call is ambiguous"
    end

    test "when redefining config with overlapping colors, but no imports" do
      import ExUnit.CaptureIO

      code = """
          alias Fledex.Config
          alias Fledex.Color.Names.Wiki
          alias Fledex.Color.Names.CSS

          Code.ensure_loaded(Config)
          Code.ensure_loaded(Wiki)
          Code.ensure_loaded(CSS)

          use Config, colors: :wiki
          red()
          use Config, colors: :css, no_imports: true
          red()
      """

      io =
        capture_io(:stderr, fn ->
          response =
            try do
              :elixir_compiler.string(to_charlist(code), "no_file", fn _a, _b -> :ok end)
              {:ok, ""}
            rescue
              x in CompileError ->
                %CompileError{description: description} = x
                {:rescue, description}
            end

          assert response == {:ok, ""}
        end)

      assert io == ""
    end
  end

  describe "color names access tests" do
    test "defined color modules" do
      use Config, colors: :default
      colors = Config.configured_color_modules()
      assert length(colors) == 3

      modules =
        Enum.map(colors, fn {module, colors} ->
          assert is_list(colors)
          module
        end)

      assert modules == [Fledex.Color.Names.Wiki, Fledex.Color.Names.CSS, Fledex.Color.Names.SVG]
    end

    test "calling by name" do
      alias Fledex.Color.Names.Wiki
      use Config, colors: :default

      assert Wiki.vermilion2(:all) == %{
               hex: 14_235_678,
               hsl: %Fledex.Color.HSL{h: 5, s: 193, l: 122},
               hsv: %Fledex.Color.HSV{h: 5, s: 219, v: 216},
               index: 828,
               name: :vermilion2,
               descriptive_name: "Vermilion2",
               source: "",
               rgb: {216, 56, 30},
               module: Fledex.Color.Names.Wiki
             }

      assert Names.info(:vermilion2, :all) == %{
               hex: 14_235_678,
               hsl: %Fledex.Color.HSL{h: 5, s: 193, l: 122},
               hsv: %Fledex.Color.HSV{h: 5, s: 219, v: 216},
               index: 828,
               name: :vermilion2,
               descriptive_name: "Vermilion2",
               source: "",
               rgb: {216, 56, 30},
               module: Fledex.Color.Names.Wiki
             }
    end

    test "calling by name with atom" do
      use Fledex.Config, colors: :default

      assert Names.info(:vermilion2, :all) == %{
               hex: 14_235_678,
               hsl: %Fledex.Color.HSL{h: 5, s: 193, l: 122},
               hsv: %Fledex.Color.HSV{h: 5, s: 219, v: 216},
               index: 828,
               name: :vermilion2,
               descriptive_name: "Vermilion2",
               source: "",
               rgb: {216, 56, 30},
               module: Fledex.Color.Names.Wiki
             }
    end

    test "test quick access functions (with atom)" do
      use Config, colors: :default
      assert 14_235_678 == Names.info(:vermilion2)
      assert 14_235_678 == Names.info(:vermilion2, :hex)
      assert {216, 56, 30} == Names.info(:vermilion2, :rgb)
      assert :vermilion2 == Names.info(:vermilion2, :name)
      assert %Fledex.Color.HSL{h: 5, s: 193, l: 122} == Names.info(:vermilion2, :hsl)
      assert %Fledex.Color.HSV{h: 5, s: 219, v: 216} == Names.info(:vermilion2, :hsv)
      assert 828 == Names.info(:vermilion2, :index)
      assert "Vermilion2" == Names.info(:vermilion2, :descriptive_name)
      assert "" == Names.info(:vermilion2, :source)
      assert "Crayola" == Names.info(:absolute_zero, :source)
      assert nil == Names.info(:non_existing_color_name, :hex)
      assert Fledex.Color.Names.Wiki == Names.info(:vermilion2, :module)

      assert :vermilion2 in Names.names()
    end
  end
end
