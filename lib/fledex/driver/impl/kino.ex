# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Kino do
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Correction
  alias Fledex.Color.Types

  # TODO: review this
  # we update as often as the driver updates us
  @default_update_freq 1
  @base16 16
  @block <<"\u2588">>

  @impl true
  @spec configure(keyword) :: keyword
  def configure(config) do
    [
      update_freq: Keyword.get(config, :update_freq, @default_update_freq),
      # only call the Kino functions if necessary
      frame: Keyword.get(config, :frame, Kino.Frame.new() |> Kino.render()),
      color_correction: Keyword.get(config, :color_correction, Correction.no_color_correction())
    ]
  end

  @impl true
  @spec init(keyword, keyword) :: keyword
  def init(config, global_config) do
    set_group_leader(global_config)
    configure(config)
  end

  defp set_group_leader(global_config) do
    # we need to ensure that we set the correct group leader, otherwise
    # the output will might go the wrong direction.
    group_leader = Map.get(global_config, :group_leader, Process.group_leader())
    Process.group_leader(self(), group_leader)
  end

  @impl true
  @spec reinit(keyword, keyword, keyword) :: keyword
  # def reinit(_old_config, new_config, _global_config), do: new_config
  def reinit(old_config, new_config, global_config) do
    set_group_leader(global_config)

    Keyword.merge(
      old_config,
      Keyword.put(new_config, :frame, Kino.Frame.new() |> Kino.render())
    )
  end

  @impl true
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, counter, config) do
    # IO.puts(inspect Keyword.fetch!(config, :frame))
    if rem(counter, Keyword.fetch!(config, :update_freq)) == 0 and length(leds) > 0 do
      output =
        leds
        |> Correction.apply_rgb_correction(Keyword.fetch!(config, :color_correction))
        |> Enum.reduce(<<>>, fn value, acc ->
          hex = value |> Integer.to_string(@base16) |> String.pad_leading(6, "0")
          acc <> "<span style=\"color: ##{hex}\">" <> @block <> "</span>"
        end)

      # IO.puts("correct group leader? #{inspect Process.group_leader()}")
      :ok =
        Kino.Frame.render(
          Keyword.fetch!(config, :frame),
          Kino.Markdown.new(output)
        )
    end

    {config, :ok}
  end

  @impl true
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    # nothing needs to be done here
    :ok
  end
end
