defmodule Fledex.LedStripDriver.LoggerDriver do
  @behaviour Fledex.LedStripDriver.Driver
  require Logger

  alias Fledex.Color.Types
  alias Fledex.Color.Utils

  @default_update_freq 10
  @divisor 255 / 5
  @block <<"\u2588">>

  @moduledoc """
    This is a dummy implementation of the LedStripDriver that dumps
    the binaries to IO. This can be useful if you want to run
    some tests without real hardware.
    The real implementatin probably opens a channel (if not already open)
    to the bus (like SPI) sends the data to the bus.

    Note: this module is allowed to store information in the state
    (like the channel it has oppened), so that we don't have open/close it
    all the time. Cleanup should happen in the terminate function
  """
  @impl true
  @spec init(map) :: map
  def init(init_module_args) do
    default_config = %{
      update_freq: @default_update_freq,
      log_color_code: false,
      terminal: true
    }
    Map.merge(default_config, init_module_args)
  end

  @impl true
  @spec reinit(map) :: map
  def reinit(module_config) do
    module_config
  end

  @impl true
  @spec transfer(list(Types.colorint), pos_integer, map) :: {map, any}
  def transfer(leds, counter, config) when rem(counter, config.update_freq) == 0 and leds != [] do
      output = Enum.reduce(leds, <<>>, fn value, acc ->
        if config.log_color_code do
          acc <> Integer.to_string(value) <> ","
        else
          acc <> to_ansi_color(value) <> @block
        end
      end)
      if config.terminal do
        IO.puts(output <> "\r")
      else
        Logger.info(output <> "\r")
      end
      {config, :ok}
  end
  def transfer(_leds, _counter, config) do
    {config, :ok}
  end

  @spec to_ansi_color(Types.colorint) :: String.t
  defp to_ansi_color(value) do
    {r, g, b} = Utils.split_into_subpixels(value)
    IO.ANSI.color(trunc(r/@divisor), trunc(g/@divisor), trunc(b/@divisor))
  end

  @impl true
  @spec terminate(reason, map) :: :ok when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
