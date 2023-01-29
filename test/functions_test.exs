defmodule Fledex.FunctionsTest do
  require Logger
  import Fledex.Color.ColorCorrection
  import Fledex.Color.TemperatureCorrection
  alias Fledex.Pixeltypes.Hsv
  alias Fledex.Color

  use ExUnit.Case
  alias Fledex.Functions

  doctest Functions

  test "create 10 pixels with rainbow colors" do
    assert Functions.create_rainbow_circular(10) ==
    [
      %Hsv{h: 0, s: 240, v: 255},
      %Hsv{h: 25, s: 240, v: 255},
      %Hsv{h: 51, s: 240, v: 255},
      %Hsv{h: 76, s: 240, v: 255},
      %Hsv{h: 102, s: 240, v: 255},
      %Hsv{h: 127, s: 240, v: 255},
      %Hsv{h: 153, s: 240, v: 255},
      %Hsv{h: 179, s: 240, v: 255},
      %Hsv{h: 204, s: 240, v: 255},
      %Hsv{h: 230, s: 240, v: 255}
    ]
  end

  test "create 10 pixels with rainbow colors and offset 50" do
    assert Functions.create_rainbow_circular(10, 50) ==
    [
      %Hsv{h:  50, s: 240, v: 255},
      %Hsv{h:  75, s: 240, v: 255},
      %Hsv{h: 101, s: 240, v: 255},
      %Hsv{h: 126, s: 240, v: 255},
      %Hsv{h: 152, s: 240, v: 255},
      %Hsv{h: 177, s: 240, v: 255},
      %Hsv{h: 203, s: 240, v: 255},
      %Hsv{h: 229, s: 240, v: 255},
      %Hsv{h: 254, s: 240, v: 255},
      %Hsv{h:  24, s: 240, v: 255}
    ]
  end

  test "rgb correction" do
    leds = Functions.create_rainbow_circular(10)
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
    correction = Color.define_correction(255, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_correction(correction)

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
    correction = Color.define_correction(200, uncorrectedColor(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_correction(correction)

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
    correction = Color.define_correction(255, typicalSMD5050(), uncorrectedTemperature())

    leds = Functions.create_rainbow_circular(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_correction(correction)

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
    correction = Color.define_correction(255, uncorrectedColor(), candle())

    leds = Functions.create_rainbow_circular(10)
      |> Functions.hsv2rgb()
      |> Functions.apply_correction(correction)

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
