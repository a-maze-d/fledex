# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi do
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Correction
  alias Fledex.Color.Types
  alias Fledex.Color.Utils

  @impl true
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

  @impl true
  @spec init(keyword) :: keyword
  def init(config) do
    config = configure(config)
    Keyword.put(config, :ref, open_spi(config))
  end

  @impl true
  @spec reinit(keyword, keyword) :: keyword
  def reinit(old_config, new_config) do
    # TODO: we have to check whether we have to reconfigure the SPI port
    #       i.e. has any of the settings changed? If yes, we close the port
    #       and recreate it.
    Keyword.merge(old_config, new_config)
  end

  @spec open_spi(keyword) :: reference
  def open_spi(config) do
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

  @impl true
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, _counter, config) do
    binary =
      leds
      |> Correction.apply_rgb_correction(Keyword.fetch!(config, :color_correction))
      |> Enum.reduce(<<>>, fn led, acc ->
        {r, g, b} = Utils.to_rgb(led)
        acc <> <<r, g, b>>
      end)

    response = Circuits.SPI.transfer(Keyword.fetch!(config, :ref), binary)
    {config, response}
  end

  @impl true
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, config) do
    Circuits.SPI.close(Keyword.fetch!(config, :ref))
  end
end
