# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi.Ws2812 do
  @moduledoc """
  This module is a concrete driver that will push the led data through an SPI port.

  The protocol used is the one as expected by an
  [WS2812](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2812B-datasheet.pdf) chip.

  ## Options
  This driver accepts the options specied by `Fledex.Driver.Impl.Spi`. You can in addition
  specify the led type (default: `:grb`). This way you should be able to use it also for a
  [WS2811](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2811-datasheet.pdf)
  led strip by specifying `:rgb`, and for
  [WS2813](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2813-RGBW-datasheet.pdf),
  [WS2814](https://suntechlite.com/wp-content/uploads/2024/06/WS2814-IC-Datasheet_V1.4_EN.pdf),
  and [WS2815](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2815-datasheet.pdf)
  led strips by specifying `:grbw`.

  > #### Note {: .info}
  > * The white LED will not be used.
  > * This hasn't been tested and is only based on the spec
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
      speed_hz: Keyword.get(config, :speed_hz, 2_600_000),
      delay_us: Keyword.get(config, :delay_us, 10),
      lsb_first: Keyword.get(config, :lsb_first, false),
      color_correction: Keyword.get(config, :color_correction, Correction.no_color_correction()),
      type: Keyword.get(config, :type, :grb),
      ref: nil
    ]
  end

  @impl Spi
  @spec convert_to_bits(byte(), byte(), byte(), keyword) :: bitstring()
  def convert_to_bits(r, g, b, config) do
    # The  SPI port is fast enough to bang out the bits so that they have the right
    # length. With 2.6MHz each bit has a length of 385ns.
    # According to the datasheet:
    # Each bit should should have a length for T0H/T1L of up to 380ns/420ns (close enough)
    # and for T1H/T0L a minimum length of 750ns (i.e. two times the length of a
    # bit, 2x385ns = 770ns)
    # Thus, we can just represent every bit with 3 bits 0 = 100, 1 = 110
    # WATCH OUT: the order is grb and not rgb!!!
    leds =
      case Keyword.get(config, :type, :grb) do
        :rgb -> <<r, g, b>>
        :grb -> <<g, r, b>>
        :grbw -> <<g, r, b, 0>>
      end

    Stream.unfold(leds, fn
      <<>> -> nil
      <<0::1, rest::bitstring>> -> {0b100, rest}
      <<1::1, rest::bitstring>> -> {0b110, rest}
    end)
    |> Enum.reduce(<<>>, fn bits, acc -> <<acc::bitstring, <<bits::3>>::bitstring>> end)
  end

  @impl Spi
  @spec add_reset(bitstring(), keyword) :: bitstring()
  def add_reset(bits, _config) do
    # we need at least 50us as reset ==> 385ns*130 = 50050ns ~50us
    # we round it up to 256
    # Note: we can hardcode the value, since the frequency should not
    # vary too much from the default.
    <<bits::bitstring, 0::256>>
  end
end
