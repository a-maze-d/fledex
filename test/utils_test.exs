defmodule Fledex.UtilsTest do
  use ExUnit.Case

  alias Fledex.Utils

  test "average" do
    led = {0x33, 0x12C, 0x258}
    assert Utils.avg(led, 3) == {0x11, 0x64, 0xC8}
  end
  test "combine" do
    led = {0x11, 0x64, 0xC8}
    assert Utils.combine_subpixels(led) == 0x1164C8
  end
  test "split into subpixels" do
    pixel = 0xFF7722
    assert Utils.split_into_subpixels(pixel) == {0xFF, 0x77, 0x22}
  end
  test "add_subpixels" do
    pixels = [{20, 40, 100}, {20,40,100}, {20,40,100}]
    assert Utils.add_subpixels(pixels) == {60, 120, 300}
  end
end
