defmodule Fledex.LedDriverTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  require Logger

  alias Fledex.Driver.Impl.Logger
  alias Fledex.Driver.Impl.Null
  alias Fledex.LedsDriver

  # doctest LedsDriver

  describe "test init" do
    test "init_args are correctly set (disable timer)" do
      {:ok, state} = LedsDriver.init({%{timer: %{disabled: true}}, :strip_name})
      assert state.timer.disabled == true
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func != nil
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
      assert state.timer.ref == nil
      assert state.led_strip.merge_strategy == :avg
      assert state.led_strip.driver_modules == [Null]
      assert state.led_strip.config == %{Null => %{}}
      assert state.namespaces == %{}
      assert state.strip_name == :strip_name
    end
    test "init_args are correctly set (with active timer)" do
      update_func = &(&1)
      {:ok, state} = LedsDriver.init({%{
        timer: %{
          update_func: update_func,
          only_dirty_update: false
        }
      }, :strip_name})
      assert state.timer.disabled == false
      assert state.timer.counter == 0
      assert state.timer.update_timeout == 50
      assert state.timer.update_func == update_func
      assert state.timer.only_dirty_update == false
      assert state.timer.is_dirty == false
      assert state.timer.ref != nil
      assert state.led_strip.merge_strategy == :avg
      assert state.led_strip.driver_modules == [Null]
      assert state.led_strip.config == %{Null => %{}}
      assert state.namespaces == %{}
      assert state.strip_name == :strip_name
      assert_receive {:update_timeout, _update_func}
    end
    test "init args need to be a map" do
      assert {:stop, "Init args need to be a map"} == LedsDriver.init([])
    end
    test "init drivers with single item throws warning" do
      config = %{
        timer: %{disabled: true},
        led_strip: %{
          merge_strategy: :cap,
          driver_modules: Null
        }
      }
      {{:ok, _state}, log} = with_log(fn ->
        LedsDriver.init({config, :strip_name})
      end)
      assert String.match?(log, ~r/warning/)
      assert String.match?(log, ~r/driver_modules is not a list/)
    end
    test "change config" do
      {:ok, state} = LedsDriver.init({%{timer: %{disabled: true}}, :strip_name})
      assert state.timer.update_timeout == 50
      {:reply, {:ok, old_value}, state} = LedsDriver.handle_call(
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
      update_func = &(&1)
      LedsDriver.handle_info(
        {:update_timeout, update_func},
        LedsDriver.init_state(%{timer: %{counter: 1, update_func: update_func}}, :strip_name)
      )
      assert_receive {:update_timeout, _update_func}
    end
    test "ensure the config can be updated in the update function" do
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
      state = LedsDriver.init_state(init_args, :strip_name)
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
      {:ok, state} = LedsDriver.init({%{timer: %{disabled: true}}, :strip_name})
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedsDriver.handle_call({:define_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedsDriver.handle_call({:set_leds, "name", [0xFF0000]}, self(), state)
      assert state.timer.is_dirty == true
      state = put_in(state, [:timer, :is_dirty], false)
      assert state.timer.is_dirty == false
      {:reply, _na, state} = LedsDriver.handle_call({:drop_namespace, "name"}, self(), state)
      assert state.timer.is_dirty == true
    end
    test "transfer shortcutting" do
      {:ok, state} = LedsDriver.init({%{timer: %{disabled: true}}, :strip_name})
      state = state
        |> put_in([:timer, :is_dirty], false)
        |> put_in([:timer, :only_dirty_updates], true)
      assert state == LedsDriver.transfer_data(state)
    end
  end

  describe "test transfer_data aspects" do
    test "merging empty namespaces" do
      namespaces = %{}
      assert LedsDriver.merge_namespaces(namespaces, :avg) == []
    end
    test "merge pixels" do
      pixels = [0, 0xFF]
      assert LedsDriver.merge_pixels(pixels, :avg) == 0x7F
    end
    test "merge leds" do
      leds = [
        [0xFF0000, 0x00FF00, 0x0000FF, 0x000000, 0x000000, 0x000000],
        [0x000000, 0x000000, 0x000000, 0x0000FF, 0x00FF00, 0xFF0000]
      ]
      assert LedsDriver.merge_leds(leds, :avg) ==
        [0x7F0000, 0x007F00, 0x00007F, 0x00007F, 0x007F00, 0x7F0000]
      assert LedsDriver.merge_leds(leds, :cap) ==
        [0xFF0000, 0x00FF00, 0x0000FF, 0x0000FF, 0x00FF00, 0xFF0000]
      assert_raise ArgumentError, ~r/Unknown merge strategy/, fn ->
         LedsDriver.merge_leds(leds, :non_existant)
      end
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
          driver_modules: [Logger],
          config: %{update_freq: 1, log_color_code: false}
        },
        namespaces: %{
          john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF],
          jane: [0x00FF00, 0x0000FF, 0xFF0000, 0x0000FF, 0x00FF00, 0xFF0000]
        }
      }
      state = LedsDriver.init_state(init_args, :strip_name)
        |> LedsDriver.init_driver()

      assert capture_io(fn ->
        response = LedsDriver.transfer_data(state)
        assert response.timer.is_dirty == false
      end) == "\e[38;5;100m█\e[38;5;30m█\e[38;5;90m█\e[38;5;30m█\e[38;5;100m█\e[38;5;90m█\r\n"

    end
  end

  describe "test client API (on server side)" do
    test "define leds first set" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      response = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      assert match?({:reply, :ok, _}, response)
      {:reply, _na, state} = response
      assert map_size(state.namespaces) == 1
      assert Map.keys(state.namespaces) == [:john]
    end
    test "define_namespace second name" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      {:reply, _na, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      response2 = LedsDriver.handle_call({:define_namespace, name2}, self(), state)
      assert match?({:reply, :ok, _}, response2)
      {:reply, _na, state2} = response2
      assert map_size(state2.namespaces) == 2
      assert Map.keys(state2.namespaces) |> Enum.sort() == [:john, :jane] |> Enum.sort()
    end
    test "define namespace again gives error" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      assert {:reply, :ok, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      assert {:reply, {:error, message}, _state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      assert String.match?(message, ~r/namespace already exists/)
    end
    test "test drop_namespace" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      {:reply, _na, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)
      name2 = :jane
      {:reply, _na, state} = LedsDriver.handle_call({:define_namespace, name2}, self(), state)

      {:reply, _na, state} = LedsDriver.handle_call({:drop_namespace, name}, self(), state)
      assert Map.keys(state.namespaces) == [:jane]
    end
    test "test set_leds" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      {:reply, :ok, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)

      {:reply, :ok, state} = LedsDriver.handle_call({:set_leds, name, leds}, self(), state)
      assert state.namespaces == %{
        john: [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      }
    end
    test "test set leds without namespace" do
      {:ok, state} = LedsDriver.init({%{}, :strip_name})
      name = :john
      leds = [0xFF0000, 0x00FF00, 0x0000FF, 0x00FF00, 0xFF0000, 0x0000FF]
      # {:reply, _na, state} = LedsDriver.handle_call({:define_namespace, name}, self(), state)

      {:reply, {:error, message}, _state} = LedsDriver.handle_call({:set_leds, name, leds}, self(), state)
      assert String.match?(message, ~r/no such namespace/)
    end
  end
end

defmodule Fledex.LedsDriverTest.TestDriver do
  @behaviour Fledex.Driver.Interface

  import ExUnit.Assertions

  def init(module_init_args) do
    assert module_init_args.test == 123
    Map.put_new(module_init_args, :test2, 321)
  end
  def reinit(module_config) do
    assert module_config == %{test: 321, test2: 123}
    Map.put_new(module_config, :test3, "abc")
  end
  def transfer(_leds, _counter, config) do
    {config, :ok}
  end
  def terminate(_reason, config) do
    assert config == %{test: 321, test2: 123, test3: "abc"}
    :ok
  end
end
defmodule Fledex.LedsDriverTestSync do
  use ExUnit.Case
  alias Fledex.LedsDriver

  @strip_name :test_strip
  setup do
    {:ok, pid} = start_supervised(
      %{
        id: LedsDriver,
        start: {LedsDriver, :start_link, [@strip_name, %{
          timer: %{disable: true},
          led_strip: %{
            driver_modules: [Fledex.LedsDriverTest.TestDriver],
            config: %{
              Fledex.LedsDriverTest.TestDriver => %{test: 123}
            }
          }
        }]}
      })
    %{strip_name: @strip_name,
      pid: pid}
  end

  @namespace :namespace
  describe "startup tests" do
    test "start server with custom parameters" do
      assert {:ok, pid} = LedsDriver.start_link(:test_strip_name, %{timer: %{disable: true}})
      :ok = GenServer.stop(pid)
    end
    test "start server with default parameters" do
      assert {:ok, pid} = LedsDriver.start_link()
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedsDriver.start_link(:test_strip_name1)
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedsDriver.start_link(:test_strip_name2, :none)
      :ok = GenServer.stop(pid)
      assert {:ok, pid} = LedsDriver.start_link(:test_strip_name3, :spi)
      :ok = GenServer.stop(pid)
    end
    test "client API calls", %{strip_name: strip_name} do
      # we only make sure that they are correctly wired to the server side calls
      # that are tested independently
      assert :ok == LedsDriver.define_namespace(strip_name, @namespace)
      assert true == LedsDriver.exist_namespace(strip_name, @namespace)
      assert :ok == LedsDriver.set_leds(strip_name, @namespace, [0xff0000, 0x00ff00, 0x0000ff])
      assert {:ok, %{test: 123, test2: 321}} == LedsDriver.change_config(strip_name,
        [:led_strip, :config, Fledex.LedsDriverTest.TestDriver],
        %{test: 321, test2: 123}
      )
      assert :ok == LedsDriver.reinit_drivers(strip_name)
      assert :ok == LedsDriver.drop_namespace(strip_name, @namespace)
      assert :ok == GenServer.stop(strip_name)
    end
  end
end

defmodule Fledex.LedsDriverTestSync2 do
  use ExUnit.Case
  alias Fledex.LedsDriver

  setup do
    {:ok, _pid} = start_supervised(
      %{
        id: LedsDriver,
        start: {LedsDriver, :start_link, [Fledex.LedsDriver, %{
          timer: %{disable: true},
          led_strip: %{
            driver_modules: [Fledex.LedsDriverTest.TestDriver],
            config: %{
              Fledex.LedsDriverTest.TestDriver => %{test: 123}
            }
          }
        }]}
      })
      %{}
  end

  @namespace :namespace
  describe "test default server_name" do
    test "client API calls" do
      # we only make sure that they are correctly wired to the server side calls
      # that are tested independently
      assert :ok == LedsDriver.define_namespace(@namespace)
      assert true == LedsDriver.exist_namespace(@namespace)
      assert :ok == LedsDriver.set_leds(@namespace, [0xff0000, 0x00ff00, 0x0000ff])
      assert {:ok, %{test: 123, test2: 321}} == LedsDriver.change_config(
        [:led_strip, :config, Fledex.LedsDriverTest.TestDriver],
        %{test: 321, test2: 123}
      )
      assert :ok == LedsDriver.reinit_drivers()
      assert :ok == LedsDriver.drop_namespace(@namespace)
      assert :ok == GenServer.stop(Fledex.LedsDriver)
    end
  end
end
