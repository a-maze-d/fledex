defmodule Fledex.LedStripDriver.KinoDriver do
  @behaviour Fledex.LedStripDriver.Driver

  use Fledex.Color.Types

  @default_update_freq 50
  @base16 16
  @block <<"\u2588">>

  @impl true
  @spec init(map, Fledex.LedDriver.t) :: Fledex.LedDriver.t
  def init(init_args, state) do
    config = %{
      update_freq: init_args[:led_strip][:config][:update_freq] || @default_update_freq,
      log_color_code: init_args[:led_strip][:config][:log_color_code] || false,
      frame: init_args[:led_strip][:config][:frame] || Kino.Frame.new() |> Kino.render()
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
      frame = state.led_strip.config.frame
      output = Enum.reduce(leds, <<>>, fn value, acc ->
        hex = value |> Integer.to_string(@base16) |> String.pad_leading(6, "0")
        acc <> "<span style=\"color: ##{hex}\">" <> @block <> "</span>"
      end)
      Kino.Frame.render(frame, Kino.Markdown.new(output))
    end
    state
  end

  @impl true
  @spec terminate(reason, Fledex.LedDriver.t) :: :ok when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end

end
