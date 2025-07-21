# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.LedStripSupervisor do
  use Supervisor

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

  # MARK: client side
  def start_link(strip_name, drivers, global_configs) do
    Supervisor.start_link(
      __MODULE__,
      {strip_name, drivers, global_configs},
      name: supervisor_name(strip_name)
    )
  end

  def stop(strip_name) do
    Supervisor.stop(supervisor_name(strip_name))
  end

  @doc """
  This starts a new animation. It should be noted that it's expected
  that the led_strip is already up and running
  """
  @spec start_animation(atom, atom, Animator.config_t()) :: GenServer.on_start()
  def start_animation(strip_name, animation_name, config) do
    DynamicSupervisor.start_child(
      animations_name(strip_name),
      %{
        # no need to be unique
        id: animation_name,
        start: {Animator, :start_link, [strip_name, animation_name, config]},
        restart: :transient
      }
    )
  end

  # MARK: Server side
  @impl true
  def init({strip_name, _drivers, _global_config} = init_args) do
    Logger.debug("Starting LedStrip #{strip_name}")

    children = [
      {LedStrip, init_args},
      {DynamicSupervisor, name: animations_name(strip_name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # MARK: public helper functions
  def supervisor_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :supervisor)
  end

  def animations_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :animations)
  end
end
