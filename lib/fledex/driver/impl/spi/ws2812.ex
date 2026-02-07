# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi.Ws2812 do
  @moduledoc """
  This module is a concrete driver that will push the led data through an SPI port.
  It is mainly intended for WS2812 led strip,

  The protocol used is the one as expected by an
  [WS2812](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2812B-datasheet.pdf) chip.
  By adjusting the settings you can also use it for other led chips

  ## Options
  This driver accepts the options specied by `Fledex.Driver.Impl.Spi`, but you can in addition
  specify:

  * `:led_type` (default: `:grb`): This way you should be able to use it also for a
  [WS2811](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2811-datasheet.pdf)
  led strip by specifying `:rgb`, and for
  [WS2813](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2813-RGBW-datasheet.pdf),
  [WS2814](https://suntechlite.com/wp-content/uploads/2024/06/WS2814-IC-Datasheet_V1.4_EN.pdf),
  and [WS2815](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2815-datasheet.pdf)
  led strips by specifying `:grbw`.
  You can also drive a [WS2805](https://www.superlightingled.com/PDF/WS2805-IC-Specification.pdf)
  by specifying `:rgbw1w2`. You can specify the white colors by using an colorint
  (`0xw2w2w1w1rrggbb`) or an `Fledex.Color.RGBW` structure.
  * `:reset_byte` (default: `<<0>>`): This is the byte sequence that will be added `:reset_bytes`
  times. Usually it's a sequence of 0.
  * `:reset_bytes` (default: `32`): This is how often the `:reset_byte` sequence should be
  duplicated. You should make sure that the reset sequence corresponds time wise to the spec.
  For example for a WS2812 we need at least 50us as reset sequence. At the default 2.6MHz
  frequency we get `385ns (bit length) * 130 (bits) = 50050ns ~50us`. We round it up to 256 bits.
  Thus, we need 32 reset bytes (`<<0>>`).

  > #### Note {: .info}
  > * The white LED can be used by using the extended version of the `t:Fledex.Color.Types.colorint/0`.
  > * This driver hasn't been tested and is only based on the spec.
  """
  use Fledex.Driver.Impl.Spi

  alias Fledex.Color.Correction
  alias Fledex.Color.RGBW
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
      reset_byte: Keyword.get(config, :reset_byte, <<0>>),
      reset_bytes: Keyword.get(config, :reset_bytes, 32),
      ref: nil
    ]
  end

  @impl Spi
  @spec convert_to_bits(RGBW.t(), keyword) :: bitstring()
  def convert_to_bits(%RGBW{r: r, g: g, b: b, w1: w1, w2: w2}, config) do
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
        :rgb -> <<r::8, g::8, b::8>>
        :grb -> <<g::8, r::8, b::8>>
        :grbw -> <<g::8, r::8, b::8, w1::8>>
        :rgbw1w2 -> <<r::8, g::8, b::8, w1::8, w2::8>>
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
  def add_reset(bits, config) do
    # we need at least 50us as reset ==> 385ns*130 = 50050ns ~50us
    # we round it up to 256
    # Note: we can hardcode the value, since the frequency should not
    # vary too much from the default.
    reset_byte = Keyword.get(config, :reset_byte, <<0>>)
    reset_bytes = Keyword.get(config, :reset_bytes, 32)

    reset_sequence = :binary.copy(reset_byte, reset_bytes)
    <<bits::bitstring, reset_sequence::bitstring>>
  end
end
