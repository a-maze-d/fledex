if Mix.target == :rpi do
  defmodule LedStripDriver.SpiDriver do
    @behaviour LedStripDriver.Driver
    import Circuits.SPI

    @impl true
    def init(init_args, state) do
      config = %{
        dev: init_args[:led_strip][:config][:dev] || "spidev0.0",
        mode: init_args[:led_strip][:config][:mode] || 0,
        bits_per_word: init_args[:led_strip][:config][:bits_per_word] || 8,
        speed_hz: init_args[:led_strip][:config][:speed_hz] || 1_000_000,
        delay_us: init_args[:led_strip][:config][:delay_us] || 10,
        lsb_first: init_args[:led_strip][:config][:lsb_first] || false,
      }

      state
        |> put_in([:led_strip, :config], config)
        |> put_in([:led_strip, :ref], open_spi(config))
    end

    def open_spi(config) do
      {:ok, ref} =
        Circuits.SPI.open(config.dev,
          mode: config.mode,
          bits_per_word: config.bits_per_word,
          speed_hz: config.speed_hz,
          delay_us: config.delay_us,
          lsb_first: config.lsb_first
        )
      ref
    end
    @impl true
    def transfer(leds, state) do
      ref = state.led_strip.ref
      binary = Enum.reduce(leds, <<>>, fn led, acc -> acc <> <<led>> end)
      {:ok, _} = Circuits.SPI.transfer(ref, binary)
      state
    end

    @impl true
    def terminate(_reason, state) do
      Circuits.SPI.close(state.led_strip.ref)
    end
  end
end
