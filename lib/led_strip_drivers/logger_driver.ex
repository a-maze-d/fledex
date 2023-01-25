defmodule LedStripDrivers.LoggerDriver do
  @behaviour LedStripDriver
  @divisor 255/5
  @block <<"\u2588">>

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
  def transfer(leds, state) do
    output = Enum.reduce(leds, <<>>, fn value, acc ->
      acc <> to_ansi_color(value) <> @block
    end)
    IO.puts(output <> "\r")
    state
  end

  defp to_ansi_color(value) do
    {r,g,b} = LedsDriver.split_into_subpixels(value)
    IO.ANSI.color(trunc(r/@divisor), trunc(g/@divisor), trunc(b/@divisor))
  end

  @impl true
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
