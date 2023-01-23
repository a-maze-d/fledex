defmodule LedStripDrivers.LoggerDriver do
  @behaviour LedStripDriver

  @moduledoc """
    This is a dummy implementation of the LedStripDriver that dumps
    the binaries to the logger. This can be useful if you want to run
    some tests without real hardware.
    The real implementatin probably opens a channel (if not already open)
    to the bus (like SPI) sends the data to the bus.

    Note: this module is allowed to store information in the state
    (like the channel it has oppened), so that we don't have open/close it
    all the time. Cleanup should happen in the terminate function
  """
require Logger

  @impl true
  def init(_init_args, state) do
    # nothing needs to be done here
    state
  end

  @impl true
  def transfer(binary, state) do
    Logger.debug(binary)
    state
  end

  @impl true
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
