# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.TestEffect do
  use Fledex.Effect.Interface

  def apply(leds, count, _config, triggers, _context) do
    {leds, count, triggers}
  end
end

defmodule Fledex.Animation.AnimatorTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Utils
  alias Fledex.Driver.Impl.Null
  alias Fledex.Effect.Rotation
  alias Fledex.Effect.Wanish
  alias Fledex.Leds
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.WorkerSupervisor

  def default_def_func(_triggers) do
    Leds.leds(30)
  end

  def default_send_config_func(_triggers) do
    [namespace: "test"]
  end

  # some logging versions to test the workflow
  def logging_def_func(triggers) do
    counter = triggers[:test_strip] || "undefined"
    Logger.info("creating led definition, #{counter}")
    Leds.leds(30)
  end

  def logging_send_config_func(triggers) do
    counter = triggers[:test_strip] || "undefined"
    Logger.info("creating send config, #{counter}")
    [namespace: "test#{ExUnit.configuration()[:seed]}"]
  end

  @strip_name :test_strip
  setup do
    # {:ok, pid} =
    start_supervised(AnimationSystem.child_spec())
    {:ok, pid} = WorkerSupervisor.start_led_strip(@strip_name, Null, [])
    # start_supervised(%{
    #   id: LedStrip,
    #   start: {LedStrip, :start_link, [@strip_name, Null]}
    # })

    %{strip_name: @strip_name, pid: pid}
  end

  describe "init" do
    test "config applied correctly (all set)" do
      init_args = %{
        def_func: &default_def_func/1,
        effects: [],
        strip_name: :test_strip,
        animation_name: :test_animation,
        triggers: %{},
        type: :animation,
        options: [send_config_func: &default_send_config_func/1]
      }

      {:ok, state, {:continue, :paint_once}} =
        Animator.init({init_args, :test_strip, :test_animation})

      assert state == init_args
    end

    test "default funcs" do
      init_args = %{type: :animation}

      {:ok, state, {:continue, :paint_once}} =
        Animator.init({init_args, :test_strip, :test_animation})

      assert Leds.leds() == state.def_func.(%{test_strip: 10})
      # assert %{} == state.send_config_func.(%{test_strip: 10})
    end

    test "config applied correctly (none_set)" do
      init_args = %{type: :animation}

      {:ok, state, {:continue, :paint_once}} =
        Animator.init({init_args, :test_strip, :test_animation})

      assert state.def_func != nil
      assert state.strip_name == :test_strip
      assert state.animation_name == :test_animation
    end

    test "update leds (with arity 2)", %{strip_name: strip_name} do
      animation_name = :arity

      state = %{
        strip_name: strip_name,
        animation_name: animation_name,
        def_func: fn triggers, options ->
          assert Keyword.has_key?(options, :coffee)
          assert Keyword.fetch!(options, :coffee) == :filter
          assert Map.has_key?(triggers, strip_name)
          assert Map.fetch!(triggers, strip_name) == 215
          Leds.leds(10)
        end,
        options: [coffee: :filter],
        effects: [],
        triggers: %{strip_name => 214}
      }

      triggers = %{
        strip_name => 215
      }

      LedStrip.define_namespace(strip_name, animation_name)
      {:noreply, _new_state} = Animator.handle_info({:trigger, triggers}, state)
    end

    test "reconfigure effects", %{strip_name: strip_name} do
      animation_name = :update_effect
      LedStrip.define_namespace(strip_name, animation_name)
      Animator.update_effect(strip_name, animation_name, :all, enable: true)
    end
  end

  describe "test triggers" do
    test "merging triggers" do
      {:noreply, state} = Animator.handle_info({:trigger, %{test_strip: 10}}, %{triggers: %{}})
      assert state.triggers.test_strip == 10

      {:noreply, state} =
        Animator.handle_info({:trigger, %{test_strip: 11, new_strip: 10}}, state)

      assert state.triggers.test_strip == 11
      assert state.triggers.new_strip == 10
    end
  end

  describe "client API" do
    test "config" do
      init_args = %{
        def_func: &default_def_func/1,
        send_config_func: &default_send_config_func/1,
        strip_name: :test_strip,
        animation_name: :test_animation,
        triggers: %{},
        type: :animation
      }

      assert map_size(init_args.triggers) == 0

      {:ok, state, {:continue, :paint_once}} =
        Animator.init({init_args, :test_strip, :test_animation})

      assert map_size(init_args.triggers) == 0
      assert Keyword.has_key?(state.options, :send_config)

      new_config = %{triggers: %{abc: 10}}
      {:noreply, state} = Animator.handle_cast({:config, new_config}, state)

      assert state.def_func != init_args.def_func
      assert state.strip_name == init_args.strip_name
      assert state.animation_name == init_args.animation_name
      assert state.triggers != init_args.triggers
      assert map_size(state.triggers) == 1
      assert state.triggers.abc == 10
      assert state.type == init_args.type
    end
  end

  describe "test workflow" do
    # what is important is to check whether our def and send functions are called
    # repeatedly. and that our trigger is incrementing properly.
    # for this we start an animation, let it run for a while and capture the logs
    # once we have shut down the animation we validate the logs that the functions
    # are called alternatingly and that the trigger is incrementing as expected
    test "validate continuous workflow", %{strip_name: strip_name, pid: pid} do
      # ensure our driver is running
      assert Process.alive?(pid)

      capture_log([], fn ->
        run_simple_workflow(strip_name)
      end)
      |> assert_logs()

      # ensure our animator did not kill our driver while shutting down
      assert Process.alive?(pid)
    end

    def run_simple_workflow(strip_name) do
      start_server(strip_name)
      |> wait()
      |> shutdown_server()
    end

    def assert_logs(logs) do
      # IO.puts(logs)
      logs
      # we start with some simple transformation and cleanup of the log lines to
      # get to what really interests us
      |> String.split("\n")
      |> Enum.filter(fn line -> String.match?(line, ~r/creating/) end)
      |> Enum.map(fn line -> extract_keyword(line) end)
      # The asserts are following a very simple state machine pattern. The log lines need
      # to come in a very specfic order (and cyclic)
      |> Enum.reduce(%{trigger: 0, send: 0, led: 0}, &count_and_assert/2)
    end

    def count_and_assert(line, acc) do
      case line do
        {_keyword, 0} ->
          acc

        {"send", trigger} ->
          if acc.send == 0 and acc.led == 0 do
            # this happens when we are not yet fully set up. Thus we ignore the first one
            acc
          else
            # IO.puts("#{acc.send}, #{acc.wait}, #{acc.led}: #{line}")
            assert acc.send == acc.led - 1
            assert acc.trigger == trigger
            %{acc | send: acc.send + 1}
          end

        {"led", trigger} ->
          # IO.puts("#{acc.send}, #{acc.wait}, #{acc.led}: #{line}")
          assert acc.led == acc.send
          if acc.trigger != 0, do: assert(acc.trigger + 1 == trigger)
          %{acc | led: acc.led + 1, trigger: trigger}
      end
    end

    def extract_keyword(line) do
      result = Regex.named_captures(~r/.*creating\s(?<word>\S+).*, (?<trigger>\d*)?/, line)
      trigger = result["trigger"]
      trigger = if trigger == "", do: "0", else: trigger
      {trigger, _rest} = Integer.parse(trigger)
      {result["word"], trigger}
    end

    def start_server(strip_name) do
      init_args = %{
        type: :animation,
        def_func: &logging_def_func/1,
        options: [send_config: &logging_send_config_func/1]
      }

      {:ok, pid} = Animator.start_link(init_args, strip_name, :test_animator)
      pid
    end

    def wait(pid) do
      Process.sleep(1_000)
      pid
    end

    def shutdown_server(pid) do
      GenServer.stop(pid)
    end
  end

  @animation_name :test_animation
  describe "trigger" do
    test "trigger as cache", %{strip_name: strip_name} do
      :ok = LedStrip.define_namespace(strip_name, @animation_name)

      state = %{
        def_func: fn triggers ->
          assert length(Map.keys(triggers)) == 2
          assert triggers.something == "abc"
          assert triggers[strip_name] == 11
          {Leds.leds(0), Map.put_new(triggers, :test1, 4)}
        end,
        options: [
          send_config: fn triggers ->
            assert length(Map.keys(triggers)) == 3
            assert triggers.something == "abc"
            assert triggers[strip_name] == 11
            assert triggers.test1 == 4
            {[], Map.put_new(triggers, :test2, 7)}
          end
        ],
        effects: [],
        strip_name: :test_strip,
        animation_name: :test_animation,
        triggers: %{
          test_strip: 10,
          something: "abc"
        }
      }

      {:noreply, state} =
        Animator.handle_info({:trigger, Map.put_new(%{}, strip_name, 11)}, state)

      assert length(Map.keys(state.triggers)) == 4
      assert state.triggers.something == "abc"
      assert state.triggers[strip_name] == 11
      assert state.triggers.test1 == 4
      assert state.triggers.test2 == 7
    end
  end

  describe "test shutdown" do
    test "through client API" do
      strip_name = :shutdown_testA
      {:ok, driver} = LedStrip.start_link(strip_name, Null)
      animation_name = :animation_testA
      {:ok, pid} = Animator.start_link(%{type: :animation}, strip_name, animation_name)
      assert Process.alive?(pid)
      Animator.shutdown(strip_name, animation_name)
      assert not Process.alive?(pid)
      GenServer.stop(driver, :normal)
    end

    test "through GenServer API" do
      strip_name = :shutdown_testB
      {:ok, driver} = LedStrip.start_link(strip_name, Null)
      animation_name = :animation_testB
      {:ok, pid} = Animator.start_link(%{type: :static}, strip_name, animation_name)
      assert Process.alive?(pid)
      Animator.shutdown(strip_name, animation_name)
      assert not Process.alive?(pid)
      GenServer.stop(driver, :normal)
    end
  end

  describe "effects" do
    test "effects applied" do
      leds = Leds.leds(3, [0xFF0000, 0x00FF00, 0x0000FF], %{})
      effects = [{Rotation, [trigger_name: :counter]}]
      triggers = %{counter: 1}

      {returned_leds, returned_triggers} =
        Animator.apply_effects(leds, effects, triggers, %{
          strip_name: :strip_name,
          animation_name: :animation_name
        })

      assert returned_triggers == triggers
      assert Leds.to_list(returned_leds) == [0x00FF00, 0x0000FF, 0xFF0000]
    end

    test "multi-effects in correct order" do
      leds = Leds.leds(3, [0xFF0000, 0x00FF00, 0x0000FF], %{})

      effects = [
        {Rotation, [trigger_name: :counter]},
        {Wanish, [trigger_name: :counter]}
      ]

      triggers = %{counter: 1}

      {returned_leds, returned_triggers} =
        Animator.apply_effects(leds, effects, triggers, %{
          strip_name: :strip_name,
          animation_name: :animation_name
        })

      assert returned_triggers == triggers
      assert Leds.to_list(returned_leds) == [0x00FF00, 0x0000FF, 0x000000]
    end

    test "enable animation without effects" do
      alias Fledex.Animation.Utils

      state = %{
        triggers: %{},
        type: :animation,
        def_func: &Utils.default_def_func/1,
        options: [send_config: &Utils.default_send_config_func/1],
        effects: [],
        strip_name: :strip_name,
        animation_name: :animation_name
      }

      {:noreply, state} = Animator.handle_cast({:update_effect, :all, [enabled: true]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
      {:noreply, state} = Animator.handle_cast({:update_effect, :all, [enabled: false]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
    end

    test "enable animation with effects" do
      import ExUnit.CaptureLog
      alias Fledex.Animation.Utils

      effect = Fledex.Animation.TestEffect
      config = []

      state = %{
        triggers: %{},
        type: :animation,
        def_func: &Utils.default_def_func/1,
        options: [send_config: &Utils.default_send_config_func/1],
        effects: [{effect, config}],
        strip_name: :strip_name,
        animation_name: :animation_name
      }

      {:noreply, state} = Animator.handle_cast({:update_effect, :all, [enabled: true]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
      assert [{module, config} | []] = state.effects
      assert module.enabled?(config) == true
      {:noreply, state} = Animator.handle_cast({:update_effect, :all, [enabled: false]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
      assert [{module, config} | []] = state.effects
      assert module.enabled?(config) == false
      {:noreply, state} = Animator.handle_cast({:update_effect, 1, [enabled: true]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
      assert [{module, config} | []] = state.effects
      assert module.enabled?(config) == true
      {:noreply, state} = Animator.handle_cast({:update_effect, 1, [enabled: false]}, state)
      assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
      assert [{module, config} | []] = state.effects
      assert module.enabled?(config) == false

      assert capture_log(fn ->
               {:noreply, state} =
                 Animator.handle_cast({:update_effect, 2, [enabled: true]}, state)

               assert Keyword.get(Map.get(state, :options, []), :enabled, true) == true
               assert [{module, config} | []] = state.effects
               assert module.enabled?(config) == false
             end) =~ "No effect found at index 2"
    end
  end

  describe "debug functions" do
    test "get state" do
      alias Fledex.Animation.Utils

      effect = Fledex.Animation.TestEffect
      config = []

      state = %{
        triggers: %{},
        type: :animation,
        def_func: &Utils.default_def_func/1,
        options: [send_config: &Utils.default_send_config_func/1],
        effects: [{effect, config}],
        strip_name: :strip_name,
        animation_name: :animation_name
      }

      assert {:reply, {:ok, state}, state} == Animator.handle_call(:info, self(), state)
    end
  end
end
