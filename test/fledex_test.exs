defmodule FledexTest do
  require Logger
  import Fledex.Color.ColorCorrection
  import Fledex.Color.TemperatureCorrection
  alias Fledex.Pixeltypes.Hsv
  alias Fledex.Pixeltypes.Rgb
  alias Fledex.Color

  use ExUnit.Case
  doctest Fledex

  test "create 10 pixels with rainbow colors" do
    assert Fledex.create_rainbow_circular(10) ==
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
    assert Fledex.create_rainbow_circular(10, 50) ==
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
    leds = Fledex.create_rainbow_circular(10)
      |> Fledex.convert_to_rgb()

      assert leds == [
        %Rgb{r: 255, g:   0, b:   0},
        %Rgb{r: 189, g:  66, b:   0},
        %Rgb{r: 171, g: 135, b:   0},
        %Rgb{r: 108, g: 201, b:   0},
        %Rgb{r:   0, g: 240, b:  15},
        %Rgb{r:   0, g: 173, b:  82},
        %Rgb{r:   0, g:  39, b: 217},
        %Rgb{r:  50, g:   0, b: 205},
        %Rgb{r: 116, g:   0, b: 140},
        %Rgb{r: 185, g:   0, b:  70}
      ]
  end

  test "check no correction" do
    correction = Color.define_correction(255, uncorrectedColor(), uncorrectedTemperature())

    leds = Fledex.create_rainbow_circular(10)
      |> Fledex.convert_to_rgb()
      |> Fledex.apply_correction(correction)

      assert leds == [
        %Rgb{r: 254, g:   0, b:   0},
        %Rgb{r: 188, g:  65, b:   0},
        %Rgb{r: 170, g: 134, b:   0},
        %Rgb{r: 107, g: 200, b:   0},
        %Rgb{r:   0, g: 239, b:  14},
        %Rgb{r:   0, g: 172, b:  81},
        %Rgb{r:   0, g:  38, b: 216},
        %Rgb{r:  49, g:   0, b: 204},
        %Rgb{r: 115, g:   0, b: 139},
        %Rgb{r: 184, g:   0, b:  69}
      ]
  end

  test "check scale correction" do
    correction = Color.define_correction(200, uncorrectedColor(), uncorrectedTemperature())

    leds = Fledex.create_rainbow_circular(10)
      |> Fledex.convert_to_rgb()
      |> Fledex.apply_correction(correction)

      assert leds == [
        %Rgb{r: 199, g:   0, b:   0},
        %Rgb{r: 147, g:  51, b:   0},
        %Rgb{r: 133, g: 105, b:   0},
        %Rgb{r:  84, g: 157, b:   0},
        %Rgb{r:   0, g: 187, b:  11},
        %Rgb{r:   0, g: 135, b:  64},
        %Rgb{r:   0, g:  30, b: 169},
        %Rgb{r:  39, g:   0, b: 160},
        %Rgb{r:  90, g:   0, b: 109},
        %Rgb{r: 144, g:   0, b:  54}
      ]
  end

  test "check color correction" do
    correction = Color.define_correction(255, typicalSMD5050(), uncorrectedTemperature())

    leds = Fledex.create_rainbow_circular(10)
      |> Fledex.convert_to_rgb()
      |> Fledex.apply_correction(correction)

      assert leds == [
        %Rgb{r: 254, g:   0, b:   0},
        %Rgb{r: 188, g:  45, b:   0},
        %Rgb{r: 170, g:  92, b:   0},
        %Rgb{r: 107, g: 138, b:   0},
        %Rgb{r:   0, g: 165, b:  14},
        %Rgb{r:   0, g: 118, b:  76},
        %Rgb{r:   0, g:  26, b: 203},
        %Rgb{r:  49, g:   0, b: 192},
        %Rgb{r: 115, g:   0, b: 131},
        %Rgb{r: 184, g:   0, b:  65}
      ]
  end

  test "check temperature correction" do
    correction = Color.define_correction(255, uncorrectedColor(), candle())

    leds = Fledex.create_rainbow_circular(10)
      |> Fledex.convert_to_rgb()
      |> Fledex.apply_correction(correction)

      assert leds == [
        %Rgb{r: 254, g: 0, b: 0},
        %Rgb{r: 188, g: 37, b: 0},
        %Rgb{r: 170, g: 77, b: 0},
        %Rgb{r: 107, g: 115, b: 0},
        %Rgb{r: 0, g: 137, b: 2},
        %Rgb{r: 0, g: 99, b: 13},
        %Rgb{r: 0, g: 22, b: 34},
        %Rgb{r: 49, g: 0, b: 32},
        %Rgb{r: 115, g: 0, b: 22},
        %Rgb{r: 184, g: 0, b: 11}
      ]
  end
end
