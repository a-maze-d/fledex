defmodule LedDriverTest do
  use ExUnit.Case
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
      assert {:ok, _} = LedsDriver.start_link(%{timer: %{disable: true}})
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
    test "split into subpixels" do
      pixel = 0xFF7722
      assert LedsDriver.split_into_subpixels(pixel) == {0xFF, 0x77, 0x22}
    end
    test "merge pixels" do
      pixels = [0,0xFF]
      assert LedsDriver.merge_pixels(pixels) == 0x7F
    end
    test "merging 2 namespaces without overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        jane: [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      }
      assert LedsDriver.merge_namespaces(namespaces) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end
  end
end
