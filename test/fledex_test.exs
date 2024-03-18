# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Test do
  use ExUnit.Case

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Manager

  @server_name :john
  describe "test macros" do
    test "fledex loaded" do
      use Fledex, dont_start: true
      assert fledex_config() != nil
    end
    test "use macro" do
      # we start the server
      assert GenServer.whereis(Manager) == nil
      use Fledex
      assert GenServer.whereis(Manager) != nil

      # and check that both Fledex, Fledex.Leds and Fledex.Color.Names are imported
      assert :erlang.fun_info(&fledex_config/0) # from Fledex
      assert :erlang.fun_info(&leds/1) # from Fledex.Leds
      assert :erlang.fun_info(&red/1) # from Fledex.Color.Names
    end
    test "use macro without server" do
      # we don't start the server
      assert GenServer.whereis(Manager) == nil
      use Fledex, dont_start: true
      assert GenServer.whereis(Manager) == nil

      # and check that both Fledex and Fledex.Leds are imported
      assert :erlang.fun_info(&fledex_config/0) # from Fledex
      assert :erlang.fun_info(&leds/1)          # from Fledex.Leds
      assert :erlang.fun_info(&red/0)           # from Fledex.Color.Names

    end

    # TODO: check this test, it seems to be flaky
    test "simple led strip macro" do
      # ensure our servers are not started
      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(Manager) == nil

      use Fledex
      led_strip @server_name do
        # we don't define here anything
      end

      # did the correct servers get started?
      assert GenServer.whereis(@server_name) != nil
      assert GenServer.whereis(Manager) != nil

      # cleanup
      GenServer.stop(Manager)

      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(Manager) == nil
    end

    test "simple animation macro" do
      use Fledex, dont_start: true
      config = animation :merry do
        _triggers -> leds(10)
      end
      assert %{merry: %{def_func: def_func}} = config
      assert def_func.(%{}) == leds(10)
    end

    test "simple animation macro (with led_strip)" do
      use Fledex
      led_strip :john, :none do
        animation :merry do
         _triggers -> leds(10)
        end
      end
      {:ok, configs} = Manager.get_info()

      assert Map.keys(configs) == [:john]
      assert Map.keys(configs.john) == [:merry]
      assert configs.john.merry.def_func.(%{}) == leds(10)
      # assert configs.john.merry.send_config_func.(%{}) == %{}
    end
    test "simple animation macro (with led_strip) withoutout trigger" do
      use Fledex
      led_strip :john, :none do
        animation :merry do
         leds(10)
        end
      end
      {:ok, configs} = Manager.get_info()

      assert Map.keys(configs) == [:john]
      assert Map.keys(configs.john) == [:merry]
      assert configs.john.merry.def_func.(%{}) == leds(10)
      # assert configs.john.merry.send_config_func.(%{}) == %{}
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

      {:ok, configs} = Manager.get_info()

      assert Map.keys(configs) == [:john, :doe]
      assert Map.keys(configs.john) == [:merry, :kate]
      assert configs.john.merry.def_func.(%{}) == leds(10)
      assert configs.john.kate.def_func.(%{}) == leds(11)
      assert Map.keys(configs.doe) == [:caine, :smith]
      assert configs.doe.caine.def_func.(%{}) == leds(1)
      assert configs.doe.smith.def_func.(%{}) == leds(2)
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
      {:ok, configs} = Manager.get_info()

      # ensure that the block does not expect any triggers even though
      # the function actually does contain it
      assert configs.sten.svenson.def_func.(%{}) == leds(5)

      {:ok, info} = Animator.get_info(:sten, :svenson)
      assert info.triggers == %{}  # there should not be any triggers, since we are static
      assert info.type == :static
    end
  end
  describe "effects" do
    test "simple" do
      use Fledex
      with_effect = effect Fledex.Test do
        animation :name do
          leds(10)
        end
      end
      assert %{name: %{effects: [{Fledex.Test, []}]}} = with_effect
    end
    test "with options" do
      use Fledex
      with_effect = effect Fledex.Test, option: :something do
        animation :name do
          leds(10)
        end
      end
      assert %{name: %{effects: [{Fledex.Test, [option: :something]}]}} = with_effect
    end
    test "with several options" do
      use Fledex
      with_effect = effect Fledex.Test, option1: :something, option2: :something_else do
        animation :name do
          leds(10)
        end
      end
      assert %{name: %{effects: [{Fledex.Test, [option1: :something, option2: :something_else]}]}} = with_effect
    end
    test "several nested" do
      use Fledex
      with_effects =
        effect Fledex.Test do
          effect Fledex.Test2 do
            animation :name do
              leds(10)
            end
          end
        end
      assert %{
        name: %{effects: [
          {Fledex.Test, []},
          {Fledex.Test2, []}
        ]}
      } = with_effects
    end
  end
  describe "component" do
    test "simple" do
      defmodule Test do
        @behaviour Fledex.Component.Interface

        @impl true
        def configure(name, options) do
          %{name => %{
            type: :animation,
            def_func: fn _triggers, _options -> Leds.led(30) end,
            options: options,
            effects: []
          }}
        end
      end
      use Fledex
      config = component :name, Test, option1: 123, option2: "abc", option3: :atom1, option4: %{test1: "123"}

      assert Map.has_key?(config, :name)
      assert config.name.options == [option1: 123, option2: "abc", option3: :atom1, option4: %{test1: "123"}]
    end
  end
  describe "dsl" do
    test "effect + double animation" do
      use Fledex
      alias Fledex.Effect.Dimming

      config = effect Rotation do
        animation :john do
          _triggers -> leds(10)
        end
        animation :mary do
          _triggers -> leds(20)
        end
      end

      assert %{
        john: %{def_func: def_func1, effects: effects1},
        mary: %{def_func: def_func2, effects: effects2},
      } = config
      assert def_func1.(%{}) == leds(10)
      assert def_func2.(%{}) == leds(20)
      assert [{Rotation, _options}] = effects1
      assert [{Rotation, _options}] = effects2
    end

    test "nested effect, on effect and animation" do
      use Fledex
      alias Fledex.Effect.Dimming
      alias Fledex.Effect.Rotation

      config = effect Rotation, [] do
        effect Dimming do
          animation :john do
            _triggers -> leds(10)
          end
        end
        animation :mary do
          _triggers -> leds(20)
        end
      end

      assert %{
        john: %{def_func: def_func1, effects: effects1},
        mary: %{def_func: def_func2, effects: effects2},
      } = config
      assert def_func1.(%{}) == leds(10)
      assert def_func2.(%{}) == leds(20)
      assert [{Rotation, _options_1}, {Dimming, _options_2}] = effects1
      assert [{Rotation, _options}] = effects2
    end
    test "double animation in strip" do
      use Fledex
      config = led_strip :strip, :debug do
        animation :john do
          leds(10)
        end
        animation :mary do
          leds(20)
        end
      end
      assert %{
        john: %{def_func: def_func1, effects: []},
        mary: %{def_func: def_func2, effects: []},
      } = config
      assert def_func1.(%{}) == leds(10)
      assert def_func2.(%{}) == leds(20)
    end
  end
end
