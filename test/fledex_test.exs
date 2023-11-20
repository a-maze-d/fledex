defmodule Fledex.Test do
  use ExUnit.Case

  require Logger

  alias Fledex.LedAnimationManager
  alias Fledex.LedAnimator

  @server_name :john
  describe "test macros" do
    test "fledex loaded" do
      use Fledex, dont_start: true
      assert fledex_config() != nil
    end
    test "use macro" do
      # we start the server
      assert GenServer.whereis(LedAnimationManager) == nil
      use Fledex
      assert GenServer.whereis(LedAnimationManager) != nil

      # and check that both Fledex and Fledex.Leds are imported
      assert :erlang.fun_info(&fledex_config/0) # from Fledex
      assert :erlang.fun_info(&leds/1) # from Fledex.Leds
    end
    test "use macro without server" do
      # we don't start the server
      assert GenServer.whereis(LedAnimationManager) == nil
      use Fledex, dont_start: true
      assert GenServer.whereis(LedAnimationManager) == nil

      # and check that both Fledex and Fledex.Leds are imported
      assert :erlang.fun_info(&fledex_config/0) # from Fledex
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

    test "simple animation macro" do
      use Fledex, dont_start: true
      config = animation :merry do
        _triggers -> leds(10)
      end
      assert {:merry, %{def_func: def_func, send_config_func: send_config_func}} = config
      assert def_func.(%{}) == leds(10)
      assert send_config_func.(%{}) == %{}
    end

    test "simple animation macro (with led_strip)" do
      use Fledex
      led_strip :john, :none do
        animation :merry do
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
        animation :caine do
          _triggers -> leds(1)
        end
        animation :smith do
          _triggers -> leds(2)
        end
      end
      led_strip :john, :none do
        animation :merry do
         _triggers -> leds(10)
        end
        animation :kate do
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
  # static animations are internally animations, but they don't
  # really animate since they don't register for updates
  describe "static animation" do
    test "no updates" do
      use Fledex
      led_strip :sten, :none do
        static :svenson do
          leds(5)
        end
      end

      Process.sleep(500) # give a chance to triggers (even though we shouldn't collect any)
      {:ok, configs} = LedAnimationManager.get_info()

      # ensure that the block does not expect any triggers even though
      # the function actually does contain it
      assert configs.sten.svenson.def_func.(%{}) == leds(5)

      {:ok, info} = LedAnimator.get_info(:sten, :svenson)
      assert info.triggers == %{}  # there should not be any triggers, since we are static
      assert info.type == :static
    end
  end
end
