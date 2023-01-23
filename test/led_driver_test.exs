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
end
