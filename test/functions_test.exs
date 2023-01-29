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

  test "rgb correction" do
    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()

      assert leds == [
        {255,   0,   0},
        {189,  66,   0},
        {171, 135,   0},
        {108, 201,   0},
        {  0, 240,  15},
        {  0, 173,  82},
        {  0,  39, 217},
        { 50,   0, 205},
        {116,   0, 140},
        {185,   0,  70}
      ]
  end

  test "check no correction" do
    correction = Correction.define_correction(255, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,   0},
        {188,  65,   0},
        {170, 134,   0},
        {107, 200,   0},
        {  0, 239,  14},
        {  0, 172,  81},
        {  0,  38, 216},
        { 49,   0, 204},
        {115,   0, 139},
        {184,   0,  69}
      ]
  end

  test "check scale correction" do
    correction = Correction.define_correction(200, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_rgb_correction(correction)

      assert leds == [
        {199,   0,   0},
        {147,  51,   0},
        {133, 105,   0},
        { 84, 157,   0},
        {  0, 187,  11},
        {  0, 135,  64},
        {  0,  30, 169},
        { 39,   0, 160},
        { 90,   0, 109},
        {144,   0, 54}
      ]
  end

  test "check color correction" do
    correction = Correction.define_correction(255, typicalSMD5050(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,   0},
        {188,  45,   0},
        {170,  92,   0},
        {107, 138,   0},
        {  0, 165,  14},
        {  0, 118,  76},
        {  0,  26, 203},
        { 49,   0, 192},
        {115,   0, 131},
        {184,   0,  65}
      ]
  end

  test "check temperature correction" do
    correction = Correction.define_correction(255, uncorrectedColor(), candle())

    leds = Functions.create_rainbow_circular_hsv(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_rgb_correction(correction)

      assert leds == [
        {254,   0,  0},
        {188,  37,  0},
        {170,  77,  0},
        {107, 115,  0},
        {0,   137,  2},
        {0,    99, 13},
        {0,    22, 34},
        {49,    0, 32},
        {115,   0, 22},
        {184,   0, 11}
      ]
  end
end
