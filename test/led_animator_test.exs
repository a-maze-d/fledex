defmodule Fledex.LedAnimatorTest do
  use ExUnit.Case
  alias Fledex.LedAnimator
  alias Fledex.TestHelpers.LedAnimatorHelper

  import ExUnit.CaptureLog
  require Logger

  describe "init" do
    test "config applied correctly (all set)" do
      init_args = %{
        def_func: &LedAnimatorHelper.default_def_func/1,
        send_config_func: &LedAnimatorHelper.default_send_config_func/1,
        wait_config_func: &LedAnimatorHelper.default_wait_config_func/1,
        debug: %{},
        counter: 0,
        timer_ref: nil
      }

      {:ok, state, {:continue, :start_timer}} = LedAnimator.init(init_args)
      assert state == init_args
    end
    test "config applied correctly (none_set)" do
      init_args = %{
      }

      {:ok, state, {:continue, :start_timer}} = LedAnimator.init(init_args)
      assert state.def_func != nil
      assert state.send_config_func != nil
      assert state.wait_config_func != nil
      assert state.debug == %{}
      assert state.counter == 0
      assert state.timer_ref == nil
    end
  end
  describe "test workflow" do
    test "validate continuous workflow" do
      capture_log([], fn ->
        run_simple_workflow()
      end)
        |> assert_logs()
    end
    def run_simple_workflow do
      start_server()
        |> wait()
        |> shutdown_server()
    end

    def assert_logs(logs) do
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
          assert acc.wait == acc.led
          %{acc | wait: acc.wait + 1}
        "send" ->
          assert acc.send == acc.wait - 1
          %{acc | send: acc.send + 1}
        "led" ->
          assert acc.led == acc.send - 1
          %{acc | led: acc.led + 1}
      end
    end

    def extract_keyword(line) do
      [_left, middle, _right] = String.slice(line, 20, String.length(line))
        |> String.split(" ")
      middle
    end

    def start_server do
      init_args = %{
        def_func: &LedAnimatorHelper.logging_def_func/1,
        send_config_func: &LedAnimatorHelper.logging_send_config_func/1,
        wait_config_func: &LedAnimatorHelper.logging_wait_config_func/1,
        debug: %{dont_send: true},
        counter: 0,
        timer_ref: nil
      }

      {:ok, pid} = GenServer.start(LedAnimator, init_args)
      pid
    end

    def wait(pid) do
      Process.sleep(1_000)
      pid
    end

    def shutdown_server(pid) do
      Process.exit(pid, :kill)
    end
  end
end
