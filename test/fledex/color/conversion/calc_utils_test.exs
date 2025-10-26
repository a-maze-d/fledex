# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Conversion.CalcUtilsTest do
  use ExUnit.Case, async: true

  alias Fledex.Color
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.RGB

  test "average" do
    led = [
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8}
    ]

    assert CalcUtils.avg(led) == {0x11, 0x64, 0xC8}
  end

  test "cap" do
    led = [
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8}
    ]

    assert CalcUtils.cap(led) == {0x33, 0xFF, 0xFF}

    led = [
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8},
      %RGB{r: 0x11, g: 0x64, b: 0xC8}
    ]

    assert CalcUtils.cap(led, 0x66..0xFF) == {0x66, 0xFF, 0xFF}
  end

  test "add_subpixels" do
    pixels = [%RGB{r: 20, g: 40, b: 100}, %RGB{r: 20, g: 40, b: 100}, %RGB{r: 20, g: 40, b: 100}]
    assert CalcUtils.add_subpixels(pixels) == {60, 120, 300}
  end

  test "frac8" do
    assert CalcUtils.frac8(48, 128) == 96
  end

  test "(n)scale8" do
    assert CalcUtils.scale8(128, CalcUtils.frac8(32, 85), false) == 48
    assert CalcUtils.scale8(128, CalcUtils.frac8(32, 85), true) == 49
    assert CalcUtils.scale8(255, 0, true) == 0

    assert CalcUtils.nscale8({128, 128, 128}, CalcUtils.frac8(32, 85)) == {49, 49, 49}
    assert CalcUtils.nscale8({128, 128, 128}, CalcUtils.frac8(32, 85), false) == {48, 48, 48}

    assert CalcUtils.nscale8(Color.to_colorint({128, 128, 128}), CalcUtils.frac8(32, 85)) ==
             3_223_857
  end
end
