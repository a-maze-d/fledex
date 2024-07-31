# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.ManagerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Manager

  defmodule TestDriver do
    @behaviour Fledex.Driver.Interface
    def configure(config) do
      [
        a1: Keyword.get(config, :a1, 0),
        a2: 1
      ]
    end

    def init(config) do
      configure(config)
    end

    def reinit(old_config, new_config) do
      Keyword.merge(old_config, new_config)
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
    def configure(config) do
      [
        a1: Keyword.get(config, :a1, 0),
        a2: 2
      ]
    end

    def init(config) do
      configure(config)
    end

    def reinit(old_config, new_config) do
      Keyword.merge(old_config, new_config)
    end

    def transfer(_leds, _count, config) do
      {Keyword.put(config, :a3, 4), :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  defmodule TestDriver3 do
    # note: on purpose we don't inherit from the
    # behaviour.
    def configure(config) do
      [
        a1: Keyword.get(config, :a1, 0),
        a2: 2
      ]
    end

    def init(config) do
      configure(config)
    end

    def transfer(_leds, config) do
      {Keyword.put(config, :a3, 4), :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  describe "test multi-module dispatching functions" do
    alias Fledex.Driver.ManagerTest.TestDriver
    alias Fledex.Driver.ManagerTest.TestDriver2

    test "init" do
      drivers = [
        {TestDriver, a1: 1},
        {TestDriver2, []}
      ]

      drivers = Manager.init_drivers(drivers)

      assert length(drivers) == 2
      config1 = get_driver_config(drivers, TestDriver)
      assert Keyword.fetch!(config1, :a1) == 1
      assert Keyword.fetch!(config1, :a2) == 1

      config2 = get_driver_config(drivers, TestDriver2)
      assert Keyword.fetch!(config2, :a1) == 0
      assert Keyword.fetch!(config2, :a2) == 2
    end

    test "transfer" do
      counter = 0

      drivers = [
        {TestDriver, a1: 1, a2: 1},
        {TestDriver2, a1: 0, a2: 2}
      ]

      drivers = Manager.transfer([], counter, drivers)

      assert length(drivers) == 2
      config1 = get_driver_config(drivers, TestDriver)
      assert Keyword.fetch!(config1, :a1) == 1
      assert Keyword.fetch!(config1, :a2) == 1
      assert Keyword.get(config1, :a3, nil) == nil

      config2 = get_driver_config(drivers, TestDriver2)
      assert Keyword.fetch!(config2, :a1) == 0
      assert Keyword.fetch!(config2, :a2) == 2
      assert Keyword.fetch!(config2, :a3) == 4
    end
  end

  describe "non-compliant module" do
    alias Fledex.Driver.ManagerTest.TestDriver
    alias Fledex.Driver.ManagerTest.TestDriver3

    test "non-compliant gets dropped" do
      drivers = [
        {TestDriver, a1: 1},
        {TestDriver3, []}
      ]

      {drivers, log} =
        with_log(fn ->
          Manager.init_drivers(drivers)
        end)

      assert length(drivers) == 1
      assert drivers == [{TestDriver, a1: 1, a2: 1}]
      assert log =~ "TestDriver3 does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end

    test "single non-compliant gets replaced with default" do
      drivers = [
        {TestDriver3, []}
      ]

      {drivers, log} =
        with_log(fn ->
          Manager.init_drivers(drivers)
        end)

      assert length(drivers) == 1
      assert drivers == [{Null, []}]
      assert log =~ "TestDriver3 does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end
  end

  defp get_driver_config(drivers, driver_module) do
    [{^driver_module, config} | _] =
      Enum.filter(drivers, fn {module, _config} -> module == driver_module end)

    config
  end
end
