defmodule Fledex.LedStripDriver.Driver do
  require Logger

  alias Fledex.Color.Types

  @callback init(module_init_args :: map) :: map
  @callback reinit(module_config::map) :: map
  @callback transfer(leds :: list(Types.colorint), counter :: pos_integer, config :: map) :: map
  @callback terminate(reason, config :: map) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()

    @spec init(map, Fledex.LedDriver.t) :: Fledex.LedDriver.t
    def init(init_args, state) do
      configs = for module <- state.led_strip.driver_modules do
        # Logger.trace("Creating driver: #{inspect module}")
        module_init_args = init_args[:led_strip][:config][module] || %{}
        config = module.init(module_init_args)
        {module, config}
      end

      put_in(state.led_strip.config, Enum.into(configs, %{}))
    end

    def reinit(state) do
      configs = for module <- state.led_strip.driver_modules do
        module_config = state.led_strip.config[module]
        config = module.reinit(module_config)
        {module, config}
      end
      put_in(state.led_strip.config, Enum.into(configs, %{}))
    end

    @spec transfer(list(Types.colorint), Fledex.LedDriver.t) :: Fledex.LedDriver.t
    def transfer(leds, state) do
      configs = for module <- state.led_strip.driver_modules do
        config = module.transfer(leds, state[:timer][:counter], state[:led_strip][:config][module])
        {module, config}
      end

      put_in(state.led_strip.config, Enum.into(configs, %{}))
    end

    def terminate(reason, state) do
      for module <- state.led_strip.driver_modules do
        module.terminate(reason, state[:led_strip][:config][module])
      end
      :ok
    end
end
