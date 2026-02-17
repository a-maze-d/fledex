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

  alias Fledex.Color.RGBW
  alias Fledex.Driver.Interface

  @impl Interface
  @spec configure(keyword) :: keyword
  def configure(config) do
    config
    # overwrite defaults by setting new default values (if not already set)
    |> Keyword.put_new(:speed_hz, 1_000_000)
    |> Keyword.put_new(:delay_us, 500)
    # otherwise use defaults
    |> Utils.default_spi_config()

    # here would come new properties, but we don't have any.
  end

  @impl Spi
  @spec convert_to_bits(RGBW.t(), keyword) :: bitstring()
  def convert_to_bits(%RGBW{r: r, g: g, b: b}, _config) do
    <<r::8, g::8, b::8>>
  end
end
