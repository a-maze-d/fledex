# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.LoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import ExUnit.CaptureIO
  require Logger

  alias Fledex.Driver.Impl.Logger

  describe "init" do
    test "defaults" do
      config = Logger.init([], %{})
      assert Keyword.fetch!(config, :update_freq) == 10
      assert Keyword.fetch!(config, :log_color_code) == false
      assert Keyword.fetch!(config, :terminal) == true
    end

    test "init_args" do
      config =
        Logger.init(
          [
            update_freq: 12,
            log_color_code: true,
            terminal: false
          ],
          %{}
        )

      assert Keyword.fetch!(config, :update_freq) == 12
      assert Keyword.fetch!(config, :log_color_code) == true
      assert Keyword.fetch!(config, :terminal) == false
    end

    test "reinit" do
      config =
        Logger.init(
          [
            update_freq: 12,
            log_color_code: true
          ],
          %{}
        )

      assert Logger.reinit(config, [], %{}) == config
    end

    test "transfer (logger without color code)" do
      capture_log(fn ->
        config =
          Logger.init(
            [
              update_freq: 1,
              log_color_code: false,
              terminal: false
            ],
            %{}
          )

        leds = [0xFF0000, 0x00FF00, 0x0000FF]
        Logger.transfer(leds, 0, config)
      end)
      |> assert_log()
    end

    defp assert_log(log) do
      ansi_color_r = IO.ANSI.color(5, 0, 0)
      ansi_color_g = IO.ANSI.color(0, 5, 0)
      ansi_color_b = IO.ANSI.color(0, 0, 5)
      assert String.contains?(log, ansi_color_r)
      assert String.contains?(log, ansi_color_g)
      assert String.contains?(log, ansi_color_b)
    end

    test "transfer without leds" do
      log =
        capture_log(fn ->
          config =
            Logger.init(
              [
                update_freq: 1,
                log_color_code: false,
                terminal: false
              ],
              %{}
            )

          leds = []
          Logger.transfer(leds, 0, config)
        end)

      assert log == ""
    end

    test "transfer (logger with color code)" do
      capture_log(fn ->
        config =
          Logger.init(
            [
              update_freq: 1,
              log_color_code: true,
              terminal: false
            ],
            %{}
          )

        leds = [0xFF0000, 0x00FF00, 0x0000FF]
        Logger.transfer(leds, 0, config)
      end)
      |> assert_log_color_code()
    end

    defp assert_log_color_code(log) do
      assert String.match?(log, ~r/16711680,65280,255,/)
    end

    test "empty transfer" do
      capture_io(fn ->
        config =
          Logger.init(
            [
              update_freq: 10,
              log_color_code: true,
              terminal: true
            ],
            %{}
          )

        leds = [0xFF0000, 0x00FF00, 0x0000FF]
        Logger.transfer(leds, 1, config)
      end)
      |> assert_log_empty()
    end

    defp assert_log_empty(log) do
      assert log == ""
    end

    test "terminate" do
      config =
        Logger.init(
          [
            update_freq: 12,
            log_color_code: true
          ],
          %{}
        )

      assert Logger.terminate(:normal, config) == :ok
    end
  end
end
