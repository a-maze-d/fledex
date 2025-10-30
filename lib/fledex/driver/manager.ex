# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Manager do
  @moduledoc """
  This modules manages a (set of) concrete driver(s).

  This module is used by the `Fledex.LedStrip` and the dispatches to the concrete `Fledex.Driver.Impl`-driver (or even drivers).
  """
  require Logger

  alias Fledex.Color.Types
  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Interface

  @typedoc """
  The structure to hold the driver related data.

  It consists of tuples with:

  * `driver`: Which modules should get loaded. Each module usually should have
      a default configuration, which can then be overwritten with specific
      settings
  * `config`: a keyword list to modify the default settings. Each module has
      their own set of settings. You need to check the driver module documentation
      for allowed settings

  > #### Note {: .info}
  >
  > You can specify a driver module several times and give them different settings.
  > This allows for example to send the same data to two different SPI ports.
  >
  > Example:
  > ```elixir
  > {Fledex.Driver.Impl.Kino, update_freq: 10 }
  > ```
  """
  @type driver_t :: {driver :: module, config :: keyword()}
  @typedoc """
  This structure is for holding several `driver_t` structures.
  """
  @type drivers_t :: [driver_t()]

  @doc false
  @spec init_drivers(list({module, keyword}), map) :: list({module, any})
  def init_drivers(drivers, global_config) do
    drivers = remove_invalid_drivers(drivers)

    drivers =
      if Enum.empty?(drivers) do
        [{Null, []}]
      else
        drivers
      end

    for {module, module_config} <- drivers do
      # Logger.trace("Creating driver: #{inspect module}")
      config = module.init(module_config, global_config)
      {module, config}
    end
  end

  @doc false
  @spec reinit(old_drivers :: drivers_t, new_drivers :: drivers_t, map) :: drivers_t
  def reinit(old_drivers, [], global_config) do
    reinit(old_drivers, [{Null, []}], global_config)
  end

  def reinit(old_drivers, new_drivers, global_config) do
    new_drivers = Enum.sort(new_drivers)

    case same_drivers(old_drivers, new_drivers) do
      true ->
        drivers =
          Enum.zip_with([old_drivers, new_drivers], fn [
                                                         {old_module, old_config},
                                                         {_new_module, new_config}
                                                       ] ->
            # we still have a minimalistic new_config. hence we need to get a proper
            # set by calling the configure function to get the defaults and overlay
            # with the new configs. This is now the "new_config" that we can compare
            # with the old config.
            # It is the responsibility of the reinit function to "merge" the old and
            # new config to ensure extra parameters are preserved.
            new_config = old_module.configure(new_config)
            config = old_module.reinit(old_config, new_config, global_config)
            {old_module, config}
          end)

        # `same_drivers` checks only the number of drivers we had so far with the
        # ones passed in. But we could pass in additional ones.
        new_drivers_length = length(new_drivers)
        old_drivers_length = length(old_drivers)

        extra_drivers =
          case old_drivers_length < new_drivers_length do
            true ->
              init_drivers(
                Enum.slice(new_drivers, old_drivers_length..new_drivers_length),
                global_config
              )

            false ->
              []
          end

        extra_drivers ++ drivers

      false ->
        terminate(:normal, old_drivers)
        init_drivers(new_drivers, global_config)
    end
  end

  # This function compares whether the passed in old_drivers can also be found
  # in the new_drivers struct. Note: The new_drivers might contain additional
  # drivers at the end not found in old_drivers.
  defp same_drivers(old_drivers, new_drivers) do
    Enum.zip_reduce([old_drivers, new_drivers], true, fn [
                                                           {old_driver_module, _old_config},
                                                           {new_driver_module, _new_config}
                                                         ],
                                                         acc ->
      case old_driver_module == new_driver_module do
        true -> acc
        false -> false
      end
    end)
  end

  @doc false
  @spec transfer(list(Types.colorint()), pos_integer, drivers_t) :: drivers_t
  def transfer(leds, counter, drivers) do
    for {module, config} <- drivers do
      {config, _response} = module.transfer(leds, counter, config)
      {module, config}
    end
  end

  @doc false
  @spec terminate(reason, drivers_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, drivers) do
    for {module, config} <- drivers do
      module.terminate(reason, config)
    end

    :ok
  end

  @spec remove_invalid_drivers(list({module, keyword})) :: list({module, keyword})
  def remove_invalid_drivers(drivers) do
    Enum.filter(drivers, fn {driver_module, _driver_config} ->
      if driver_valid(driver_module) do
        true
      else
        Logger.warning(
          "Driver '#{inspect(driver_module)}' invalid and therefore removed as driver"
        )

        false
      end
    end)
  end

  @spec driver_valid(atom) :: boolean
  def driver_valid(driver_module) when is_atom(driver_module) do
    # this is only to do a rough validation to catch the biggest
    # issues early on.
    required_functions = Interface.behaviour_info(:callbacks)
    module_functions = driver_module.__info__(:functions)

    existing_functions =
      Enum.map(required_functions, fn {function, arity} ->
        case Keyword.fetch(module_functions, function) do
          {:ok, ^arity} ->
            true

          {:ok, value} ->
            Logger.error(
              "The driver #{inspect(driver_module)} implements the function #{function} but with the wrong arity #{value} vs #{arity}"
            )

            false

          :error ->
            Logger.error(
              "The driver #{inspect(driver_module)} does not implement the function #{inspect(function)}"
            )

            false
        end
      end)

    Enum.reduce(existing_functions, true, fn existing, acc ->
      if existing, do: acc, else: false
    end)
  end
end
