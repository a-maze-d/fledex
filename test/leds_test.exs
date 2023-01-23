defmodule LedsTest do
  use ExUnit.Case
  doctest Leds

  test "struct definition" do
    leds = Leds.new()
    assert leds.count == 0
    assert leds.leds == %{}
    assert leds.opts == nil
    assert leds.meta == %{index: 1}
  end

  test "setting number of leds" do
    leds = Leds.new(96)
    assert leds.count == 96
    assert leds.leds == %{}
    assert leds.opts == nil
    assert leds.meta == %{index: 1}
  end

  test "setting leds in sequence" do
    leds = Leds.new(10)
      |> Leds.light(0xFF0000)
      |> Leds.light(0x00FF00)
      |> Leds.light(0x0000FF)

    assert Leds.get_light(leds, 1) == 0xFF0000
    assert Leds.get_light(leds, 2) == 0x00FF00
    assert Leds.get_light(leds, 3) == 0x0000FF
  end

  test "setting leds in non-sequence" do
    offset = 5
    leds = Leds.new(10)
      |> Leds.light(0xFF0000, offset)
      |> Leds.light(0x00FF00)

    assert Leds.get_light(leds, offset)   == 0xFF0000
    assert Leds.get_light(leds, offset+1) == 0x00FF00
  end

  test "setting several leds and updating first one" do
    offset = 5
    leds = Leds.new(10)
      |> Leds.light(0xFF0000, offset)
      |> Leds.light(0x00FF00)
      |> Leds.light(0x0000FF, offset)

    assert Leds.get_light(leds, offset)   == 0x0000FF
    assert Leds.get_light(leds, offset+1) == 0x00FF00
    assert map_size(leds.leds) == 2
  end

  test "embedding leds in leds" do
    offset = 5
    leds_some = Leds.new(
      20,
      %{
        1 => 0x00FF00,
        2 => 0x0000FF,
        11 => 0x00FF00,
        12 => 0x0000FF
      },
      nil
    )

    leds_all = Leds.new(100)
      |> Leds.light(leds_some, offset)

    assert Leds.get_light(leds_all, offset)    == 0x00FF00
    assert Leds.get_light(leds_all, offset+1)  == 0x0000FF
    assert Leds.get_light(leds_all, offset+10) == 0x00FF00
    assert Leds.get_light(leds_all, offset+11) == 0x0000FF
  end

  test "embedding leds with overlap" do
    offset = 5
    leds_some = Leds.new(
      20,
      %{
        1 => 0x00FF00,
        2 => 0x0000FF,
        11 => 0x00FF00,
        12 => 0x0000FF
      },
      nil
    )
    leds_all = Leds.new(10)
      |> Leds.light(0xFF0000, offset+1) # this led will be overwritten with 0x0000FF
      |> Leds.light(leds_some, offset)


    assert Leds.get_light(leds_all, offset)    == 0x00FF00
    assert Leds.get_light(leds_all, offset+1)  == 0x0000FF
    assert Leds.get_light(leds_all, offset+10) == 0x00FF00
    assert Leds.get_light(leds_all, offset+11) == 0x0000FF
  end

  test "get binary with led values" do
    leds = Leds.new(
      5,
      %{
        1 => 0x00FF00,
        2 => 0x0000FF,
        4 => 0x00FF00,
        5 => 0x0000FF
      },
      nil
    )

    assert Leds.to_binary(leds) == <<0x00F00, 0x0000FF, 0, 0x00FF00, 0x0000FF>>
  end


# loop
#   Leds.new(10)
#     |> Leds.light 0xFF0000
#     |> Leds.light 0x00FF00
#     |> send()

end
