# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.KinoRenderTest do
  use Kino.LivebookCase, async: true

  alias Fledex.Color.KinoRender
  alias Fledex.Leds

  describe "new" do
    test "single color" do
      assert %KinoRender{colors: [255]} = KinoRender.new(0x0000FF)
      assert %KinoRender{colors: [{0, 0, 255}]} = KinoRender.new({0, 0, 255})
      assert %KinoRender{colors: [:red]} = KinoRender.new(:red)
    end

    test "color array" do
      assert %KinoRender{colors: [255, {0, 0, 255}]} = KinoRender.new([0x0000FF, {0, 0, 255}])
    end

    test "guard" do
      import Fledex.Color.KinoRender, only: [is_byte: 1]
      assert is_byte(0) == true
      assert is_byte(128) == true
      assert is_byte(255) == true
      assert is_byte(-1) == false
      assert is_byte(256) == false
    end
  end

  describe "conversion functions" do
    test "to_leds" do
      kino = KinoRender.new([0x0000FF, {0, 0, 255}])
      assert %Leds{count: 2, leds: %{1 => 255, 2 => 255}} = KinoRender.to_leds(kino)
    end

    test "to_markdown" do
      kino = KinoRender.new([0x0000FF, {0, 0, 255}])

      assert ~s(<span style="color: #0000FF">█</span><span style="color: #0000FF">█</span>) ==
               KinoRender.to_markdown(kino)
    end
  end

  describe "livebook" do
    test "render" do
      KinoRender.new([0xFF0000, 0x00FF00, 0x0000FF])
      |> Kino.render()

      assert_output(%{
        labels: ["Leds", "Raw"],
        outputs: [
          %{
            type: :markdown,
            text:
              ~s(<span style="color: #FF0000">█</span><span style="color: #00FF00">█</span><span style="color: #0000FF">█</span>),
            chunk: false
          },
          %{
            type: :terminal_text,
            text:
              ~s(%Fledex.Color.KinoRender{\e[34mcolors:\e[0m [\e[34m16711680\e[0m, \e[34m65280\e[0m, \e[34m255\e[0m]}),
            chunk: false
          }
        ],
        type: :tabs
      })
    end
  end
end
