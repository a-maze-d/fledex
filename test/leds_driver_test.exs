defmodule LedDriverTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  doctest Leds

  describe "test init/1" do

    test "init_args are correctly set (disable timer)" do
      {:ok, state} = LedsDriver.init(%{timer: %{disabled: true}})
      assert state.timer.disabled == true
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func != nil
      assert state.timer.ref == nil
    end

    test "init_args are correctly set (with active timer)" do
      update_func = &(&1)
      {:ok, state} = LedsDriver.init(%{timer: %{update_func: update_func}})
      assert state.timer.disabled == false
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func == update_func
      assert state.timer.ref != nil

      assert_receive {:update_timeout, _update_func}
    end

    test "start server" do
      assert match?({:ok, _}, LedsDriver.start_link(%{timer: %{disable: true}}))
    end
  end

  describe "test timer to ensure it reschedules itself" do
    test "handle_info for the update timer timeout" do
      update_func = &(&1)
      LedsDriver.handle_info({:update_timeout, update_func}, LedsDriver.init_state(%{timer: %{counter: 1, update_func: update_func}}))
      assert_receive {:update_timeout, _update_func}
    end
  end

  describe "test transfer_data aspects" do
    test "merging empty namespaces" do
      namespaces = %{}
      assert LedsDriver.merge_namespaces(namespaces) == []
    end
    test "average and combine" do
      led = {0x33, 0x12C, 0x258}
      LedsDriver.avg_and_combine(led, 3) == 0x1164C8
    end
    test "split into subpixels" do
      pixel = 0xFF7722
      assert LedsDriver.split_into_subpixels(pixel) == {0xFF, 0x77, 0x22}
    end
    test "add_subpixels" do
      pixels = [{20, 40, 60}, {20,40,60}, {20,40,60}]
      assert LedsDriver.add_subpixels(pixels) == {60, 120, 180}
    end
    test "merge pixels" do
      pixels = [0,0xFF]
      assert LedsDriver.merge_pixels(pixels) == 0x7F
    end
    test "merge leds" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]
      assert LedsDriver.merge_leds(leds) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end
    test "get_leds" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        jane: [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      }
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]
      # note, the order does not need to be the same as defined above, so
      # we sort the list consistently
      assert Enum.sort(LedsDriver.get_leds(namespaces)) == Enum.sort(leds)
    end
    test "merging 2 namespaces without overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        jane: [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      }
      assert LedsDriver.merge_namespaces(namespaces) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end
    test "merging 2 namespaces with pixel but no subpixel overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
        jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
      }
      assert LedsDriver.merge_namespaces(namespaces) ==
        [0x7F7F00, 0x007F7F, 0x7F007F, 0x007F7F, 0x7F7F00, 0x7F007F]
    end
    test "merging 2 namespaces with subpixel overlap" do
      namespaces = %{
        john: [0xFF00FF, 0x888800, 0x882222],
        jane: [0xFFFF00, 0x008888, 0x220088]
      }
      assert LedsDriver.merge_namespaces(namespaces) ==
        [0xFF7F7F, 0x448844, 0x551155]
    end
  end
  describe "e2e tests" do
    test "e2e flow" do
      state = %{
        led_strip: %{
          driver_module: LedStripDrivers.LoggerDriver
        },
        namespaces: %{
          john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
          jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
        }
      }
      state = LedsDriver.init_led_strip_driver(%{}, state)

      assert LedsDriver.transfer_data(state) == state
    end
  end
  describe "test client API" do
    test "define leds first set" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      response = LedsDriver.handle_call({:define_leds, name}, self(), state)
      assert match?({:reply, {:ok, name},_}, response)
      {_, _, state} = response
      assert map_size(state.namespaces) == 1
      assert Map.keys(state.namespaces) == [:john]
    end
    test "define_leds second name" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      {_, _, state} = LedsDriver.handle_call({:define_leds, name}, self(), state)
      name2 = :jane
      response2 = LedsDriver.handle_call({:define_leds, name2}, self(), state)
      assert match?({:reply, {:ok, name}, _}, response2)
      {_, _, state2} = response2
      assert map_size(state2.namespaces) == 2
      assert Map.keys(state2.namespaces) |> Enum.sort() == [:john, :jane] |> Enum.sort()
    end
    test "test drop_leds" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      {_, _, state} = LedsDriver.handle_call({:define_leds, name}, self(), state)
      name2 = :jane
      {_, _, state} = LedsDriver.handle_call({:define_leds, name2}, self(), state)

      {_, _, state} = LedsDriver.handle_call({:drop_leds, name}, self(), state)
      assert Map.keys(state.namespaces) == [:jane]
    end
    test "test set_leds" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      {_, _, state} = LedsDriver.handle_call({:define_leds, name}, self(), state)

      {_, _, state} = LedsDriver.handle_call({:set_leds, name, leds}, self(), state)
      assert state.namespaces == %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      }
    end
  end
end
