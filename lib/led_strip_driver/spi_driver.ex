defmodule Fledex.LedStripDriver.SpiDriver do
  alias Fledex.Color.Correction

  @behaviour Fledex.LedStripDriver.Driver
  use Fledex.Color.Types

  @impl true
  @spec init(map) :: map
  def init(init_module_args) do
    config = %{
      dev: init_module_args[:dev] || "spidev0.0",
      mode: init_module_args[:mode] || 0,
      bits_per_word: init_module_args[:bits_per_word] || 8,
      speed_hz: init_module_args[:speed_hz] || 1_000_000,
      delay_us: init_module_args[:delay_us] || 10,
      lsb_first: init_module_args[:lsb_first] || false,
      color_correction: init_module_args[:color_correction] || Correction.no_color_correction(),
      ref: nil
    }

    put_in(config.ref, open_spi(config))
  end

  @spec open_spi(map) :: reference
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
  @spec transfer(list(colorint), pos_integer, map) :: map
  def transfer(leds, _counter, config) do
    binary = leds
      |> Correction.apply_rgb_correction(config.color_correction)
      |> Enum.reduce(<<>>, fn led, acc ->
        {r,g,b} = Fledex.Color.Utils.convert_to_subpixels(led)
        acc <> <<r, g, b>>
      end)
    {:ok, _} = Circuits.SPI.transfer(config.ref, binary)
    config
  end

  @impl true
  @spec terminate(reason, map) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, config) do
    Circuits.SPI.close(config.ref)
  end
end
