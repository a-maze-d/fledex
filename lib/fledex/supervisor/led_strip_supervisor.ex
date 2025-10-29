# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.LedStripSupervisor do
  @moduledoc """
  This is the supervisor for an led strip and all it's workers, like animations
  (`start_animation/3`) and coordinators (`start_coordinator/3`).
  """
  use Supervisor

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

  # MARK: client side
  @doc """
  Start a new supervisor for an led strip.
  """
  @spec start_link(atom, LedStrip.drivers_config_t(), keyword) :: Supervisor.on_start()
  def start_link(strip_name, drivers, global_configs) do
    global_configs = Keyword.put_new(global_configs, :group_leader, Process.group_leader())

    Supervisor.start_link(
      __MODULE__,
      {strip_name, drivers, global_configs},
      name: Utils.supervisor_name(strip_name)
    )
  end

  @doc """
  Stop the supervisor (and all it's children)
  """
  @spec stop(atom) :: :ok
  def stop(strip_name) do
    Supervisor.stop(Utils.supervisor_name(strip_name))
  end

  @doc """
  This starts a new animation attached to the specified led strip.

  It should be noted that it's expected that the led_strip supervisor is
  already up and running
  """
  @spec start_animation(atom, atom, Animator.config_t()) :: GenServer.on_start()
  def start_animation(strip_name, animation_name, config) do
    Utils.start_worker(strip_name, animation_name, Animator, config)
  end

  @doc """
  This checks whether a specific animation exists (for the specified led strip)
  """
  @spec animation_exists?(atom, atom) :: boolean
  def animation_exists?(strip_name, animation_name) do
    Utils.worker_exists?(strip_name, :animator, animation_name)
  end

  @doc """
  This returns a list of all the defined animations and returns their names
  """
  @spec get_animations(atom) :: list(atom)
  def get_animations(strip_name) do
    Utils.get_workers(strip_name, :animator, :"$1")
  end

  @doc """
  This stops an animation.

  It is safe to call this function even if the animation does not exist
  """
  @spec stop_animation(atom, atom) :: :ok
  def stop_animation(strip_name, animation_name) do
    Utils.stop_worker(Utils.workers_name(strip_name), strip_name, :animator, animation_name)
  end

  @doc """
  This starts a new coordinator. Which can receive events and react to those
  by impacting the running annimations.
  """
  @spec start_coordinator(atom, atom, Coordinator.config_t()) ::
          DynamicSupervisor.on_start_child()
  def start_coordinator(strip_name, coordinator_name, config) do
    Utils.start_worker(strip_name, coordinator_name, Coordinator, config)
  end

  @doc """
  This checks whether a specified coordinator exists
  """
  @spec coordinator_exists?(atom, atom) :: boolean
  def coordinator_exists?(strip_name, coordinator_name) do
    Utils.worker_exists?(strip_name, :coordinator, coordinator_name)
  end

  @doc """
  This returns a list of all the defined coordinators
  """
  @spec get_coordinators(atom) :: list(atom)
  def get_coordinators(strip_name) do
    Utils.get_workers(strip_name, :coordinator, :"$1")
  end

  @doc """
  This stops a coordinator.

  It is safe to call this function even if the coordinator does not exist
  """
  @spec stop_coordinator(atom, atom) :: :ok
  def stop_coordinator(strip_name, coordinator_name) do
    Utils.stop_worker(Utils.workers_name(strip_name), strip_name, :coordinator, coordinator_name)
  end

  # MARK: Server side
  @impl true
  @doc false
  @spec init({atom, LedStrip.drivers_config_t(), keyword}) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init({strip_name, _drivers, _global_config} = init_args) do
    Logger.debug("Starting LedStrip #{strip_name}")

    children = [
      {LedStrip, init_args},
      {DynamicSupervisor, name: Utils.workers_name(strip_name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
