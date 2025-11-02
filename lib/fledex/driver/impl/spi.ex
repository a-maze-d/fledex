# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi do
  @moduledoc """
  This module is a concrete driver that will push the led data through an SPI port.

  The protocol used is the one as expected by an WS2801 chip. See the
  [hardware](docs/hardware.md) documentation for more information on to wire it.

  ## Options
  This driver accepts the following options (most of them are very SPI specific and the defaults are probably good enough):
  * `:dev`: SPI device name (default "spidev0.0", see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:mode`: set clock polarity and phase (default: mode `0`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details),
  * `:bits_per_word`: set the bits per word on the bus (default: `8`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:speed_hz`: set the bus speed (default: `1_000_000`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:delay_us`: set the delay between transactions (default: `10`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:lsb_first`: sets whether the least significant bit is first (default: `false`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:color_correction`: specifies the color correction (see `Fledex.Color.Correction` for details)
  * `:clear_leds`: Sets the number of leds that should be cleared during startup (default: `0`)
  """
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Correction
  alias Fledex.Color.RGB
  alias Fledex.Color.Types
  alias Fledex.Driver.Interface

  @impl Interface
  @spec configure(keyword) :: keyword
  def configure(config) do
    [
      dev: Keyword.get(config, :dev, "spidev0.0"),
      mode: Keyword.get(config, :mode, 0),
      bits_per_word: Keyword.get(config, :bits_per_word, 8),
      speed_hz: Keyword.get(config, :speed_hz, 1_000_000),
      delay_us: Keyword.get(config, :delay_us, 10),
      lsb_first: Keyword.get(config, :lsb_first, false),
      color_correction: Keyword.get(config, :color_correction, Correction.no_color_correction()),
      ref: nil
    ]
  end

  @impl Interface
  @spec init(keyword, map) :: keyword
  def init(config, _global_config) do
    {clear_leds, config} = Keyword.pop(config, :clear_leds, 0)
    config = configure(config)
    config = Keyword.put(config, :ref, open_spi(config))
    clear_leds(clear_leds, config, &transfer/3)
  end

  @impl Interface
  @spec reinit(keyword, keyword, map) :: keyword
  def reinit(old_config, new_config, _global_config) do
    config = Keyword.merge(old_config, new_config)
    # Maybe the following code could be optimized
    # to only reopen the port if it's necessary. But this is safe
    :ok = terminate(:normal, old_config)
    Keyword.put(config, :ref, open_spi(config))
  end

  @impl Interface
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, _counter, config) do
    binary =
      leds
      |> Correction.apply_rgb_correction(Keyword.fetch!(config, :color_correction))
      |> Enum.reduce(<<>>, fn led, acc ->
        %RGB{r: r, g: g, b: b} = RGB.new(led)
        acc <> <<r, g, b>>
      end)

    response = Circuits.SPI.transfer(Keyword.fetch!(config, :ref), binary)
    {config, response}
  end

  @impl Interface
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, config) do
    Circuits.SPI.close(Keyword.fetch!(config, :ref))
  end

  # MARK: utility functions
  @doc false
  @spec clear_leds(
          count :: non_neg_integer | {count :: non_neg_integer, color :: non_neg_integer},
          config :: keyword,
          clear_func :: (list(Types.colorint()), pos_integer, keyword -> {keyword, any})
        ) :: keyword
  def clear_leds(count, config, clear_func) when is_integer(count) do
    # set it to black by default
    clear_leds({count, 0x000000}, config, clear_func)
  end

  def clear_leds({count, color} = _clear_leds, config, clear_func)
      when is_integer(count) and count > 0 do
    leds =
      Enum.reduce(1..count, [], fn _index, acc ->
        [color | acc]
      end)

    {config, _response} = clear_func.(leds, count, config)
    config
  end

  def clear_leds({0, _color} = _clear_leds, config, _clear_func), do: config

  @spec open_spi(keyword) :: reference
  defp open_spi(config) do
    {:ok, ref} =
      Circuits.SPI.open(
        Keyword.fetch!(config, :dev),
        mode: Keyword.fetch!(config, :mode),
        bits_per_word: Keyword.fetch!(config, :bits_per_word),
        speed_hz: Keyword.fetch!(config, :speed_hz),
        delay_us: Keyword.fetch!(config, :delay_us),
        lsb_first: Keyword.fetch!(config, :lsb_first)
      )

    ref
  end
end
