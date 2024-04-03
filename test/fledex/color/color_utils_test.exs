# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.UtilsTest do
  use ExUnit.Case, async: true

  alias Fledex.Color.Utils

  test "average" do
    led = [{0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}]
    assert Utils.avg(led) == {0x11, 0x64, 0xC8}
  end

  test "cap" do
    led = [{0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}]
    assert Utils.cap(led) == {0x33, 0xFF, 0xFF}
    led = [{0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}, {0x11, 0x64, 0xC8}]
    assert Utils.cap(led, 0x66..0xFF) == {0x66, 0xFF, 0xFF}
  end

  test "combine" do
    led = {0x11, 0x64, 0xC8}
    assert Utils.to_colorint(led) == 0x1164C8
  end

  test "split into subpixels" do
    pixel = 0xFF7722
    assert Utils.split_into_subpixels(pixel) == {0xFF, 0x77, 0x22}
  end

  test "add_subpixels" do
    pixels = [{20, 40, 100}, {20, 40, 100}, {20, 40, 100}]
    assert Utils.add_subpixels(pixels) == {60, 120, 300}
  end

  test "frac8" do
    assert Utils.frac8(48, 128) == 96
  end

  test "(n)scale8" do
    assert Utils.scale8(128, Utils.frac8(32, 85), false) == 48
    assert Utils.scale8(128, Utils.frac8(32, 85), true) == 49
    assert Utils.scale8(255, 0, true) == 0

    assert Utils.nscale8({128, 128, 128}, Utils.frac8(32, 85)) == {49, 49, 49}
    assert Utils.nscale8({128, 128, 128}, Utils.frac8(32, 85), false) == {48, 48, 48}
    assert Utils.nscale8(Utils.to_colorint({128, 128, 128}), Utils.frac8(32, 85)) == 3_223_857
  end

  test "convert to_colorint" do
    assert Utils.to_colorint(0xFFEEDD) == 0xFFEEDD
    assert Utils.to_colorint({0xFF, 0xEE, 0xDD}) == 0xFFEEDD
    assert Utils.to_colorint(:red) == 0xFF0000
  end

  test "convert to_rgb" do
    assert Utils.to_rgb(%{rgb: 0x123456}) == {0x12, 0x34, 0x56}
    assert Utils.to_rgb(%{rgb: {0x12, 0x34, 0x56}}) == {0x12, 0x34, 0x56}
    assert Utils.to_rgb(:red) == {0xFF, 0x00, 0x00}
    assert Utils.to_rgb(0x123456) == {0x12, 0x34, 0x56}
    assert Utils.to_rgb({0x12, 0x34, 0x56}) == {0x12, 0x34, 0x56}
  end
end
