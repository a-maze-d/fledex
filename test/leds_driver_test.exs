defmodule Fledex.LedDriverTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Fledex.LedsDriver
  alias Fledex.LedStripDriver.LoggerDriver

  doctest LedsDriver

  describe "test init/1" do
    test "init_args are correctly set (disable timer)" do
      {:ok, state} = LedsDriver.init(%{timer: %{disabled: true}})
      assert state.timer.disabled == true
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func != nil
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
      assert state.timer.ref == nil
    end

    test "init_args are correctly set (with active timer)" do
      update_func = &(&1)
      {:ok, state} = LedsDriver.init(%{
        timer: %{
          update_func: update_func,
          only_dirty_update: false
        }
      })
      assert state.timer.disabled == false
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func == update_func
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
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
    test "ensure the state can be updated in the update function" do
      update_func = fn(state) ->
        {_old_update_counter, state} = get_and_update_in(state, [:led_strip, :update_counter], &{&1, &1 + 1})
        state
      end
      init_args = %{
        timer: %{
          counter: 1,
          update_func: update_func
        },
      }
      state = LedsDriver.init_state(init_args)
      state = %{state | led_strip: %{
        update_counter: 0
      }}
      orig_counter = state.led_strip.update_counter
      {:noreply, state} = LedsDriver.handle_info({:update_timeout, update_func}, state)
      assert state.led_strip.update_counter > orig_counter
    end
  end

  describe "test update shortcutting" do
    test "state is dirty after client calls" do
      {:ok, state} = LedsDriver.init(%{timer: %{disabled: true}})
      assert state.timer.is_dirty == false
      {:reply, _, state} = LedsDriver.handle_call({:define_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _, state} = LedsDriver.handle_call({:set_leds, "name", [0xFF0000]}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _, state} = LedsDriver.handle_call({:drop_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
    end
  end
  describe "test transfer_data aspects" do
    test "merging empty namespaces" do
      namespaces = %{}
      assert LedsDriver.merge_namespaces(namespaces, :avg) == []
    end
    test "merge pixels" do
      pixels = [0,0xFF]
      assert LedsDriver.merge_pixels(pixels, :avg) == 0x7F
    end
    test "merge leds" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]
      assert LedsDriver.merge_leds(leds, :avg) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end
    test "merge leds of different length" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]
      assert LedsDriver.merge_leds(leds, :avg) ==
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
      assert LedsDriver.merge_namespaces(namespaces, :avg) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end
    test "merging 2 namespaces with pixel but no subpixel overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
        jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
      }
      assert LedsDriver.merge_namespaces(namespaces, :avg) ==
        [0x7F7F00, 0x007F7F, 0x7F007F, 0x007F7F, 0x7F7F00, 0x7F007F]
    end
    test "merging 2 namespaces with subpixel overlap" do
      namespaces = %{
        john: [0xFF00FF, 0x888800, 0x882222],
        jane: [0xFFFF00, 0x008888, 0x220088]
      }
      assert LedsDriver.merge_namespaces(namespaces, :avg) ==
        [0xFF7F7F, 0x448844, 0x551155]
    end
  end
  describe "e2e tests" do
    test "e2e flow" do
      init_args = %{
        timer: %{counter: 0, is_dirty: true},
        led_strip: %{
          driver_module: LoggerDriver,
          config: %{update_freq: 1, log_color_code: false}
        },
        namespaces: %{
          john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
          jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
        }
      }
      state = LedsDriver.init_state(init_args)

      assert capture_io( fn ->
        response = LedsDriver.transfer_data(state)
        assert response.timer.is_dirty == false
      end) == "\e[38;5;100m█\e[38;5;30m█\e[38;5;90m█\e[38;5;30m█\e[38;5;100m█\e[38;5;90m█\r\n"

    end
  end
  describe "test client API" do
    test "define leds first set" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      response = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      assert match?({:reply, {:ok, _},_}, response)
      {_, _, state} = response
      assert map_size(state.namespaces) == 1
      assert Map.keys(state.namespaces) == [:john]
    end
    test "define_namespace second name" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      {_, _, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      response2 = LedsDriver.handle_call({:define_namespace, name2}, self(), state)
      assert match?({:reply, {:ok, _}, _}, response2)
      {_, _, state2} = response2
      assert map_size(state2.namespaces) == 2
      assert Map.keys(state2.namespaces) |> Enum.sort() == [:john, :jane] |> Enum.sort()
    end
    test "test drop_namespace" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      {_, _, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      {_, _, state} = LedsDriver.handle_call({:define_namespace, name2}, self(), state)

      {_, _, state} = LedsDriver.handle_call({:drop_namespace, name}, self(), state)
      assert Map.keys(state.namespaces) == [:jane]
    end
    test "test set_leds" do
      {:ok, state} = LedsDriver.init(%{})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      {_, _, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)

      {_, _, state} = LedsDriver.handle_call({:set_leds, name, leds}, self(), state)
      assert state.namespaces == %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      }
    end
  end
end
