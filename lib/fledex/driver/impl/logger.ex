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

  ## Options
  The following options can be passed to this driver:
  * `:update_freq`: the frequency on how often the data is dumped (default: `10`, meaning that only every `10`th redraw is printed out).
  * `:color`: whether to use terminal colors in the output (default: `false`)
  * `:terminal`: whether to dump to the terminal (`true`, default) or to the `Logger` (`false`)
  """
  @behaviour Fledex.Driver.Interface
  require Logger

  alias Fledex.Color.RGB
  alias Fledex.Color.Types
  alias Fledex.Driver.Interface

  @default_update_freq 10
  @divisor 255 / 5
  @block <<"\u2588">>

  @impl Interface
  @spec configure(keyword) :: keyword
  def configure(config) do
    [
      update_freq: Keyword.get(config, :update_freq, @default_update_freq),
      color: Keyword.get(config, :color, false),
      terminal: Keyword.get(config, :terminal, true)
    ]
  end

  @impl Interface
  @spec init(keyword, map) :: keyword
  def init(config, _global_config) do
    configure(config)
  end

  @impl Interface
  @spec change_config(keyword, keyword, map) :: keyword
  def change_config(old_config, new_config, _global_config) do
    Keyword.merge(old_config, new_config)
  end

  @impl Interface
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, _counter, config) when leds == [] do
    {config, :ok}
  end

  def transfer(leds, counter, config) do
    if rem(counter, Keyword.fetch!(config, :update_freq)) == 0 do
      log_color_mode = Keyword.fetch!(config, :color)

      output =
        Enum.reduce(leds, <<>>, fn value, acc ->
          add(acc, value, log_color_mode)
        end)

      if Keyword.fetch!(config, :terminal) do
        # credo:disable-for-next-line
        IO.puts(output <> "\r")
      else
        Logger.info(output <> "\r")
      end
    end

    {config, :ok}
  end

  @impl Interface
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    # nothing needs to be done here
    :ok
  end

  # MARK: private utilty functions
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
end
