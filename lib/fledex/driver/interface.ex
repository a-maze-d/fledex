defmodule Fledex.Driver.Interface do

  alias Fledex.Color.Types

  @moduledoc """
    A driver dispatches the "real" hardware. Differen types of
    drivers exist. Currently the following drivers exist:

    * [`NullDriver`](Fledex.Driver.Impl.NullDriver.html): a driver that doesn't do
        anything. This is the default driver. It's also very practical for tests.
    * [`LoggerDriver`](Fledex.Driver.Impl.LoggerDriver.html): a driver that logs the
        led data to the terminal or to the logs
    * [`KinoDriver`](Fledex.Driver.Impl.KinoDriver.html): a driver that can display
        the LEDs in a [livebook](https://livebook.dev)
    * [`SpiDriver`](Fledex.Driver.Impl.SpiDriver.html): a driver that can connect
        to a real LED strip with a WS2801 chip.
    * [`PubSubDrive`](Fledex.Driver.Impl.PubSubDriver.html): a driver that can transfer
        the LED data via pubsub. This should also allow the data to be transferred to
        a LED strip connected on another computer.

    More Drivers can be created by implementing the simple behaviour
  """
  @doc """
  The init function will be called after the LedsDriver is initialized as part
  of the initialization process. A map of initalization arguments are passed to
  the driver. The driver can decide what to do with them. The returned map is a
  configuration that gets passed to any of the other driver functions.
  """
  @callback init(module_init_args :: map) :: map
  @doc """
  In some cases it is necessary to reinitialize the driver when a new LED strip
  is defined (see the `Fledex.Driver.Impl.KinoDriver` as an example). The
  driver should know whether it needs to do anything or not. If it does not need
  to do anything, then simply return the passed in map, i.e.:

  ```elixir
  def reinit(module_config), do: driver_config
  ```
  """
  @callback reinit(module_config::map) :: map
  @doc """
  This is the main function where we transfer the LED information to the "hardware"
  The `leds` is a list of integers, (color codes of the form `0xrrggbb` if written in
  hexadecimal format).
  The `counter` is a counter that gets incremented in each update loop and thereby allows
  to transfer the data with a lower frequency by not transferring it in every loop.
  The `module_config` is the config that got returned by the `init/1` or `reinit/1`
  functions
  """
  @callback transfer(leds :: list(Types.colorint), counter :: pos_integer, module_config :: map) :: {map, response::any}

  @doc """
  THe terminate functions gets called when we dispose of the led strip. This the place
  where the driver can perform some cleanup (e.g.: close some channels)
  """
  @callback terminate(reason, config :: map) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()
end
