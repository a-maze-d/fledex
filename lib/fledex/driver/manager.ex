defmodule Fledex.Driver.Manager do
  require Logger

  alias Fledex.Color.Types
  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Interface

  @typedoc """
  The structure to hold the driver related data.

  It consists of:
  * `:driver_modules`: Which modules should get loaded. More than one module
      can be loaded at the same time
  * `config`: a map with driver specific configurations. Each driver gets its
      own configuration. The driver module name is used as key to separate
      the drivers from each other. example:
      ```elixir
      %{Fledex.Driver.Impl.Kino: %{
        update_freq: 10
      }}
      ```
  * `:merge_strategy`: The merge strategy that will be applied to
  """
  @type driver_t :: %{
    merge_strategy: atom,
    driver_modules: [module],
    config: %{atom => map}
  }

  @doc false
  @spec init_config(map) :: driver_t
  def init_config(init_args) do
    %{
      merge_strategy: init_args[:merge_strategy] || :avg,
      driver_modules: define_drivers(init_args[:driver_modules]),
      config: init_args[:config] || %{}
    }
  end

  @doc false
  @spec init_drivers(driver_t) :: driver_t
  def init_drivers(led_strip) do
    configs = for module <- led_strip.driver_modules do
      # Logger.trace("Creating driver: #{inspect module}")
      module_init_args = led_strip[:config][module] || %{}
      config = module.init(module_init_args)
      {module, config}
    end

    put_in(led_strip.config, Map.new(configs))
  end

  @doc false
  @spec reinit(driver_t) :: driver_t
  def reinit(led_strip) do
    configs = for module <- led_strip.driver_modules do
      module_config = led_strip.config[module]
      config = module.reinit(module_config)
      {module, config}
    end
    put_in(led_strip.config, Map.new(configs))
  end

  @doc false
  @spec transfer(list(Types.colorint), pos_integer, driver_t) :: driver_t
  def transfer(leds, counter, led_strip) do
      configs = for module <- led_strip.driver_modules do
      {config, _response} = module.transfer(leds, counter, led_strip[:config][module])
      {module, config}
    end

    put_in(led_strip.config, Map.new(configs))
  end

  @doc false
  @spec terminate(reason, driver_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, led_strip) do
    for module <- led_strip.driver_modules do
      module.terminate(reason, led_strip[:config][module])
    end
    :ok
  end

  @default_driver_modules [Null]
  @spec define_drivers(nil | module | [module]) :: [module]
  defp define_drivers(nil) do
    # Logger.warning("No driver_modules defined/ #{inspect @default_driver_modules} will be used")
    define_drivers(@default_driver_modules)
  end
  defp define_drivers(driver_modules) when is_list(driver_modules) do
    drivers = Enum.filter(driver_modules, fn driver -> validate_driver(driver) end)
    if length(drivers) > 0, do: drivers, else: @default_driver_modules
  end
  defp define_drivers(driver_modules) do
    Logger.warning("driver_modules is not a list")
    define_drivers([driver_modules])
  end

  defp validate_driver(driver) when is_atom(driver) do
    # this is only to do a rough validation to catch the biggest
    # issues early on.
    required_functions = Interface.behaviour_info(:callbacks)
    module_functions = driver.__info__(:functions)
    existing_functions = Enum.map(required_functions, fn {function, arity} ->
      case Keyword.fetch(module_functions, function) do
        {:ok, ^arity} -> true
        {:ok, value} ->
           Logger.error("The driver #{inspect driver} implements the function #{function} but with the wrong arity #{value} vs #{arity}")
           false
        :error ->
          Logger.error("The driver #{inspect driver} does not implement the function #{inspect function}")
          false
      end
    end)
    Enum.reduce(existing_functions, true, fn existing, acc -> if existing, do: acc, else: false end)
  end
end
