defmodule LedsTest do
  use ExUnit.Case
  doctest Leds

  test "struct definition" do
    leds = %Leds{}
    assert leds.count == 0
    assert leds.leds == %{}
  end

  test "setting number of leds" do
    leds = %Leds{count: 96}
    assert leds.count == 96
    assert leds.leds == %{}
  end

  test "setting leds in bound" do
    leds = %Leds{count: 10}
    offset = 5
    leds = Leds.update(leds, 0xFF0000, offset)
    assert Map.fetch(leds.leds, offset) == {:ok, 0xFF0000}
  end

  test "setting several leds and updating first one" do
    leds = %Leds{count: 10}
    offset = 5
    leds = Leds.update(leds, 0xFF0000, offset)
    leds = Leds.update(leds, 0x00FF00, offset+1)
    leds = Leds.update(leds, 0x0000FF, offset)
    assert Map.fetch(leds.leds, offset) == {:ok, 0x0000FF}
    assert Map.fetch(leds.leds, offset+1) == {:ok, 0x00FF00}
    assert map_size(leds.leds) == 2
  end

  test "embedding leds in leds" do
    leds_all = %Leds{count: 100}
    offset = 5
    leds_some = %Leds{count: 20, leds: %{
      1 => 0x00FF00,
      2 => 0x0000FF,
      11 => 0x00FF00,
      12 => 0x0000FF
    }}
    leds_all = Leds.update(leds_all, leds_some, offset)

    assert Map.fetch(leds_all.leds, offset) == {:ok, 0x00FF00}
    assert Map.fetch(leds_all.leds, offset+1) == {:ok, 0x0000FF}
    assert Map.fetch(leds_all.leds, offset+10) == {:ok, 0x00FF00}
    assert Map.fetch(leds_all.leds, offset+11) == {:ok, 0x0000FF}
  end

  test "embedding leds with overlap" do
    offset = 5
    leds_all = %Leds{count: 100, leds: %{
      offset+1 => 0xFF0000, # this led will be overwritten with 0x0000FF
    }}
    leds_some = %Leds{count: 20, leds: %{
      1 => 0x00FF00,
      2 => 0x0000FF,
      11 => 0x00FF00,
      12 => 0x0000FF
    }}
    leds_all = Leds.update(leds_all, leds_some, offset)

    assert Map.fetch(leds_all.leds, offset) == {:ok, 0x00FF00}
    assert Map.fetch(leds_all.leds, offset+1) == {:ok, 0x0000FF}
    assert Map.fetch(leds_all.leds, offset+10) == {:ok, 0x00FF00}
    assert Map.fetch(leds_all.leds, offset+11) == {:ok, 0x0000FF}
  end

end
