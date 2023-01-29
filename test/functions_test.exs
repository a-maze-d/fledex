defmodule Fledex.FunctionsTest do
  require Logger
  import Fledex.Color.Correction.Color
  import Fledex.Color.Correction.Temperature
  alias Fledex.Color.Correction

  use ExUnit.Case
  alias Fledex.Functions

  doctest Functions

  test "create 10 pixels with rainbow colors" do
    assert Functions.create_rainbow_circular_hsv(10) ==
    [
      {  0, 240, 255},
      { 25, 240, 255},
      { 51, 240, 255},
      { 76, 240, 255},
      {102, 240, 255},
      {127, 240, 255},
      {153, 240, 255},
      {179, 240, 255},
      {204, 240, 255},
      {230, 240, 255}
    ]
  end

  test "create 10 pixels with rainbow colors and offset 50" do
    assert Functions.create_rainbow_circular_hsv(10, 50) ==
    [
      { 50, 240, 255},
      { 75, 240, 255},
      {101, 240, 255},
      {126, 240, 255},
      {152, 240, 255},
      {177, 240, 255},
      {203, 240, 255},
      {229, 240, 255},
      {254, 240, 255},
      { 24, 240, 255}
    ]
  end

  test "create 10 pixels with rainbow colors and offset 50 in reversed order" do
    assert Functions.create_rainbow_circular_hsv(10, 50, true) ==
    [
      { 50, 240, 255},
      { 25, 240, 255},
      {255, 240, 255},
      {230, 240, 255},
      {204, 240, 255},
      {179, 240, 255},
      {153, 240, 255},
      {127, 240, 255},
      {102, 240, 255},
      { 76, 240, 255}
    ]
  end

  test "rgb correction" do
    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()

      assert leds == [
        {255,   1,   1},
        {189,  67,   1},
        {171, 135,   1},
        {109, 201,   1},
        {  1, 240,  16},
        {  1, 173,  83},
        {  1,  40, 217},
        { 51,   1, 205},
        {117,   1, 140},
        {185,   1,  71}
      ]
  end

  test "check no correction" do
    correction = Correction.define_correction(255, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Correction.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,   0},
        {188,  66,   0},
        {170, 134,   0},
        {108, 200,   0},
        {  0, 239,  15},
        {  0, 172,  82},
        {  0,  39, 216},
        { 50,   0, 204},
        {116,   0, 139},
        {184,   0,  70}
      ]
  end

  test "check scale correction" do
    correction = Correction.define_correction(200, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Correction.apply_rgb_correction(correction)

      assert leds == [
        {199,   0,   0},
        {147,  52,   0},
        {133, 105,   0},
        { 85, 157,   0},
        {  0, 187,  12},
        {  0, 135,  64},
        {  0,  31, 169},
        { 39,   0, 160},
        { 91,   0, 109},
        {144,   0, 55}
      ]
  end

  test "check color correction" do
    correction = Correction.define_correction(255, typicalSMD5050(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Correction.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,   0},
        {188,  46,   0},
        {170,  92,   0},
        {108, 138,   0},
        {  0, 165,  15},
        {  0, 118,  77},
        {  0,  27, 203},
        { 50,   0, 192},
        {116,   0, 131},
        {184,   0,  66}
      ]
  end

  test "check temperature correction" do
    correction = Correction.define_correction(255, uncorrectedColor(), candle())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Correction.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,  0},
        {188,  38,  0},
        {170,  77,  0},
        {108, 115,  0},
        {0,   137,  2},
        {0,    99, 13},
        {0,    22, 34},
        {50,    0, 32},
        {116,   0, 22},
        {184,   0, 11}
      ]
  end
end
