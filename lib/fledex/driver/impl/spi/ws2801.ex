# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi.Ws2801 do
  @moduledoc """
  This module is a concrete driver that will push the led data through an SPI port.

  The protocol used is the one as expected by an
  [WS2801](https://cdn-shop.adafruit.com/datasheets/WS2801.pdf) chip. See the
  [hardware](pages/hardware.md) documentation for more information on to wire it up.

  ## Options
  This driver accepts the options specified by `Fledex.Driver.Impl.Spi`
  """
  use Fledex.Driver.Impl.Spi

  alias Fledex.Color.Correction
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
      # for consistency we specify those too, but they are not exposed in the docs
      reset_byte: Keyword.get(config, :reset_byte, <<0>>),
      reset_bytes: Keyword.get(config, :reset_bytes, 64),
      ref: nil
    ]
  end

  @impl Spi
  @spec convert_to_bits(byte(), byte(), byte(), byte(), keyword) :: bitstring()
  def convert_to_bits(r, g, b, _w, _config) do
    <<r, g, b>>
  end

  @impl Spi
  @spec add_reset(bitstring(), keyword) :: bitstring()
  def add_reset(bits, config) do
    # to prepare for the data transport we should start with >500us silence.
    # this corresponds to 500 bits if we run at the default 1MHz.
    # we don't expect the frequency to be dramatically changed and we don't
    # want to recalculate the necessary value in every transfer.
    reset_byte = Keyword.get(config, :reset_byte, <<0>>)
    reset_bytes = Keyword.get(config, :reset_bytes, 64)

    reset_sequence = :binary.copy(reset_byte, reset_bytes)
    <<reset_sequence::bitstring, bits::bitstring>>
  end
end
