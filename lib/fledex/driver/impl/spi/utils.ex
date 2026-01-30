# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Driver.Impl.Spi.Utils do
  @moduledoc """
  Some utily functions for the Spi driver
  """
  alias Fledex.Color.Types

  @doc """
  Clears `number` leds at startup if the `clear_leds: <number>` option was specified
  in the config.
  """
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

  @doc """
  Opens the SPI port with the configuration and returns the reference
  """
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
end
