# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.LedDriverTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  require Logger

  alias Fledex.Driver.Impl.Logger
  alias Fledex.Driver.Impl.Null
  alias Fledex.LedStrip

  # doctest LedStrip

  describe "test init" do
    test "init_args are correctly set (disable timer)" do
      {:ok, state} = LedStrip.init({:strip_name, [{Null, []}], timer_disabled: true})
      assert state.timer.disabled == true
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func != nil
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
      assert state.timer.ref == nil
      assert state.config.merge_strategy == :cap
      assert state.drivers == [{Null, []}]
      assert state.namespaces == %{}
      assert state.strip_name == :strip_name
    end

    test "init_args are correctly set (with active timer)" do
      update_func = & &1

      {:ok, state} =
        LedStrip.init(
          {:strip_name, [{Null, []}],
           timer_update_func: update_func, timer_only_dirty_update: false}
        )

      assert state.timer.disabled == false
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func == update_func
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
      assert state.timer.ref != nil
      assert state.config.merge_strategy == :cap
      assert state.drivers == [{Null, []}]
      assert state.namespaces == %{}
      assert state.strip_name == :strip_name
      assert_receive {:update_timeout, _update_func}
    end

    test "init args need to be a tuple with 3 elements" do
      assert {:stop, "Init args need to be a 3 element tuple with name, drivers, global configs"} ==
               LedStrip.init([])
    end

    # test "init drivers with single item throws warning" do
    #   global_config = [
    #     timer_disabled: true,
    #     merge_strategy: :cap,
    #   ]

    #   {{:ok, _state}, log} =
    #     with_log(fn ->
    #       LedStrip.init({:strip_name, [{Null, []}], global_config})
    #     end)

    #   assert String.match?(log, ~r/warning/)
    #   assert String.match?(log, ~r/driver_modules is not a list/)
    # end

    test "change config" do
      {:ok, state} = LedStrip.init({:strip_name, [{Null, []}], timer_disabled: true})
      assert state.timer.update_timeout == 50

      {:reply, {:ok, old_value}, state} =
        LedStrip.handle_call(
          {:change_config, [:timer, :update_timeout], 100},
          {self(), :tag},
          state
        )

      assert old_value == 50
      assert state.timer.update_timeout == 100
    end
  end

  describe "test timer to ensure it reschedules itself" do
    test "handle_info for the update timer timeout" do
      update_func = & &1

      LedStrip.handle_info(
        {:update_timeout, update_func},
        LedStrip.init_state(
          :strip_name,
          [],
          timer_counter: 1,
          update_func: update_func
        )
      )

      assert_receive {:update_timeout, _update_func}
    end

    test "ensure the config can be updated in the update function" do
      update_func = fn state ->
        {_old_update_counter, state} =
          get_and_update_in(state, [:timer, :counter], &{&1, &1 + 1})

        state
      end

      state =
        LedStrip.init_state(:strip_name, [], timer_counter: 1, timer_update_func: update_func)

      orig_counter = state.timer.counter
      {:noreply, state} = LedStrip.handle_info({:update_timeout, update_func}, state)
      assert state.timer.counter > orig_counter
    end
  end

  describe "test update shortcutting" do
    test "state is dirty after client calls" do
      {:ok, state} = LedStrip.init({:strip_name, [], timer_disabled: true})
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedStrip.handle_call({:define_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedStrip.handle_call({:set_leds, "name", [0xFF0000]}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedStrip.handle_call({:drop_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
    end

    test "transfer shortcutting" do
      {:ok, state} = LedStrip.init({:strip_name, [], timer_disabled: true})

      state =
        state
        |> put_in([:timer, :is_dirty], false)
        |> put_in([:timer, :only_dirty_updates], true)

      assert state == LedStrip.transfer_data(state)
    end
  end

  describe "test transfer_data aspects" do
    test "merging empty namespaces" do
      namespaces = %{}
      assert LedStrip.merge_namespaces(namespaces, :avg) == []
    end

    test "merge pixels" do
      pixels = [0, 0xFF]
      assert LedStrip.merge_pixels(pixels, :avg) == 0x7F
    end

    test "merge leds" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]

      assert LedStrip.merge_leds(leds, :avg) ==
               [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]

      assert LedStrip.merge_leds(leds, :cap) ==
               [0xFF0000, 0x00FF00, 0x0000FF, 0x0000FF, 0x00FF00, 0xFF0000]

      assert_raise ArgumentError, ~r/Unknown merge strategy/, fn ->
        LedStrip.merge_leds(leds, :non_existant)
      end
    end

    test "merge leds of different length" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]

      assert LedStrip.merge_leds(leds, :avg) ==
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
      assert Enum.sort(LedStrip.get_leds(namespaces)) == Enum.sort(leds)
    end

    test "merging 2 namespaces without overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        jane: [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      }

      assert LedStrip.merge_namespaces(namespaces, :avg) ==
               [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
    end

    test "merging 2 namespaces with pixel but no subpixel overlap" do
      namespaces = %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
        jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
      }

      assert LedStrip.merge_namespaces(namespaces, :avg) ==
               [0x7F7F00, 0x007F7F, 0x7F007F, 0x007F7F, 0x7F7F00, 0x7F007F]
    end

    test "merging 2 namespaces with subpixel overlap" do
      namespaces = %{
        john: [0xFF00FF, 0x888800, 0x882222],
        jane: [0xFFFF00, 0x008888, 0x220088]
      }

      assert LedStrip.merge_namespaces(namespaces, :avg) ==
               [0xFF7F7F, 0x448844, 0x551155]
    end
  end

  describe "e2e tests" do
    test "e2e flow" do
      drivers = [
        {Logger, update_freq: 1, log_color_code: false}
      ]

      global_config = [
        timer_counter: 0,
        timer_is_dirty: true,
        merge_strategy: :avg,
        namespaces: %{
          john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
          jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
        }
      ]

      state = LedStrip.init_state(:strip_name, drivers, global_config)

      assert capture_io(fn ->
               response = LedStrip.transfer_data(state)
               assert response.timer.is_dirty == false
             end) ==
               "\e[38;5;100m█\e[38;5;30m█\e[38;5;90m█\e[38;5;30m█\e[38;5;100m█\e[38;5;90m█\r\n"
    end
  end

  describe "test client API (on server side)" do
    test "define leds first set" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      response = LedStrip.handle_call({:define_namespace, name}, self(), state)
      assert match?({:reply, :ok, _}, response)
      {:reply, _na, state} = response
      assert map_size(state.namespaces) == 1
      assert Map.keys(state.namespaces) == [:john]
    end

    test "define_namespace second name" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      {:reply, _na, state} = LedStrip.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      response2 = LedStrip.handle_call({:define_namespace, name2}, self(), state)
      assert match?({:reply, :ok, _}, response2)
      {:reply, _na, state2} = response2
      assert map_size(state2.namespaces) == 2
      assert Map.keys(state2.namespaces) |> Enum.sort() == [:john, :jane] |> Enum.sort()
    end

    test "define namespace again gives error" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      assert {:reply, :ok, state} = LedStrip.handle_call({:define_namespace, name}, self(), state)

      assert {:reply, {:error, message}, _state} =
               LedStrip.handle_call({:define_namespace, name}, self(), state)

      assert String.match?(message, ~r/namespace already exists/)
    end

    test "test drop_namespace" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      {:reply, _na, state} = LedStrip.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      {:reply, _na, state} = LedStrip.handle_call({:define_namespace, name2}, self(), state)

      {:reply, _na, state} = LedStrip.handle_call({:drop_namespace, name}, self(), state)
      assert Map.keys(state.namespaces) == [:jane]
    end

    test "test set_leds" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      {:reply, :ok, state} = LedStrip.handle_call({:define_namespace, name}, self(), state)

      {:reply, :ok, state} = LedStrip.handle_call({:set_leds, name, leds}, self(), state)

      assert state.namespaces == %{
               john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
             }
    end

    test "test set leds without namespace" do
      {:ok, state} = LedStrip.init({:strip_name, [], []})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      # {:reply, _na, state} = LedStrip.handle_call({:define_namespace, name}, self(), state)

      {:reply, {:error, message}, _state} =
        LedStrip.handle_call({:set_leds, name, leds}, self(), state)

      assert String.match?(message, ~r/no such namespace/)
    end
  end
end

defmodule Fledex.LedStripTest.TestDriver do
  @behaviour Fledex.Driver.Interface

  import ExUnit.Assertions

  def configure(config) do
    config
  end

  def init(config) do
    assert Keyword.get(config, :test, nil) == 123
    Keyword.put_new(config, :test2, 321)
  end

  def reinit(old_config, new_config) do
    assert Keyword.get(old_config, :test2, nil) == 123
    old_config = Keyword.put_new(old_config, :test3, "abc")
    Keyword.merge(old_config, new_config)
  end

  def transfer(_leds, _counter, config) do
    {config, :ok}
  end

  def terminate(_reason, config) do
    assert Keyword.get(config, :test, nil) == 321
    assert Keyword.get(config, :test2, nil) == 123
    assert Keyword.get(config, :test3, nil) == "abc"
    :ok
  end
end

defmodule Fledex.LedStripTestSync do
  use ExUnit.Case
  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Impl.Spi
  alias Fledex.LedStrip

  @strip_name :test_strip
  setup do
    {:ok, pid} =
      start_supervised(%{
        id: LedStrip,
        start:
          {LedStrip, :start_link,
           [
             @strip_name,
             {
               Fledex.LedStripTest.TestDriver,
               [test: 123]
             },
             [timer_disable: true]
           ]}
      })

    %{strip_name: @strip_name, pid: pid}
  end

  @namespace :namespace
  describe "startup tests" do
    test "start server with custom parameters" do
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name, {Null, []}, timer_disable: true)
      :ok = GenServer.stop(pid)
    end

    test "start server with default parameters" do
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name1)
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name2, Null)
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name3, Spi)
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name4, [{Null, []}, {Spi, []}])
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name5, Null, [])
      :ok = GenServer.stop(pid)
    end

    test "client API calls", %{strip_name: strip_name} do
      # we only make sure that they are correctly wired to the server side calls
      # that are tested independently
      assert :ok == LedStrip.define_namespace(strip_name, @namespace)
      assert true == LedStrip.exist_namespace(strip_name, @namespace)
      assert :ok == LedStrip.set_leds(strip_name, @namespace, [0xFF0000, 0x00FF00, 0x0000FF])

      assert {:ok, test2: 321, test: 123} ==
               LedStrip.change_config(
                 strip_name,
                 [:drivers, Access.at!(0), Access.elem(1)],
                 test: 321,
                 test2: 123
               )

      assert :ok == LedStrip.reinit(strip_name, [{Fledex.LedStripTest.TestDriver, []}], [])
      assert :ok == LedStrip.drop_namespace(strip_name, @namespace)
      assert :ok == GenServer.stop(strip_name)
    end
  end
