# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.ConfigTest do
  use ExUnit.Case

  alias Fledex.Config

  def get_modules(modules_and_color) do
    Enum.map(modules_and_color, fn {module, _colors} -> module end)
  end

  describe "use config" do
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

    test "colors parameter" do
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

    test "no colors definition" do
      use Config, colors: :wiki
      assert Fledex.Config.exists?()
      assert length(Config.configured_color_modules()) == 1

      use Config, colors: nil
      assert not Fledex.Config.exists?()
      assert Enum.empty?(Config.configured_color_modules())
    end

    # it's a bit unclear to me where the logging is going :-(
    test "specify non-existing module" do
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

    test "specify color name module with wrong behaviour" do
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
  end
end
