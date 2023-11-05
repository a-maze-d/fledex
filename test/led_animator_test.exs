defmodule Fledex.LedAnimatorTest do
  use ExUnit.Case
  alias Fledex.LedAnimator
  alias Fledex.Leds
  alias Fledex.LedsDriver

  import ExUnit.CaptureLog
  require Logger

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
        triggers: %{}
      }

      {:ok, state} = Fledex.LedAnimator.init({init_args, :test_strip, :test_animator})
      assert state == init_args
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
end
