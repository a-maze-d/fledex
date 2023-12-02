defmodule Fledex.LedStripDriver.Driver do
  require Logger

  alias Fledex.Color.Types

  @callback init(module_init_args :: map) :: map
  @callback reinit(module_config::map) :: map
  @callback transfer(leds :: list(Types.colorint), counter :: pos_integer, config :: map) :: {map, response::any}
  @callback terminate(reason, config :: map) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()

  @type driver_t :: %{
    merge_strategy: atom,
    driver_modules: [module],
    config: %{atom => map}
  }

  @spec init(driver_t) :: driver_t
  def init(led_strip) do
    configs = for module <- led_strip.driver_modules do
      # Logger.trace("Creating driver: #{inspect module}")
      module_init_args = led_strip[:config][module] || %{}
      config = module.init(module_init_args)
      {module, config}
    end

    put_in(led_strip.config, Map.new(configs))
  end

  @spec reinit(driver_t) :: driver_t
  def reinit(led_strip) do
    configs = for module <- led_strip.driver_modules do
      module_config = led_strip.config[module]
      config = module.reinit(module_config)
      {module, config}
    end
    put_in(led_strip.config, Map.new(configs))
  end

  @spec transfer(list(Types.colorint), pos_integer, driver_t) :: driver_t
  def transfer(leds, counter, led_strip) do
      configs = for module <- led_strip.driver_modules do
      {config, _response} = module.transfer(leds, counter, led_strip[:config][module])
      {module, config}
    end

    put_in(led_strip.config, Map.new(configs))
  end

  @spec terminate(reason, driver_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, led_strip) do
    for module <- led_strip.driver_modules do
      module.terminate(reason, led_strip[:config][module])
    end
    :ok
  end
end
