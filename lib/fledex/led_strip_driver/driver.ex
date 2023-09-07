defmodule Fledex.LedStripDriver.Driver do
  use Fledex.Color.Types
  require Logger

  @callback init(module_init_args :: map) :: map
  @callback transfer(leds :: list(colorint), counter :: pos_integer, config :: map) :: map
  @callback terminate(reason, config :: map) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()

    @spec init(map, Fledex.LedDriver.t) :: Fledex.LedDriver.t
    def init(init_args, state) do
      configs = for module <- state.led_strip.driver_modules do
        Logger.info("Creating driver: #{inspect module}")
        module_init_args = init_args[:led_strip][:config][module] || %{}
        config = module.init(module_init_args)
        {module, config}
      end

      put_in(state.led_strip.config, Enum.into(configs, %{}))
    end

    @spec transfer(list(colorint), Fledex.LedDriver.t) :: Fledex.LedDriver.t
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
