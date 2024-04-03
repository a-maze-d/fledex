# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.ManagerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Manager

  defmodule TestDriver do
    @behaviour Fledex.Driver.Interface
    def init(init_args) do
      %{
        a1: init_args[:a1] || 0,
        a2: 1
      }
    end

    def reinit(config) do
      config
    end

    def transfer(_leds, _count, config) do
      {config, :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  defmodule TestDriver2 do
    @behaviour Fledex.Driver.Interface
    def init(init_args) do
      %{
        a1: init_args[:a1] || 0,
        a2: 2
      }
    end

    def reinit(config) do
      config
    end

    def transfer(_leds, _count, config) do
      {Map.put(config, :a3, 4), :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  defmodule TestDriver3 do
    # note: on purpose we don't inherit from the
    # behaviour.
    def init(init_args) do
      %{
        a1: init_args[:a1] || 0,
        a2: 2
      }
    end

    def transfer(_leds, config) do
      {Map.put(config, :a3, 4), :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  describe "test multi-module dispatching functions" do
    alias Fledex.Driver.ManagerTest.TestDriver
    alias Fledex.Driver.ManagerTest.TestDriver2

    test "init" do
      led_strip = %{
        driver_modules: [TestDriver, TestDriver2],
        config: %{
          TestDriver => %{
            a1: 1
          },
          TestDriver2 => %{}
        }
      }

      led_strip =
        Manager.init_config(led_strip)
        |> Manager.init_drivers()

      assert map_size(led_strip[:config]) == 2
      assert led_strip[:config][TestDriver][:a1] == 1
      assert led_strip[:config][TestDriver2][:a1] == 0
      assert led_strip[:config][TestDriver][:a2] == 1
      assert led_strip[:config][TestDriver2][:a2] == 2
    end

    test "transfer" do
      counter = 0

      led_strip = %{
        driver_modules: [TestDriver, TestDriver2],
        config: %{
          TestDriver => %{
            a1: 1,
            a2: 1
          },
          TestDriver2 => %{
            a1: 0,
            a2: 2
          }
        }
      }

      led_strip = Manager.transfer([], counter, led_strip)

      assert map_size(led_strip[:config]) == 2
      assert led_strip[:config][TestDriver][:a1] == 1
      assert led_strip[:config][TestDriver2][:a1] == 0
      assert led_strip[:config][TestDriver][:a2] == 1
      assert led_strip[:config][TestDriver2][:a2] == 2
      assert led_strip[:config][TestDriver][:a3] == nil
      assert led_strip[:config][TestDriver2][:a3] == 4
    end
  end

  describe "non-compliant module" do
    alias Fledex.Driver.ManagerTest.TestDriver
    alias Fledex.Driver.ManagerTest.TestDriver3

    test "non-compliant gets dropped" do
      led_strip = %{
        driver_modules: [TestDriver, TestDriver3],
        config: %{
          TestDriver => %{
            a1: 1
          },
          TestDriver3 => %{}
        }
      }

      {led_strip, log} =
        with_log(fn ->
          Manager.init_config(led_strip)
          |> Manager.init_drivers()
        end)

      assert length(led_strip[:driver_modules]) == 1
      assert led_strip[:driver_modules] == [TestDriver]
      assert log =~ "TestDriver3 does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end

    test "single non-compliant gets replaced with default" do
      led_strip = %{
        driver_modules: [TestDriver3],
        config: %{
          TestDriver3 => %{}
        }
      }

      {led_strip, log} =
        with_log(fn ->
          Manager.init_config(led_strip)
          |> Manager.init_drivers()
        end)

      assert length(led_strip[:driver_modules]) == 1
      assert led_strip[:driver_modules] == [Null]
      assert log =~ "TestDriver3 does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end
  end
end
