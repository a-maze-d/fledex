# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Interface do
  @moduledoc """
  This interface defines the `@behaviour` for drivers. They can be
  dummy implementations like a driver that dumps the output to IO,
  wich can be useful for testing without real hardware.
  A proper implementation probably opens a channel (if not already open)
  to the bus (like SPI) and sends the data to the bus.

  Differen types of drivers exist. Currently the following exist:

  * [`Null`](Fledex.Driver.Impl.Null.html): a driver that doesn't do
      anything. This is the default driver. It's also very practical for tests.
  * [`Logger`](Fledex.Driver.Impl.Logger.html): a driver that logs the
      led data to the terminal or to the logs
  * [`Kino`](Fledex.Driver.Impl.Kino.html): a driver that can display
      the LEDs in a [livebook](https://livebook.dev)
  * [`Spi`](Fledex.Driver.Impl.Spi.html): a driver that can connect
      to a real LED strip with a WS2801 chip.
  * [`PubSub`](Fledex.Driver.Impl.PubSub.html): a driver that can transfer
      the LED data via pubsub. This should also allow the data to be transferred to
      a LED strip connected on another computer.

  More Drivers can be created by implementing this simple behaviour

  > #### Note {: .info}
  >
  > The implementing module is allowed to store information in the state
  > (like the channel it has oppened), so that we don't have open/close it
  > all the time. Cleanup should happen in the terminate function
  """

  alias Fledex.Color.Types

  @doc """
  This callback will be called to retrieve the default set of parameters for
  this driver. It will be used as default and then ovelayed with the additional arguments
  passed in (which can be passed in to the function)
  """
  @callback configure(keyword) :: keyword

  @doc """
  The init function will be called after the `Fledex.LedStrip` is initialized as part
  of the initialization process. A map of initalization arguments are passed to
  the driver. The driver can decide what to do with them. The returned map is a
  configuration that gets passed to any of the other driver functions.
  """
  @callback init(module_config :: keyword, global_config :: map) :: keyword
  @doc """
  In some cases it is necessary to reinitialize the driver when a new LED strip
  is defined (see the `Fledex.Driver.Impl.Kino` as an example). The
  driver should know whether it needs to do anything or not. If it does not need
  to do anything, then simply return the passed in keyword list, i.e.:

  ```elixir
  def reinit(_old_module_config, new_module_config, _global_config), do: new_module_config
  ```
  """
  @callback reinit(
              old_module_config :: keyword,
              new_module_config :: keyword,
              global_config :: map
            ) :: keyword
  @doc """
  This is the main function where we transfer the LED information to the "hardware"
  The `leds` is a list of integers, (color codes of the form `0xrrggbb` if written in
  hexadecimal format).
  The `counter` is a counter that gets incremented in each update loop and thereby allows
  to transfer the data with a lower frequency by not transferring it in every loop.
  The `module_config` is the config that got returned by the `init/1` or `reinit/1`
  functions
  """
  @callback transfer(leds :: list(Types.colorint()), counter :: pos_integer, config :: keyword) ::
              {config :: keyword, response :: any}

  @doc """
  The terminate functions gets called when we dispose of the led strip. This the place
  where the driver can perform some cleanup (e.g.: close some channels)
  """
  @callback terminate(reason, config :: keyword) :: :ok
            when reason: :normal | :shutdown | {:shutdown, term()} | term()
end
