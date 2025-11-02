# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.LedStripTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  require Logger

  alias Fledex.Driver.Impl.Logger
  alias Fledex.Driver.Impl.Null
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem

  # doctest LedStrip

  setup do
    {:ok, _pid} = start_supervised(AnimationSystem.child_spec())
    :ok
  end

  describe "test init" do
    test "init_args are correctly set (disable timer)" do
      {:ok, state} = LedStrip.init({:strip_name, [{Null, []}], timer_disabled: true})
      assert state.config.timer.disabled == true
      assert state.config.timer.counter == 0
      assert state.config.timer.update_timeout == 50
      assert state.config.timer.update_func != nil
      assert state.config.timer.only_dirty_update == false
      assert state.config.timer.is_dirty == false
      assert state.config.timer.ref == nil
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

      assert state.config.timer.disabled == false
      assert state.config.timer.counter == 0
      assert state.config.timer.update_timeout == 50
      assert state.config.timer.update_func == update_func
      assert state.config.timer.only_dirty_update == false
      assert state.config.timer.is_dirty == false
      assert state.config.timer.ref != nil
      assert state.config.merge_strategy == :cap
      assert state.drivers == [{Null, []}]
      assert state.namespaces == %{}
      assert state.strip_name == :strip_name
      assert_receive {:update_timeout, _update_func}
    end

    test "init args need to be a tuple with 3 elements" do
      assert {:stop, "Init args need to be a 3 element tuple with name, drivers, global config"} ==
               LedStrip.init([])
    end

    test "change config" do
      {:ok, state} = LedStrip.init({:strip_name, [{Null, []}], timer_disabled: true})
      assert state.config.timer.update_timeout == 50

      {:reply, {:ok, old_values}, state} =
        LedStrip.handle_call(
          {:change_config, timer_update_timeout: 100},
          {self(), :tag},
          state
        )

      assert old_values == [timer_update_timeout: 50]
      assert state.config.timer.update_timeout == 100
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
          timer_update_func: update_func
        )
      )

      assert_receive {:update_timeout, _update_func}
    end

    test "ensure the config can be updated in the update function" do
      update_func = fn state ->
        {_old_update_counter, state} =
          get_and_update_in(state, [:config, :timer, :counter], &{&1, &1 + 1})

        state
      end

      state =
        LedStrip.init_state(:strip_name, [], timer_counter: 1, timer_update_func: update_func)

      orig_counter = state.config.timer.counter
      {:noreply, state} = LedStrip.handle_info({:update_timeout, update_func}, state)
      assert state.config.timer.counter > orig_counter
    end
  end

  describe "test update shortcutting" do
    test "state is dirty after client calls" do
      {:ok, state} = LedStrip.init({:strip_name, [], timer_disabled: true})
      assert state.config.timer.is_dirty == false
      {:reply, _na, state} = LedStrip.handle_call({:define_namespace, :name}, self(), state)
      assert state.config.timer.is_dirty == true
      state = put_in(state, [:config, :timer, :is_dirty], false)
      assert state.config.timer.is_dirty == false

      {:reply, _na, state} =
        LedStrip.handle_call({:set_leds, :name, [0xFF0000], 1}, self(), state)

      assert state.config.timer.is_dirty == true
      state = put_in(state, [:config, :timer, :is_dirty], false)
      assert state.config.timer.is_dirty == false
      {:reply, _na, state} = LedStrip.handle_call({:drop_namespace, :name}, self(), state)
      assert state.config.timer.is_dirty == true
    end

    test "transfer shortcutting" do
      {:ok, state} = LedStrip.init({:strip_name, [], timer_disabled: true})

      state =
        state
        |> put_in([:config, :timer, :is_dirty], false)
        |> put_in([:config, :timer, :only_dirty_updates], true)

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
        {Logger, update_freq: 1, color: false}
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
               assert response.config.timer.is_dirty == false
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
      {:reply, :ok, state} = response
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

      {:reply, :ok, state} =
        LedStrip.handle_call({:set_leds, name, leds, length(leds)}, self(), state)

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
        LedStrip.handle_call({:set_leds, name, leds, length(leds)}, self(), state)

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

  def init(config, _global_config) do
    assert Keyword.get(config, :test, nil) == 123
    Keyword.put_new(config, :test2, 321)
  end

  def reinit(old_config, new_config, _global_config) do
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
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  require Logger
  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Impl.Spi
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.Utils

  setup do
    start_supervised(AnimationSystem.child_spec())
    :ok
  end

  describe "startup tests" do
    test "start server with custom parameters" do
      assert {:ok, pid} = LedStrip.start_link(:test_strip_name, {Null, []}, timer_disabled: true)
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

      assert {:error, _message} =
               LedStrip.start_link(:test_strop_name6, %{wrong: "structure"}, [])
    end

    test "start server a second time" do
      {:ok, pid} = AnimationSystem.start_led_strip(:test_strip_name6)

      # {:ok, pid} = LedStrip.start_link(:test_strip_name1)
      assert {:ok, pid} == AnimationSystem.start_led_strip(:test_strip_name6)
      # assert {:ok, pid} == LedStrip.start_link(:test_strip_name1)
    end
  end

  describe "test LedStrip client APIs" do
    @strip_name :strip_name
    @namespace :namespace

    setup do
      start_supervised(AnimationSystem.child_spec())
      :ok
    end

    test "client API calls" do
      {:ok, _pid} = AnimationSystem.start_led_strip(@strip_name, [{Null, []}], [])

      # we only make sure that they are correctly wired to the server side calls
      # that are tested independently
      assert :ok == LedStrip.define_namespace(@strip_name, @namespace)
      assert LedStrip.exist_namespace(@strip_name, @namespace)
      assert not LedStrip.exist_namespace(@strip_name, :non_existent)
      assert :ok == LedStrip.set_leds(@strip_name, @namespace, [0xFF0000, 0x00FF00, 0x0000FF], 3)
      assert :ok == LedStrip.set_leds(@strip_name, @namespace, [0xFF0000, 0x00FF00, 0x0000FF])

      # stipid options
      assert :ok ==
               LedStrip.set_leds_with_rotation(
                 @strip_name,
                 @namespace,
                 [0xFF0000, 0x00FF00, 0x0000FF],
                 3,
                 offset: nil,
                 rotate_left: :blue
               )

      assert :ok ==
               LedStrip.set_leds_with_rotation(
                 @strip_name,
                 @namespace,
                 [0xFF0000, 0x00FF00, 0x0000FF],
                 3,
                 offset: -1
               )

      # stupid options and no led count
      assert :ok ==
               LedStrip.set_leds_with_rotation(
                 @strip_name,
                 @namespace,
                 [0xFF0000, 0x00FF00, 0x0000FF],
                 offset: -1
               )

      # successful config change
      assert {:ok, timer_counter: 0} = LedStrip.change_config(@strip_name, timer_counter: 1)

      led_strip_pid =
        Supervisor.which_children(Utils.supervisor_name(@strip_name))
        |> Enum.filter(fn {_name, _pid, type, _module} -> type == :worker end)
        |> List.first()
        |> elem(1)

      assert %{config: %{timer: %{counter: 1}}} = :sys.get_state(led_strip_pid)

      # unsuccessful config change
      assert capture_log(fn ->
               assert {:ok, []} = LedStrip.change_config(@strip_name, counter: 2)
             end) =~ "Unknown config key (:counter with value 2) was specified"

      assert %{config: %{timer: %{counter: 1}}} = :sys.get_state(led_strip_pid)

      # test all 3 reinit functions (they all lead to the same result)
      # This is the reason why we expect the configure and reinit to be called 3 times
      assert :ok == LedStrip.reinit(@strip_name, Null, [])
      assert :ok == LedStrip.reinit(@strip_name, {Null, []}, [])
      assert :ok == LedStrip.reinit(@strip_name, [{Null, []}], [])
    end
  end
end
