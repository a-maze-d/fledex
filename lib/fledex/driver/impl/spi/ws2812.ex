# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi.Ws2812 do
  @moduledoc """
  This module is a concrete driver that will push the led data through an SPI port.
  It is mainly intended for WS2812 led strip,

  The protocol used is the one as expected by an
  [WS2812](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2812B-datasheet.pdf) chip.
  By adjusting the settings you can also use it for other led chips. See the
  [hardware](pages/hardware.md) documentation for more information on to wire it up.

  ## Changed defaults
  * `:speed_hz`: The bus speed is set to 2.6MHz (`2_600_000`) by default.
  * `:delay_us`: The default is set to 300us (which works for all supported led strips)

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

  > #### Notes {: .info}
  > * The `:delay_us` timing of the WS2812 is not consistent the same spec mentions `>=50us` as well as `>300us`. So you might have to experiment a bit. We use here the higher value because it aligns with the other supported led strips. But it has been tested with the lower value too and it seems to work.
  > * The white LED can be used by using the extended version of the `t:Fledex.Color.Types.colorint/0`.
  > * This driver has only been tested with a WS2812. All others are only based on the specs.
  """
  use Fledex.Driver.Impl.Spi

  alias Fledex.Color.RGBW
  alias Fledex.Driver.Interface

  @impl Interface
  @spec configure(keyword) :: keyword
  def configure(config) do
    config
    # overwrite defaults by setting new default values (if not already set)
    |> Keyword.put_new(:speed_hz, 2_600_000)
    |> Keyword.put_new(:delay_us, 300)
    # otherwise use defaults
    |> Utils.default_spi_config()
    # add new property (if not already defined)
    |> Keyword.put(:type, Keyword.get(config, :type, :grb))
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
end
