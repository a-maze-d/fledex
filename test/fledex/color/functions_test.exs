# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.FunctionsTest do
  use ExUnit.Case, async: true

  import Fledex.Color.Correction.Color
  import Fledex.Color.Correction.Temperature

  alias Fledex.Color.Conversion.Rainbow
  alias Fledex.Color.Correction
  alias Fledex.Color.Functions
  alias Fledex.Color.HSV
  alias Fledex.Color.RGB

  doctest Functions

  describe "test rainbow function" do
    test "create 10 pixels with rainbow colors" do
      assert Functions.create_rainbow_circular_hsv(10) ==
               [
                 %HSV{h: 0, s: 240, v: 255},
                 %HSV{h: 25, s: 240, v: 255},
                 %HSV{h: 51, s: 240, v: 255},
                 %HSV{h: 76, s: 240, v: 255},
                 %HSV{h: 102, s: 240, v: 255},
                 %HSV{h: 127, s: 240, v: 255},
                 %HSV{h: 153, s: 240, v: 255},
                 %HSV{h: 179, s: 240, v: 255},
                 %HSV{h: 204, s: 240, v: 255},
                 %HSV{h: 230, s: 240, v: 255}
               ]
    end

    test "create 0 pixels with rainbow colors and offset 0" do
      assert Functions.create_rainbow_circular_hsv(0, 0, true) == []
      assert Functions.create_rainbow_circular_hsv(0, 0, false) == []
    end

    test "create 10 pixels with rainbow colors and offset 50" do
      assert Functions.create_rainbow_circular_hsv(10, 50) ==
               [
                 %HSV{h: 50, s: 240, v: 255},
                 %HSV{h: 75, s: 240, v: 255},
                 %HSV{h: 101, s: 240, v: 255},
                 %HSV{h: 126, s: 240, v: 255},
                 %HSV{h: 152, s: 240, v: 255},
                 %HSV{h: 177, s: 240, v: 255},
                 %HSV{h: 203, s: 240, v: 255},
                 %HSV{h: 229, s: 240, v: 255},
                 %HSV{h: 254, s: 240, v: 255},
                 %HSV{h: 24, s: 240, v: 255}
               ]
    end

    test "create 10 pixels with rainbow colors and offset 50 in reversed order" do
      assert Functions.create_rainbow_circular_hsv(10, 50, true) ==
               [
                 %HSV{h: 50, s: 240, v: 255},
                 %HSV{h: 25, s: 240, v: 255},
                 %HSV{h: 255, s: 240, v: 255},
                 %HSV{h: 230, s: 240, v: 255},
                 %HSV{h: 204, s: 240, v: 255},
                 %HSV{h: 179, s: 240, v: 255},
                 %HSV{h: 153, s: 240, v: 255},
                 %HSV{h: 127, s: 240, v: 255},
                 %HSV{h: 102, s: 240, v: 255},
                 %HSV{h: 76, s: 240, v: 255}
               ]
    end

    test "rgb correction" do
      leds = Functions.create_rainbow_circular_rgb(10)

      assert leds == [
               {255, 1, 1},
               {189, 67, 1},
               {171, 135, 1},
               {109, 201, 1},
               {1, 240, 16},
               {1, 173, 83},
               {1, 40, 217},
               {51, 1, 205},
               {117, 1, 140},
               {185, 1, 71}
             ]
    end

    test "check no correction" do
      correction =
        Correction.define_correction(255, uncorrected_color(), uncorrected_temperature())

      leds =
        Functions.create_rainbow_circular_rgb(10)
        |> Correction.apply_rgb_correction(correction)

      assert leds == [
               {255, 1, 1},
               {189, 67, 1},
               {171, 135, 1},
               {109, 201, 1},
               {1, 240, 16},
               {1, 173, 83},
               {1, 40, 217},
               {51, 1, 205},
               {117, 1, 140},
               {185, 1, 71}
             ]
    end

    test "check scale correction" do
      correction =
        Correction.define_correction(200, uncorrected_color(), uncorrected_temperature())

      leds =
        Functions.create_rainbow_circular_rgb(10)
        |> Correction.apply_rgb_correction(correction)

      assert leds == [
               {199, 0, 0},
               {147, 52, 0},
               {133, 105, 0},
               {85, 157, 0},
               {0, 187, 12},
               {0, 135, 64},
               {0, 31, 169},
               {39, 0, 160},
               {91, 0, 109},
               {144, 0, 55}
             ]
    end

    test "check color correction" do
      correction = Correction.define_correction(255, typical_smd5050(), uncorrected_temperature())

      leds =
        Functions.create_rainbow_circular_rgb(10)
        |> Correction.apply_rgb_correction(correction)

      assert leds == [
               {254, 0, 0},
               {188, 46, 0},
               {170, 92, 0},
               {108, 138, 0},
               {0, 165, 15},
               {0, 118, 77},
               {0, 27, 203},
               {50, 0, 192},
               {116, 0, 131},
               {184, 0, 66}
             ]
    end

    test "check temperature correction" do
      correction = Correction.define_correction(255, uncorrected_color(), candle())

      leds =
        Functions.create_rainbow_circular_rgb(10)
        |> Correction.apply_rgb_correction(correction)

      assert leds == [
               {254, 0, 0},
               {188, 38, 0},
               {170, 77, 0},
               {108, 115, 0},
               {0, 137, 2},
               {0, 99, 13},
               {0, 22, 34},
               {50, 0, 32},
               {116, 0, 22},
               {184, 0, 11}
             ]
    end
  end

  describe "test gradient function" do
    test "gradient with 1 distance (simple)" do
      assert Functions.create_gradient_rgb(1, %RGB{r: 0xFF, g: 0x00, b: 0x00}, %RGB{
               r: 0x00,
               g: 0x00,
               b: 0xFF
             }) == [
               %RGB{r: 0x7F, g: 0x00, b: 0x7F}
             ]
    end

    test "gradient with 1 distance (complex)" do
      assert Functions.create_gradient_rgb(1, %RGB{r: 0x7F, g: 0xD3, b: 0x5E}, %RGB{
               r: 0x2A,
               g: 0xFF,
               b: 0x8F
             }) == [
               %RGB{r: 0x54, g: 0xE9, b: 0x76}
             ]
    end

    test "gradient with 10 distance (simple)" do
      assert Functions.create_gradient_rgb(10, %RGB{r: 0xFF, g: 0x00, b: 0x00}, %RGB{
               r: 0x00,
               g: 0x00,
               b: 0xFF
             }) ==
               [
                 %RGB{r: 0xE7, g: 0x00, b: 0x17},
                 %RGB{r: 0xD0, g: 0x00, b: 0x2E},
                 %RGB{r: 0xB9, g: 0x00, b: 0x45},
                 %RGB{r: 0xA2, g: 0x00, b: 0x5C},
                 %RGB{r: 0x8B, g: 0x00, b: 0x73},
                 %RGB{r: 0x73, g: 0x00, b: 0x8B},
                 %RGB{r: 0x5C, g: 0x00, b: 0xA2},
                 %RGB{r: 0x45, g: 0x00, b: 0xB9},
                 %RGB{r: 0x2E, g: 0x00, b: 0xD0},
                 %RGB{r: 0x17, g: 0x00, b: 0xE7}
               ]
    end

    test "gradient with 10 distance (complex)" do
      assert Functions.create_gradient_rgb(10, %RGB{r: 0x7F, g: 0xD3, b: 0x5E}, %RGB{
               r: 0x2A,
               g: 0xFF,
               b: 0x8F
             }) ==
               [
                 %RGB{r: 0x77, g: 0xD7, b: 0x62},
                 %RGB{r: 0x6F, g: 0xDB, b: 0x66},
                 %RGB{r: 0x67, g: 0xDF, b: 0x6B},
                 %RGB{r: 0x60, g: 0xE3, b: 0x6F},
                 %RGB{r: 0x58, g: 0xE7, b: 0x74},
                 %RGB{r: 0x50, g: 0xEB, b: 0x78},
                 %RGB{r: 0x48, g: 0xEF, b: 0x7D},
                 %RGB{r: 0x41, g: 0xF3, b: 0x81},
                 %RGB{r: 0x39, g: 0xF7, b: 0x86},
                 %RGB{r: 0x31, g: 0xFB, b: 0x8A}
               ]
    end
  end

  describe "test hsv2rgb function" do
    assert [{173, 14, 5}] ==
             Functions.hsv2rgb(
               [%HSV{h: 5, s: 219, v: 216}],
               conversion_function: &Rainbow.hsv2rgb/2,
               color_correction: &Functions.color_correction_none/1
             )

    assert [{173, 14, 5}] ==
             Functions.hsv2rgb(
               [%HSV{h: 5, s: 219, v: 216}],
               conversion_function: &Rainbow.hsv2rgb/2
             )

    assert [{173, 14, 5}] == Functions.hsv2rgb([%HSV{h: 5, s: 219, v: 216}])
  end
end
