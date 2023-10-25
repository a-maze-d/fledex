defmodule Fledex.LedAnimatorTest do
  use ExUnit.Case
  alias Fledex.LedAnimator
  alias Fledex.LedsDriver
  alias Fledex.TestHelpers.LedAnimatorHelper

  import ExUnit.CaptureLog
  require Logger

  @strip_name :test_strip
  setup do
    {:ok, pid} = start_supervised(
      %{
        id: LedsDriver,
        start: {LedsDriver, :start_link, [:none, @strip_name]}
      })
    %{strip_name: @strip_name,
      pid: pid}
  end

  describe "init" do
    test "config applied correctly (all set)" do
      init_args = %{
        def_func: &LedAnimatorHelper.default_def_func/1,
        send_config_func: &LedAnimatorHelper.default_send_config_func/1,
        wait_config_func: &LedAnimatorHelper.default_wait_config_func/1,
        debug: %{},
        # counter: 0,
        # timer_ref: nil,
        strip_name: :test_strip,
        animator_name: :test_animator,
        triggers: %{}
      }

      {:ok, state, {:continue, :start_timer}} = Fledex.LedAnimator.init({init_args, :test_strip, :test_animator})
      assert state == init_args
    end

    test "config applied correctly (none_set)" do
      init_args = %{}

      {:ok, state, {:continue, :start_timer}} = LedAnimator.init({init_args, :test_strip, :test_animator})
      assert state.def_func != nil
      assert state.send_config_func != nil
      assert state.wait_config_func != nil
      assert state.debug == %{}
      # assert state.counter == 0
      # assert state.timer_ref == nil
      assert state.strip_name == :test_strip
      assert state.animator_name == :test_animator
    end
  end

  describe "test workflow" do
    # TODO: we need to rethink this test, see the run() funtion
    # test "validate continuous workflow", %{strip_name: strip_name, pid: pid} do
    #   # ensure our driver is running
    #   assert Process.alive?(pid)

    #   capture_log([], fn -> run_simple_workflow(strip_name) end)
    #     |> assert_logs()

    #   # ensure our animator did not kill our driver while shutting down
    #   assert Process.alive?(pid)
    # end

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
      |> Enum.reduce(%{wait: 0, send: 0, led: 0}, &count_and_assert/2)
    end

    def count_and_assert(line, acc) do
      case line do
        "wait" ->
          # IO.puts("#{acc.send}, #{acc.wait}, #{acc.led}: #{line}")
          assert acc.wait == acc.led
          %{acc | wait: acc.wait + 1}

        "send" ->
          if acc.send == 0 and acc.wait == 0 and acc.led == 0 do
            # this happens when we are not yet fully set up. Thus we ignore the first one
            acc
          else
            # IO.puts("#{acc.send}, #{acc.wait}, #{acc.led}: #{line}")
            assert acc.send == acc.wait - 1
            %{acc | send: acc.send + 1}
          end
        "led" ->
          # IO.puts("#{acc.send}, #{acc.wait}, #{acc.led}: #{line}")
          assert acc.led == acc.send - 1
          %{acc | led: acc.led + 1}
      end
    end

    def extract_keyword(line) do
      [_left, middle, _right] =
        String.slice(line, 20, String.length(line))
        |> String.split(" ")

      middle
    end

    def start_server(strip_name) do
      init_args = %{
        def_func: &LedAnimatorHelper.logging_def_func/1,
        send_config_func: &LedAnimatorHelper.logging_send_config_func/1,
        wait_config_func: &LedAnimatorHelper.logging_wait_config_func/1,
        debug: %{dont_send: true},
        counter: 0,
        timer_ref: nil
      }

      {:ok, pid} = Fledex.LedAnimator.start_link(init_args, strip_name, :test_animator)
      # GenServer.start(LedAnimator, {init_args, :test_animator}, name: :test_animator)
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
