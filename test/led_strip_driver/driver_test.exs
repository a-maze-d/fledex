defmodule Fledex.LedStripDriver.DriverTest do
  use ExUnit.Case, async: true

  alias Fledex.LedStripDriver.Driver

  defmodule TestDriver do
    @behaviour Fledex.LedStripDriver.Driver
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
    @behaviour Fledex.LedStripDriver.Driver
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

  describe "test multi-module dispatching functions" do
    alias Fledex.LedStripDriver.DriverTest.TestDriver
    alias Fledex.LedStripDriver.DriverTest.TestDriver2
    test "init" do
      state = %{
        led_strip: %{
          driver_modules: [TestDriver, TestDriver2],
          config: %{}
        }
      }
      init_args = %{
        led_strip: %{
          config: %{
            Fledex.LedStripDriver.DriverTest.TestDriver => %{
              a1: 1
            },
            Fledex.LedStripDriver.DriverTest.TestDriver2 => %{
            }
          }
        }
      }
      state = Driver.init(init_args, state)

      assert map_size(state[:led_strip][:config]) == 2
      assert state[:led_strip][:config][TestDriver][:a1] == 1
      assert state[:led_strip][:config][TestDriver2][:a1] == 0
      assert state[:led_strip][:config][TestDriver][:a2] == 1
      assert state[:led_strip][:config][TestDriver2][:a2] == 2
    end

    test "transfer" do
      state = %{
        timer: %{counter: 0},
        led_strip: %{
          driver_modules: [TestDriver, TestDriver2],
          config: %{
            Fledex.LedStripDriver.DriverTest.TestDriver => %{
              a1: 1,
              a2: 1
            },
            Fledex.LedStripDriver.DriverTest.TestDriver2 => %{
              a1: 0,
              a2: 2
            }
          }
        }
      }
      state = Driver.transfer([], state)

      assert map_size(state[:led_strip][:config]) == 2
      assert state[:led_strip][:config][TestDriver][:a1] == 1
      assert state[:led_strip][:config][TestDriver2][:a1] == 0
      assert state[:led_strip][:config][TestDriver][:a2] == 1
      assert state[:led_strip][:config][TestDriver2][:a2] == 2
      assert state[:led_strip][:config][TestDriver][:a3] == nil
      assert state[:led_strip][:config][TestDriver2][:a3] == 4
    end
  end
end
