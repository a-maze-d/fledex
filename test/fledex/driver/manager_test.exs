# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
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

    def init(config, _global_config) do
      configure(config)
    end

    def reinit(old_config, new_config, _global_config) do
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

    def init(config, _global_config) do
      configure(config)
    end

    def reinit(old_config, new_config, _global_config) do
      Keyword.merge(old_config, new_config)
    end

    def transfer(_leds, _count, config) do
      {Keyword.put(config, :a3, 4), :ok}
    end

    def terminate(_reason, _config) do
      :ok
    end
  end

  defmodule NonCompliantDriver do
    # note: on purpose we don't inherit from the
    # behaviour. This is a non-compliant driver
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

  defmodule TestDriver4 do
    @behaviour Fledex.Driver.Interface
    def configure(config) do
      Keyword.merge([], config)
    end

    def init(config, _global_config) do
      configure(config)
    end

    def reinit(old_config, new_config, _global_config) do
      Keyword.merge(old_config, new_config)
    end

    def transfer(_leds, _count, config) do
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

      drivers = Manager.init_drivers(drivers, [])

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
    alias Fledex.Driver.ManagerTest.NonCompliantDriver
    alias Fledex.Driver.ManagerTest.TestDriver

    test "non-compliant gets dropped" do
      drivers = [
        {TestDriver, a1: 1},
        {NonCompliantDriver, []}
      ]

      {drivers, log} =
        with_log(fn ->
          Manager.init_drivers(drivers, [])
        end)

      assert length(drivers) == 1
      assert drivers == [{TestDriver, a1: 1, a2: 1}]
      assert log =~ "NonCompliantDriver does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end

    test "single non-compliant gets replaced with default" do
      drivers = [
        {NonCompliantDriver, []}
      ]

      {drivers, log} =
        with_log(fn ->
          Manager.init_drivers(drivers, [])
        end)

      assert length(drivers) == 1
      assert drivers == [{Null, []}]
      assert log =~ "NonCompliantDriver does not implement the function :reinit"
      assert log =~ "with the wrong arity 2 vs 3"
    end
  end

  defp get_driver_config(drivers, driver_module) do
    [{^driver_module, config} | _other] =
      Enum.filter(drivers, fn {module, _config} -> module == driver_module end)

    config
  end

  describe "reinit drivers" do
    test "without drivers" do
      drivers = Manager.reinit([], [], [])
      assert drivers == [{Null, []}]
    end

    test "with existing default" do
      drivers = Manager.reinit([{Null, []}], [], [])
      assert drivers == [{Null, []}]
    end

    test "with overlapping driver" do
      drivers = Manager.reinit([{TestDriver4, []}], [{TestDriver4, []}], [])
      assert drivers == [{TestDriver4, []}]
    end

    test "with overlapping driver, new config" do
      drivers = Manager.reinit([{TestDriver4, [abc: 123]}], [{TestDriver4, [abc: 345]}], [])
      assert drivers == [{TestDriver4, abc: 345}]
    end

    test "with overlapping driver, non-overlapping config" do
      drivers = Manager.reinit([{TestDriver4, [abc: 123]}], [{TestDriver4, [efg: 345]}], [])
      assert drivers == [{TestDriver4, [abc: 123, efg: 345]}]
    end

    test "with overlapping driver and extra driver" do
      drivers =
        Manager.reinit(
          [{TestDriver4, [abc: 123]}],
          [{TestDriver4, [abc: 345]}, {Null, []}],
          []
        )

      assert drivers == [{Null, []}, {TestDriver4, [abc: 345]}]
    end

    test "drivers stay sorted" do
      drivers = Manager.reinit([], [{TestDriver4, []}, {Null, []}], [])
      assert drivers == [{Null, []}, {TestDriver4, []}]
    end

    test "with dropped driver, config retained" do
      old_drivers = Enum.sort([{TestDriver4, [abc: 123]}, {Null, []}])
      drivers = Manager.reinit(old_drivers, [{TestDriver4, []}, {Null, []}], [])

      assert drivers == [{Null, []}, {TestDriver4, [abc: 123]}]
    end

    test "with dropped driver, config retained (second order)" do
      old_drivers = Enum.sort([{TestDriver4, [abc: 123]}, {Null, []}])
      drivers = Manager.reinit(old_drivers, [{Null, []}, {TestDriver4, []}], [])

      assert drivers == [{Null, []}, {TestDriver4, [abc: 123]}]
    end
  end
end
