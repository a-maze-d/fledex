# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Spi do
  @moduledoc """
  This module is the base for SPI based drivers.

  ## Options
  This module is not a concrete driver, but usually the concrete drivers make use of
  `Fledex.Driver.Impl.Spi.Utils.default_spi_config/1` to configure the SPI port.
  Concrete drivers can both define different defaults and implement additional options,
  but you can expect to find the following:

  * `:dev`: SPI device name (default "spidev0.0", see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:mode`: set clock polarity and phase (default: mode `0`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details),
  * `:bits_per_word`: set the bits per word on the bus (default: `8`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:speed_hz`: set the bus speed (default: `1_000_000`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:delay_us`: set the delay between transactions (default: `10`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:lsb_first`: sets whether the least significant bit is first (default: `false`, see [`Circuits.SPI.spi_option/0`](https://hexdocs.pm/circuits_spi/Circuits.SPI.html#t:spi_option/0) for details).
  * `:color_correction`: specifies the color correction (see `Fledex.Color.Correction` for details)
  * `:clear_leds`: Sets the number of leds that should be cleared during startup (default: `0`)

  > #### Warning {: .warning}
  >
  > Be careful, because specific drivers might need very specific settings. You really
  > should understand the driver before you modify any option.
  """

  alias Fledex.Color.Correction
  alias Fledex.Color.RGBW
  alias Fledex.Color.Types
  alias Fledex.Driver.Interface

  @doc """
  Before we can transfer the `rgb` values we need to convert them to the a bitstring
  that we can send over the wire. Any SPI driver `use`-ing this module, needs to
  implement the conversion in this function
  """
  @callback convert_to_bits(RGBW.t(), config :: keyword) ::
              bitstring()

  @doc """
  If you want to implement a new SPI driver you can use this module as a base.

  This way you only have to have to implement the callbacks
  `c:Fledex.Driver.Interface.configure/1` and from this module:
  `c:convert_to_bits/2`.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Fledex.Driver.Impl.Spi
      @behaviour Fledex.Driver.Interface

      alias Fledex.Color.Correction
      alias Fledex.Color.RGB
      alias Fledex.Color.Types
      alias Fledex.Driver.Impl.Spi
      alias Fledex.Driver.Impl.Spi.Utils
      alias Fledex.Driver.Interface

      @doc false
      @impl Interface
      @spec init(keyword, map) :: keyword
      def init(config, _global_config) do
        {clear_leds, config} = Keyword.pop(config, :clear_leds, 0)
        config = configure(config)
        config = Keyword.put(config, :ref, Utils.open_spi(config))
        Utils.clear_leds(clear_leds, config, &transfer/3)
      end

      @doc false
      @impl Interface
      @spec change_config(keyword, keyword, map) :: keyword
      def change_config(old_config, new_config, _global_config) do
        config = Keyword.merge(old_config, new_config)
        # Maybe the following code could be optimized
        # to only reopen the port if it's necessary. But this is safe
        :ok = terminate(:normal, old_config)
        Keyword.put(config, :ref, Utils.open_spi(config))
      end

      @doc false
      @impl Interface
      @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
      def transfer(leds, _counter, config) do
        binary =
          leds
          |> Correction.apply_rgb_correction(Keyword.fetch!(config, :color_correction))
          |> Enum.reduce(<<>>, fn led, acc ->
            acc <> convert_to_bits(RGBW.new(led), config)
          end)

        response = Circuits.SPI.transfer(Keyword.fetch!(config, :ref), binary)
        {config, response}
      end

      @doc false
      @impl Interface
      @spec terminate(reason, keyword) :: :ok
            when reason: :normal | :shutdown | {:shutdown, term()} | term()
      def terminate(_reason, config) do
        Circuits.SPI.close(Keyword.fetch!(config, :ref))
      end

      defoverridable transfer: 3
    end
  end
end
