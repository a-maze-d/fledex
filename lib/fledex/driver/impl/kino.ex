# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Kino do
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Correction
  alias Fledex.Color.Types

  # we update as often as the driver updates us
  @default_update_freq 1
  @base16 16
  @block <<"\u2588">>

  @impl true
  @spec init(map) :: map
  def init(init_args) do
    default_config = %{
      update_freq: @default_update_freq,
      # only call the Kino functions if necessary
      frame: init_args[:frame] || Kino.Frame.new() |> Kino.render(),
      color_correction: Correction.no_color_correction()
    }
    Map.merge(default_config, init_args)
  end

  @impl true
  @spec reinit(map) :: map
  def reinit(module_config) do
    %{module_config | frame: Kino.Frame.new() |> Kino.render()}
  end

  @impl true
  @spec transfer(list(Types.colorint), pos_integer, map) :: {map, any}
  def transfer(leds, counter, config) do
    if (rem(counter, config.update_freq) == 0 and length(leds) > 0) do
      output = leds
        |> Correction.apply_rgb_correction(config.color_correction)
        |> Enum.reduce(<<>>, fn value, acc ->
          hex = value |> Integer.to_string(@base16) |> String.pad_leading(6, "0")
          acc <> "<span style=\"color: ##{hex}\">" <> @block <> "</span>"
      end)
      :ok = Kino.Frame.render(config.frame, Kino.Markdown.new(output))
    end
    {config, :ok}
  end

  @impl true
  @spec terminate(reason, map) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end

end
