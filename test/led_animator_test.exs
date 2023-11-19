defmodule Fledex.LedAnimatorTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  require Logger

  alias Fledex.LedAnimator
  alias Fledex.Leds
  alias Fledex.LedsDriver

  def default_def_func(_triggers) do
    Leds.leds(30)
  end
  def default_send_config_func(_triggers) do
    %{namespace: "test"}
  end
  # some logging versions to test the workflow
  def logging_def_func(triggers) do
    Logger.info("creating led definition, #{triggers.test_strip}")
    Leds.leds(30)
  end
  def logging_send_config_func(triggers) do
    Logger.info("creating send config, #{triggers.test_strip}")
    %{namespace: "test#{ExUnit.configuration()[:seed]}"}
  end

  @strip_name :test_strip
  setup do
    {:ok, pid} = start_supervised(
      %{
        id: LedsDriver,
        start: {LedsDriver, :start_link, [@strip_name, :none]}
      })
    %{strip_name: @strip_name,
      pid: pid}
  end

  describe "init" do
    test "config applied correctly (all set)" do
      init_args = %{
        def_func: &default_def_func/1,
        send_config_func: &default_send_config_func/1,
        strip_name: :test_strip,
        animator_name: :test_animator,
        triggers: %{},
        type: :animation
      }

      {:ok, state} = Fledex.LedAnimator.init({init_args, :test_strip, :test_animator})
      assert state == init_args
    end

    test "default funcs" do
      init_args = %{}
      {:ok, state} = Fledex.LedAnimator.init({init_args, :test_strip, :test_animator})
      assert Leds.leds(30) == state.def_func.(%{test_strip: 10})
      assert %{} == state.send_config_func.(%{test_strip: 10})

    end
    test "config applied correctly (none_set)" do
      init_args = %{}

      {:ok, state} = LedAnimator.init({init_args, :test_strip, :test_animator})
      assert state.def_func != nil
      assert state.send_config_func != nil
      assert state.strip_name == :test_strip
      assert state.animator_name == :test_animator
    end
  end
  describe "test triggers" do
    test "merging triggers" do
      {:noreply, state} = LedAnimator.handle_info({:trigger, %{test_strip: 10}}, %{triggers: %{}})
      assert state.triggers.test_strip == 10
      {:noreply, state} = LedAnimator.handle_info({:trigger, %{test_strip: 11, new_strip: 10}}, state)
      assert state.triggers.test_strip == 11
      assert state.triggers.new_strip == 10
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
          if acc.trigger != 0, do: assert acc.trigger + 1 == trigger
          %{acc | led: acc.led + 1, trigger: trigger}
      end
    end

    def extract_keyword(line) do
      result = Regex.named_captures(~r/.*creating\s(?<word>\S+).*, (?<trigger>\d*)/, line)
      {trigger, _rest} = Integer.parse(result["trigger"] || "0")
      {result["word"], trigger}
    end

    def start_server(strip_name) do
      init_args = %{
        def_func: &logging_def_func/1,
        send_config_func: &logging_send_config_func/1,
      }

      {:ok, pid} = LedAnimator.start_link(init_args, strip_name, :test_animator)
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

  @animator_name :test_animator
  describe "trigger" do
    test "trigger as cache", %{strip_name: strip_name}  do
      :ok = LedsDriver.define_namespace(strip_name, @animator_name)
      state = %{
        def_func: fn (triggers) ->
          assert length(Map.keys(triggers)) == 2
          assert triggers.something == "abc"
          assert triggers[strip_name] == 11
          {Leds.leds(0), Map.put_new(triggers, :test1, 4)}
        end,
        send_config_func: fn (triggers) ->
          assert length(Map.keys(triggers)) == 3
          assert triggers.something == "abc"
          assert triggers[strip_name] == 11
          assert triggers.test1 == 4
          {%{}, Map.put_new(triggers, :test2, 7)}
        end,
        strip_name: :test_strip,
        animator_name: :test_animator,
        triggers: %{
          test_strip: 10,
          something: "abc"
        }
      }
      {:noreply, state} = LedAnimator.handle_info({:trigger, Map.put_new(%{}, strip_name, 11)}, state)
      assert length(Map.keys(state.triggers)) == 4
      assert state.triggers.something == "abc"
      assert state.triggers[strip_name] == 11
      assert state.triggers.test1 == 4
      assert state.triggers.test2 == 7
    end
  end
end
