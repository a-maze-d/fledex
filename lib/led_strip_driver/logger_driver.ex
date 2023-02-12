defmodule Fledex.LedStripDriver.LoggerDriver do
  @behaviour Fledex.LedStripDriver.Driver
  use Fledex.Color.Types

  alias Fledex.Utils

  @default_update_freq 10
  @divisor 255/5
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
  @spec init(map, Fledex.LedDriver.t) :: Fledex.LedDriver.t
  def init(init_args, state) do
    config = %{
      update_freq: init_args[:led_strip][:config][:update_freq] || @default_update_freq,
      log_color_code: init_args[:led_strip][:config][:log_color_code] || false
    }
    state
    |> put_in([Access.key(:led_strip, %{}), Access.key(:config, %{})], config)
  end

  @impl true
  @spec transfer(list(colorint), Fledex.LedDriver.t) :: Fledex.LedDriver.t
  def transfer(leds, state) do
    counter = state.timer.counter
    update_freq = state.led_strip.config.update_freq

    if (rem(counter, update_freq) == 0 and length(leds) > 0) do
      log_color_code = state.led_strip.config.log_color_code
      output = Enum.reduce(leds, <<>>, fn value, acc ->
        if log_color_code do
          acc <> <<value>>
        else
          acc <> to_ansi_color(value) <> @block
        end
      end)
      IO.puts(output <> "\r")
    end
    state
  end

  @spec to_ansi_color(colorint) :: String.t
  defp to_ansi_color(value) do
    {r,g,b} = Utils.split_into_subpixels(value)
    IO.ANSI.color(trunc(r/@divisor), trunc(g/@divisor), trunc(b/@divisor))
  end

  @impl true
  @spec terminate(reason, Fledex.LedDriver.t) :: :ok when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