end

defmodule Fledex.LedStripTestSync2 do
  use ExUnit.Case
  alias Fledex.LedStrip

  @strip_name :test_strip_sync2
  setup do
    {:ok, pid} =
      start_supervised(%{
        id: LedStrip,
        start:
          {LedStrip, :start_link,
           [
             @strip_name,
             [
               {
                 Fledex.LedStripTest.TestDriver,
                 [test: 123]
               }
             ],
             [timer_disable: true]
           ]}
      })

    %{strip_name: @strip_name, pid: pid}
  end

  @namespace :namespace
  describe "test default server_name" do
    test "client API calls", %{strip_name: strip_name} do
      # we only make sure that they are correctly wired to the server side calls
      # that are tested independently
      assert :ok == LedStrip.define_namespace(strip_name, @namespace)
      assert true == LedStrip.exist_namespace(strip_name, @namespace)
      assert :ok == LedStrip.set_leds(strip_name, @namespace, [0xFF0000, 0x00FF00, 0x0000FF])

      assert {:ok, [test2: 321, test: 123]} =
               LedStrip.change_config(
                 strip_name,
                 [:drivers, Access.at!(0), Access.elem(1)],
                 test: 321,
                 test2: 123
               )

      assert :ok == LedStrip.reinit(strip_name, {Fledex.LedStripTest.TestDriver, []}, [])
      assert :ok == LedStrip.drop_namespace(strip_name, @namespace)
      assert :ok == GenServer.stop(strip_name)
    end
  end
end
