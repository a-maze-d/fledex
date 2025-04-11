# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.AnimatorBase do
  alias Fledex.Leds

  # defmacro __using__(opts) do
  #   quote location: :keep, bind_quoted: [opts: opts] do
  #     use GenServer, opts
  #     alias Fledex.Animation.AnimatorBase
  #     alias Fledex.Animation.Utils

  #     # defoverridable start_link: 3, config: 3, shutdown: 2

  #     # # MARK: server side
  #     # defoverridable handle_call: 3
  #   end
  # end

  @doc false
  @default_leds Leds.leds()
  @spec default_def_func(map) :: Leds.t()
  def default_def_func(_triggers) do
    @default_leds
  end

  @doc false
  @spec default_send_config_func(map) :: []
  def default_send_config_func(_triggers) do
    []
  end
end
