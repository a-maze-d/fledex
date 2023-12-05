defmodule Fledex.LedsTest do
  use ExUnit.Case, async: true
  alias Fledex.Leds
  alias Fledex.LedStrip

  doctest Leds

  describe "basic tests" do
    test "define raw struct" do
      assert Leds.leds() == %Leds{
        count: 0,
        leds: %{},
        opts: %{namespace: nil, server_name: nil},
        meta: %{index: 1}
      }
    end
    test "struct definition" do
      leds = Leds.leds()
      assert leds.count == 0
      assert leds.leds == %{}
      assert leds.opts == %{namespace: nil, server_name: nil}
      assert leds.meta == %{index: 1}
    end
    test "struct definition with leds (list and map)" do
      leds = Leds.leds(10, %{1 => 0x00ff00}, %{})
      assert leds.count == 10
      assert leds.leds == %{1 => 0x00ff00}
      assert leds.opts == %{namespace: nil, server_name: nil}
      assert leds.meta == %{index: 1}

      leds = Leds.leds(10, [{0x00, 0xff, 0x00}], %{})
      assert leds.count == 10
      assert leds.leds == %{1 => 0x00ff00}
      assert leds.opts == %{namespace: nil, server_name: nil}
      assert leds.meta == %{index: 1}
    end
    test "delegates" do
      assert Leds.leds() === Leds.new()
      assert Leds.leds(10) === Leds.new(10)
      assert Leds.leds(10, %{server_name: :test, namespace: :space}) ===
        Leds.new(10, %{server_name: :test, namespace: :space})
      assert Leds.leds(10, %{1 => 0xff0000}, %{server_name: :test, namespace: :space}) ===
        Leds.new(10, %{1 => 0xff0000}, %{server_name: :test, namespace: :space})
      assert Leds.leds(10, %{1 => 0x00ff00}, %{server_name: :test, namespace: :space}, %{index: 1}) ===
        Leds.new(10, %{1 => 0x00ff00}, %{server_name: :test, namespace: :space}, %{index: 1})
    end
    test "setting number of leds" do
      leds = Leds.leds(96)
      assert leds.count == 96
      assert leds.leds == %{}
      assert leds.opts == %{namespace: nil, server_name: nil}
      assert leds.meta == %{index: 1}
    end
    test "resetting led count" do
      offset = 15
      color = 0x00ff00
      leds = Leds.leds(10) |> Leds.light(color, offset)
      assert Leds.count(leds) == 10
      assert Leds.get_light(leds, offset) == color

      leds = Leds.set_count(leds, 20)
      assert Leds.count(leds) == 20
      assert Leds.get_light(leds, offset) == color
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
      leds = Leds.leds(10)
        |> Leds.light(:red)
        |> Leds.light({0, 0xff, 0})
        |> Leds.light(0xff)

      assert Leds.get_light(leds, 1) == 0xff0000
      assert Leds.get_light(leds, 2) == 0x00ff00
      assert Leds.get_light(leds, 3) == 0x0000ff

    end
    test "setting leds with a function" do
      leds = Leds.leds(10)
        |> Leds.rainbow()

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
      leds = Leds.leds(10)
        |> Leds.light(0xFF0000, offset)
        |> Leds.light(0x00FF00)

      assert Leds.get_light(leds, offset)   == 0xFF0000
      assert Leds.get_light(leds, offset + 1) == 0x00FF00
    end

    test "setting several leds and updating first one" do
      offset = 5
      leds = Leds.leds(10)
        |> Leds.light(0xFF0000, offset)
        |> Leds.light(0x00FF00)
        |> Leds.light(0x0000FF, offset)

      assert Leds.get_light(leds, offset)   == 0x0000FF
      assert Leds.get_light(leds, offset + 1) == 0x00FF00
      assert map_size(leds.leds) == 2
    end

    test "embedding leds in leds" do
      offset = 5
      leds_some = Leds.leds(
        20,
        %{
          1 => 0x00FF00,
          2 => 0x0000FF,
          11 => 0x00FF00,
          12 => 0x0000FF
        },
        nil
      )

      leds_all = Leds.leds(100)
        |> Leds.light(leds_some, offset)

      assert Leds.get_light(leds_all, offset)    == 0x00FF00
      assert Leds.get_light(leds_all, offset + 1)  == 0x0000FF
      assert Leds.get_light(leds_all, offset + 10) == 0x00FF00
      assert Leds.get_light(leds_all, offset + 11) == 0x0000FF
    end

    test "embedding leds with overlap" do
      offset = 5
      leds_some = Leds.leds(
        20,
        %{
          1 => 0x00FF00,
          2 => 0x0000FF,
          11 => 0x00FF00,
          12 => 0x0000FF
        },
        nil
      )
      leds_all = Leds.leds(10)
        |> Leds.light(0xFF0000, offset + 1) # this led will be overwritten with 0x0000FF
        |> Leds.light(leds_some, offset)

      assert Leds.get_light(leds_all, offset)    == 0x00FF00
      assert Leds.get_light(leds_all, offset + 1)  == 0x0000FF
      assert Leds.get_light(leds_all, offset + 10) == 0x00FF00
      assert Leds.get_light(leds_all, offset + 11) == 0x0000FF
    end
    test "get light" do
      leds = Leds.leds(10) |> Leds.light(0xff0000, 5) |> Leds.light(0x00ff00, 20)
      assert Leds.get_light(leds, 1) == 0
      assert Leds.get_light(leds, 5) == 0xff0000
      assert Leds.get_light(leds, 20) == 0x00ff00
    end
    test "setting leds by name" do
      leds = Leds.leds(10)
        |> Leds.light(:light_salmon)
        |> Leds.light(:red)
        |> Leds.light(:green)
        |> Leds.light(:lime_web_x11_green)
        |> Leds.light(:blue)

        assert Leds.get_light(leds, 1) == 0xFFA07A
        assert Leds.get_light(leds, 2) == 0xFF0000
        assert Leds.get_light(leds, 3) == 0x00FF00
        assert Leds.get_light(leds, 4) == 0x00FF00
        assert Leds.get_light(leds, 5) == 0x0000FF
    end

    test "get binary with led values" do
      leds = Leds.leds(
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
      leds = Leds.leds(
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
    test "setting driver info" do
      leds = Leds.leds() |> Leds.set_driver_info(:test_name, :test_strip)
      assert leds.opts.namespace == :test_name
      assert leds.opts.server_name == :test_strip

      leds = Leds.leds() |> Leds.set_driver_info(:test_name)
      assert leds.opts.namespace == :test_name
      assert leds.opts.server_name == LedStrip

    end
  end
  describe "test functions" do
    test "rainbow" do
      config = %{
        num_leds: 20,
        initial_hue: 0,
        reversed: true
      }

      list = Leds.leds(20)
      |> Leds.rainbow(config)
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
      list = Leds.leds(20)
      |> Leds.gradient(0xff0000, 0x0000ff)
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
      leds = Leds.leds(3) |> Leds.light(:red) |> Leds.light(:red) |> Leds.light(:red) |> Leds.repeat(3)
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
    test "light with repeat" do
      leds = Leds.leds(3) |> Leds.light(:red, 2, 3)
      assert Leds.count(leds) == 3
      assert Leds.get_light(leds, 1) == 0x000000
      assert Leds.get_light(leds, 2) == 0xff0000
      assert Leds.get_light(leds, 3) == 0xff0000
    assert_raise ArgumentError, fn ->
        Leds.leds(3) |> Leds.light(:red, 1, 1)
      end
      assert_raise ArgumentError, fn ->
        Leds.leds(3) |> Leds.light(:red, -1, 2)
      end
    end
    test "repeat with different input types" do
      leds = Leds.leds(10, %{
        1 => 0xff0000,
        2 => 0x00ff00,
        3 => 0x0000ff
      }, %{})
        |> Leds.light(0xaabbcc, 4, 2)
        |> Leds.light(:may_green, 6, 2)
        |> Leds.light(Leds.leds(1) |> Leds.light(:red), 8, 2)
      assert leds.leds[1] == 0xff0000
      assert leds.leds[2] == 0x00ff00
      assert leds.leds[3] == 0x0000ff
      assert leds.leds[4] == 0xaabbcc
      assert leds.leds[5] == 0xaabbcc
      assert leds.leds[6] == 0x4c9141
      assert leds.leds[7] == 0x4c9141
      assert leds.leds[8] == 0xff0000
      assert leds.leds[9] == 0xff0000
    end
  end
  describe "internal functions" do
    test "rotate" do
      vals = [1, 2, 3, 4, 5, 6, 7, 8]
      assert Leds.rotate(vals, 0, true) == [1, 2, 3, 4, 5, 6, 7, 8]
      assert Leds.rotate(vals, 1, true) == [2, 3, 4, 5, 6, 7, 8, 1]
      assert Leds.rotate(vals, 0, false) == [1, 2, 3, 4, 5, 6, 7, 8]
      assert Leds.rotate(vals, 1, false) == [8, 1, 2, 3, 4, 5, 6, 7]
      assert Leds.rotate(vals, 2) == [3, 4, 5, 6, 7, 8, 1, 2]
    end
  end
  describe "errors" do
    test "light on negative offset position" do
      assert_raise ArgumentError, ~r/the offset needs to be > 0/, fn ->
        Leds.light(Leds.leds(2), :red, -1)
      end
    end
    # test "gradient with missing config parameters" do
    #   assert_raise ArgumentError, ~r/start_color and end_color/, fn ->
    #     Leds.gradient(Leds.leds(10), %{})
    #   end
    #   assert_raise ArgumentError, ~r/start_color and end_color/, fn ->
    #     Leds.do_gradient(Leds.leds(10), %{start_color: :red})
    #   end
    #   assert_raise ArgumentError, ~r/start_color and end_color/, fn ->
    #     Leds.do_gradient(Leds.leds(10), %{end_color: :red})
    #   end
    # end
    test "wrong structure" do
      assert_raise ArgumentError, ~r/unknown data/, fn ->
        Leds.light(%{}, :red, 1)
      end
    end
  end
end

defmodule Fledex.LedsTestSync do
  # all the sync tests that require some GenServer. We want to run
  # them in a sync way. We split them out for that reason
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  alias Fledex.Leds

  # @strip_name :test_strip
  # setup do
  #   {:ok, pid} = start_supervised(
  #     %{
  #       id: LedStrip,
  #       start: {LedStrip, :start_link, [@strip_name, :none]}
  #     })
  #   %{strip_name: @strip_name,
  #     pid: pid}
  # end

  describe "send functions" do
    test "correct setup and warnings" do
      leds = Leds.leds(20) |> Leds.light(:red, 1, 10)
      {:ok, log} = with_log (fn ->
        Leds.send(leds)
      end)
      assert String.match?(log, ~r/warning/)
      assert String.match?(log, ~r/You should start it/)
      assert String.match?(log, ~r/namespace hasn't been defined/)
    end
  end
end

defmodule Fledex.LedsTestKino do
  use Kino.LivebookCase, async: true
  alias Fledex.Leds

  describe "render test" do
    test "output" do
      Leds.leds(3)
        |> Leds.light(0xff0000)
        |> Leds.light(0x00ff00)
        |> Leds.light(0x0000ff)
        |> Kino.render()

      assert_output(%{
        labels: ["Leds", "Raw"],
        outputs: [%{
          type: :markdown,
          text: ~s(<span style="color: #FF0000">█</span><span style="color: #00FF00">█</span><span style="color: #0000FF">█</span>),
          chunk: false
        },
        %{
          type: :terminal_text,
          # the field order is not stable :-( Thus we don't compare the actual text
          # text: ~s(%Fledex.Leds{\n  \e[34mcount:\e[0m \e[34m3\e[0m,\n  \e[34mleds:\e[0m %{\e[34m1\e[0m) <>
          #       ~s( => \e[34m16711680\e[0m, \e[34m2\e[0m => \e[34m65280\e[0m, \e[34m3\e[0m => \e[34m255\e[0m}) <>
          #       ~s(,\n  \e[34mopts:\e[0m %{\e[34mnamespace:\e[0m \e[35mnil\e[0m, \e[34mserver_name:\e[0m) <>
          #       ~s( \e[35mnil\e[0m},\n  \e[34mmeta:\e[0m %{\e[34mindex:\e[0m \e[34m4\e[0m}\n}),
          chunk: false
        }],
        type: :tabs
      })
    end
  end
end
