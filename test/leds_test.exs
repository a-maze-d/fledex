defmodule Fledex.LedsTest do
  use ExUnit.Case
  alias Fledex.Leds

  doctest Leds

  describe "basic tests" do
    test "struct definition" do
      leds = Leds.new()
      assert leds.count == 0
      assert leds.leds == %{}
      assert leds.opts == %{}
      assert leds.meta == %{index: 1}
    end

    test "setting number of leds" do
      leds = Leds.new(96)
      assert leds.count == 96
      assert leds.leds == %{}
      assert leds.opts == %{}
      assert leds.meta == %{index: 1}
    end

    test "converting from list to map" do
      list = [
        {0,     0,   0},
        {25,   25,  25},
        {50,   50,  50},
        {75,   75,  75},
        {100, 100, 100},
        {125, 125, 125},
        {150, 150, 150},
        {175, 175, 175},
        {200, 200, 200},
        {225, 225, 225},
        {250, 250, 250}
      ]
      assert Leds.convert_to_leds_structure(list) == %{
        1 => 0,
        2 => 0x191919,
        3 => 0x323232,
        4 => 0x4B4B4B,
        5 => 0x646464,
        6 => 0x7D7D7D,
        7 => 0x969696,
        8 => 0xAFAFAF,
        9 => 0xC8C8C8,
        10 => 0xE1E1E1,
        11 => 0xFAFAFA
      }
    end

    test "setting leds in sequence" do
      leds = Leds.new(10)
        |> Leds.func(:rainbow)

      Enum.each(leds.leds, fn led ->
        assert led != nil
      end)
      assert map_size(leds.leds) == 10

      # take some samples
      assert Leds.get_light(leds, 1) == 0xFF0101
      assert Leds.get_light(leds, 10) == 0xB90147
    end

    test "setting leds in non-sequence" do
      offset = 5
      leds = Leds.new(10)
        |> Leds.light(0xFF0000, offset)
        |> Leds.light(0x00FF00)

      assert Leds.get_light(leds, offset)   == 0xFF0000
      assert Leds.get_light(leds, offset + 1) == 0x00FF00
    end

    test "setting several leds and updating first one" do
      offset = 5
      leds = Leds.new(10)
        |> Leds.light(0xFF0000, offset)
        |> Leds.light(0x00FF00)
        |> Leds.light(0x0000FF, offset)

      assert Leds.get_light(leds, offset)   == 0x0000FF
      assert Leds.get_light(leds, offset + 1) == 0x00FF00
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
      assert Leds.get_light(leds_all, offset + 1)  == 0x0000FF
      assert Leds.get_light(leds_all, offset + 10) == 0x00FF00
      assert Leds.get_light(leds_all, offset + 11) == 0x0000FF
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
        |> Leds.light(0xFF0000, offset + 1) # this led will be overwritten with 0x0000FF
        |> Leds.light(leds_some, offset)

      assert Leds.get_light(leds_all, offset)    == 0x00FF00
      assert Leds.get_light(leds_all, offset + 1)  == 0x0000FF
      assert Leds.get_light(leds_all, offset + 10) == 0x00FF00
      assert Leds.get_light(leds_all, offset + 11) == 0x0000FF
    end
    test "setting leds by name" do
      leds = Leds.new(10)
        |> Leds.light(:light_salmon)
        |> Leds.light(:red)
        |> Leds.light(:green)
        |> Leds.light(:lime_web_x11_green_)
        |> Leds.light(:blue)

        assert Leds.get_light(leds, 1) == 0xFFA07A
        assert Leds.get_light(leds, 2) == 0xFF0000
        assert Leds.get_light(leds, 3) == 0x00FF00
        assert Leds.get_light(leds, 4) == 0x00FF00
        assert Leds.get_light(leds, 5) == 0x0000FF
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

      assert Leds.to_binary(leds) == <<0x00FF00, 0x0000FF, 0, 0x00FF00, 0x0000FF>>
    end

    test "get list with led values" do
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

      assert Leds.to_list(leds) == [0x00FF00, 0x0000FF, 0, 0x00FF00, 0x0000FF]
    end
  end
  describe "test functions" do
    test "rainbow" do
      config = %{
        num_leds: 20,
        initial_hue: 0,
        reversed: true
      }

      list = Leds.new(20)
      |> Leds.func(:rainbow, config)
      |> Leds.to_list()

      assert length(list) == 20
      assert list == [
        0xFF0101,
        0xDF0121,
        0xBC0144,
        0x9A0167,
        0x780189,
        0x5801A9,
        0x3601CA,
        0x1301ED,
        0x0122DF,
        0x01679A,
        0x01A65B,
        0x01CA36,
        0x01ED13,
        0x22EF01,
        0x67CC01,
        0xA6AC01,
        0xAB8A01,
        0xAB6801,
        0xBA4601,
        0xDD2301
      ]
    end

    test "gradient" do
      config = %{
        start_color: 0xFF0000,
        end_color: 0x0000FF
      }

      list = Leds.new(20)
      |> Leds.func(:gradient, config)
      |> Leds.to_list()

      assert length(list) == 20
      assert list == [
        0xF2000C,
        0xE60018,
        0xDA0024,
        0xCE0030,
        0xC2003C,
        0xB60048,
        0xAA0054,
        0x9D0061,
        0x91006D,
        0x850079,
        0x790085,
        0x6D0091,
        0x61009D,
        0x5500A9,
        0x4800B6,
        0x3C00C2,
        0x3000CE,
        0x2400DA,
        0x1800E6,
        0x0C00F2
      ]
    end

    test "repeat" do
      leds = Leds.new(3) |> Leds.light(:red) |> Leds.light(:red) |> Leds.light(:red) |> Leds.func(:repeat, %{amount: 3})
      assert leds.count == 9
      assert Leds.get_light(leds, 1) == 0xff0000
      assert Leds.get_light(leds, 2) == 0xff0000
      assert Leds.get_light(leds, 3) == 0xff0000
      assert Leds.get_light(leds, 4) == 0xff0000
      assert Leds.get_light(leds, 5) == 0xff0000
      assert Leds.get_light(leds, 6) == 0xff0000
      assert Leds.get_light(leds, 7) == 0xff0000
      assert Leds.get_light(leds, 8) == 0xff0000
      assert Leds.get_light(leds, 9) == 0xff0000
      assert leds.meta.index == 10
    end
  end

# loop
#   Leds.new(10)
#     |> Leds.light 0xFF0000
#     |> Leds.light 0x00FF00
#     |> send()

end
