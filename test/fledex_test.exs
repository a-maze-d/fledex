defmodule Fledex.Test do
  use ExUnit.Case

  require Logger

  alias Fledex.LedAnimationManager

  @server_name :john
  describe "test macros" do
    test "fledex loaded" do
      use Fledex, dont_start: true
      assert fledex_loaded() != nil
    end
    test "use macro" do
      # we start the server
      assert GenServer.whereis(LedAnimationManager) == nil
      use Fledex
      assert GenServer.whereis(LedAnimationManager) != nil

      # and check that both Fledex and Fledex.Leds are imported
      assert :erlang.fun_info(&fledex_loaded/0) # from Fledex
      assert :erlang.fun_info(&leds/1) # from Fledex.Leds
    end
    test "use macro without server" do
      # we don't start the server
      assert GenServer.whereis(LedAnimationManager) == nil
      use Fledex, dont_start: true
      assert GenServer.whereis(LedAnimationManager) == nil

      # and check that both Fledex and Fledex.Leds are imported
      assert :erlang.fun_info(&fledex_loaded/0) # from Fledex
      assert :erlang.fun_info(&leds/1)          # from Fledex.Leds
      assert :erlang.fun_info(&red/0)           # from Fledex.Color.Names

    end

    # TODO: check this test, it seems to be flaky
    test "simple led strip macro" do
      # ensure our servers are not started
      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(LedAnimationManager) == nil

      use Fledex
      led_strip @server_name do
        # we don't define here anything
      end

      # did the correct servers get started?
      assert GenServer.whereis(@server_name) != nil
      assert GenServer.whereis(LedAnimationManager) != nil

      # cleanup
      GenServer.stop(LedAnimationManager)

      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(LedAnimationManager) == nil
    end

    test "simple live_loop macro" do
      use Fledex, dont_start: true
      config = live_loop :merry do
        _triggers -> leds(10)
      end
      assert {:merry, %{def_func: def_func, send_config_func: send_config_func}} = config
      assert def_func.(%{}) == leds(10)
      assert send_config_func.(%{}) == %{}
    end

    test "simple live_loop macro (with led_strip)" do
      use Fledex
      led_strip :john, :none do
        live_loop :merry do
         _triggers -> leds(10)
        end
      end
      {:ok, configs} = LedAnimationManager.get_info()

      assert Map.keys(configs) == [:john]
      assert Map.keys(configs.john) == [:merry]
      assert configs.john.merry.def_func.(%{}) == leds(10)
      assert configs.john.merry.send_config_func.(%{}) == %{}
    end

    test "complex scenario" do
      use Fledex
      led_strip :doe, :none do
        live_loop :caine do
          _triggers -> leds(1)
        end
        live_loop :smith do
          _triggers -> leds(2)
        end
      end
      led_strip :john, :none do
        live_loop :merry do
         _triggers -> leds(10)
        end
        live_loop :kate do
          _triggers -> leds(11)
        end
      end

      {:ok, configs} = LedAnimationManager.get_info()

      assert Map.keys(configs) == [:john, :doe]
      assert Map.keys(configs.john) == [:merry, :kate]
      assert configs.john.merry.def_func.(%{}) == leds(10)
      assert configs.john.kate.def_func.(%{}) == leds(11)
      assert configs.john.merry.send_config_func.(%{}) == %{}
      assert configs.john.kate.send_config_func.(%{}) == %{}
      assert Map.keys(configs.doe) == [:caine, :smith]
      assert configs.doe.caine.def_func.(%{}) == leds(1)
      assert configs.doe.smith.def_func.(%{}) == leds(2)
      assert configs.doe.caine.send_config_func.(%{}) == %{}
      assert configs.doe.smith.send_config_func.(%{}) == %{}
   end
  end
end
