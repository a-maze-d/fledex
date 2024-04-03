# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.FunctionsTest do
  use ExUnit.Case, async: true

  import Fledex.Color.Correction.Color
  import Fledex.Color.Correction.Temperature

  require Logger

  alias Fledex.Color.Conversion.Rainbow
  alias Fledex.Color.Correction
  alias Fledex.Color.Functions

  doctest Functions

  describe "test rainbow function" do
    test "create 10 pixels with rainbow colors" do
      assert Functions.create_rainbow_circular_hsv(10) ==
               [
                 {0, 240, 255},
                 {25, 240, 255},
                 {51, 240, 255},
                 {76, 240, 255},
                 {102, 240, 255},
                 {127, 240, 255},
                 {153, 240, 255},
                 {179, 240, 255},
                 {204, 240, 255},
                 {230, 240, 255}
               ]
    end

    test "create 0 pixels with rainbow colors and offset 0" do
      assert Functions.create_rainbow_circular_hsv(0, 0, true) == []
      assert Functions.create_rainbow_circular_hsv(0, 0, false) == []
    end

    test "create 10 pixels with rainbow colors and offset 50" do
      assert Functions.create_rainbow_circular_hsv(10, 50) ==
               [
                 {50, 240, 255},
                 {75, 240, 255},
                 {101, 240, 255},
                 {126, 240, 255},
                 {152, 240, 255},
                 {177, 240, 255},
                 {203, 240, 255},
                 {229, 240, 255},
                 {254, 240, 255},
                 {24, 240, 255}
               ]
    end

    test "create 10 pixels with rainbow colors and offset 50 in reversed order" do
      assert Functions.create_rainbow_circular_hsv(10, 50, true) ==
               [
                 {50, 240, 255},
                 {25, 240, 255},
                 {255, 240, 255},
                 {230, 240, 255},
                 {204, 240, 255},
                 {179, 240, 255},
                 {153, 240, 255},
                 {127, 240, 255},
                 {102, 240, 255},
                 {76, 240, 255}
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
      assert Functions.create_gradient_rgb(1, {0xFF, 0x00, 0x00}, {0x00, 0x00, 0xFF}) == [
               {0x7F, 0x00, 0x7F}
             ]
    end

    test "gradient with 1 distance (complex)" do
      assert Functions.create_gradient_rgb(1, {0x7F, 0xD3, 0x5E}, {0x2A, 0xFF, 0x8F}) == [
               {0x54, 0xE9, 0x76}
             ]
    end

    test "gradient with 10 distance (simple)" do
      assert Functions.create_gradient_rgb(10, {0xFF, 0x00, 0x00}, {0x00, 0x00, 0xFF}) ==
               [
                 {0xE7, 0x00, 0x17},
                 {0xD0, 0x00, 0x2E},
                 {0xB9, 0x00, 0x45},
                 {0xA2, 0x00, 0x5C},
                 {0x8B, 0x00, 0x73},
                 {0x73, 0x00, 0x8B},
                 {0x5C, 0x00, 0xA2},
                 {0x45, 0x00, 0xB9},
                 {0x2E, 0x00, 0xD0},
                 {0x17, 0x00, 0xE7}
               ]
    end

    test "gradient with 10 distance (complex)" do
      assert Functions.create_gradient_rgb(10, {0x7F, 0xD3, 0x5E}, {0x2A, 0xFF, 0x8F}) ==
               [
                 {0x77, 0xD7, 0x62},
                 {0x6F, 0xDB, 0x66},
                 {0x67, 0xDF, 0x6B},
                 {0x60, 0xE3, 0x6F},
                 {0x58, 0xE7, 0x74},
                 {0x50, 0xEB, 0x78},
                 {0x48, 0xEF, 0x7D},
                 {0x41, 0xF3, 0x81},
                 {0x39, 0xF7, 0x86},
                 {0x31, 0xFB, 0x8A}
               ]
    end
  end

  describe "test hsv2rgb function" do
    assert [{173, 14, 5}] ==
             Functions.hsv2rgb(
               [{5, 219, 216}],
               &Rainbow.hsv2rgb/2,
               &Correction.color_correction_none/1
             )

    assert [{173, 14, 5}] ==
             Functions.hsv2rgb(
               [{5, 219, 216}],
               &Rainbow.hsv2rgb/2
             )

    assert [{173, 14, 5}] == Functions.hsv2rgb([{5, 219, 216}])
  end
end
