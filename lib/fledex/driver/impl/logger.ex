# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Logger do
  @moduledoc """
    This driver can log the data either to `IO` or to a `Logger`.

    When logging to IO an attempt is made to preserve the colors, which
    is difficult due to the more restrictive nature of the IO colors
    (5bit instead of 8bit). It's probably best to stick to the
    [ANSI defined colors](https://www.ditig.com/256-colors-cheat-sheet)
  """
  @behaviour Fledex.Driver.Interface
  require Logger

  alias Fledex.Color.RGB
  alias Fledex.Color.Types

  @default_update_freq 10
  @divisor 255 / 5
  @block <<"\u2588">>

  @impl true
  @spec configure(keyword) :: keyword
  def configure(config) do
    [
      update_freq: Keyword.get(config, :update_freq, @default_update_freq),
      log_color_code: Keyword.get(config, :log_color_code, false),
      terminal: Keyword.get(config, :terminal, true)
    ]
  end

  @impl true
  @spec init(keyword, map) :: keyword
  def init(config, _global_config) do
    configure(config)
  end

  @impl true
  @spec reinit(keyword, keyword, map) :: keyword
  def reinit(old_config, new_config, _global_config) do
    Keyword.merge(old_config, new_config)
  end

  @impl true
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, _counter, config) when leds == [] do
    {config, :ok}
  end

  def transfer(leds, counter, config) do
    if rem(counter, Keyword.fetch!(config, :update_freq)) == 0 do
      log_color_mode = Keyword.fetch!(config, :log_color_code)

      output =
        Enum.reduce(leds, <<>>, fn value, acc ->
          add(acc, value, log_color_mode)
        end)

      if Keyword.fetch!(config, :terminal) do
        IO.puts(output <> "\r")
      else
        Logger.info(output <> "\r")
      end
    end

    {config, :ok}
  end

  @spec add(acc :: String.t(), value :: Types.colorint(), log_color_mode :: boolean) :: String.t()
  defp add(acc, value, true) do
    acc <> Integer.to_string(value) <> ","
  end

  defp add(acc, value, false) do
    acc <> to_ansi_color(value) <> @block
  end

  @spec to_ansi_color(Types.colorint()) :: String.t()
  defp to_ansi_color(value) do
    %RGB{r: r, g: g, b: b} = RGB.new(value)
    IO.ANSI.color(trunc(r / @divisor), trunc(g / @divisor), trunc(b / @divisor))
  end

  @impl true
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    # nothing needs to be done here
    :ok
  end
end
