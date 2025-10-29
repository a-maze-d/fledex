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
      name: supervisor_name(strip_name)
    )
  end

  @doc """
  Stop the supervisor (and all it's children)
  """
  @spec stop(atom) :: :ok
  def stop(strip_name) do
    Supervisor.stop(supervisor_name(strip_name))
  end

  @doc """
  This starts a new animation attached to the specified led strip.

  It should be noted that it's expected that the led_strip supervisor is
  already up and running
  """
  @spec start_animation(atom, atom, Animator.config_t()) :: GenServer.on_start()
  def start_animation(strip_name, animation_name, config) do
    DynamicSupervisor.start_child(
      workers_name(strip_name),
      %{
        # no need to be unique
        id: animation_name,
        start: {Animator, :start_link, [strip_name, animation_name, config]},
        restart: :transient
      }
    )
  end

  @spec animation_exists?(atom, atom) :: boolean
  def animation_exists?(strip_name, animation_name) do
    case Registry.lookup(Utils.worker_registry(), {strip_name, :animator, animation_name}) do
      [{_pid, _value}] -> true
      _other -> false
    end
  end

  @spec get_animations(atom) :: list(atom)
  def get_animations(strip_name) do
    Registry.select(Utils.worker_registry(), [
      {
        {{strip_name, :animator, :"$1"}, :_, :_},
        [],
        [:"$1"]
      }
    ])
  end

  @spec stop_animation(atom, atom) :: :ok
  def stop_animation(strip_name, animation_name) do
    case Registry.lookup(Utils.worker_registry(), {strip_name, :animator, animation_name}) do
      [{pid, _value}] -> DynamicSupervisor.terminate_child(workers_name(strip_name), pid)
      _other -> :ok
    end

    :ok
  end

  @doc """
  This starts a new coordinator. Which can receive events and react to those
  by impacting the running annimations.
  """
  @spec start_coordinator(atom, atom, Coordinator.config_t()) :: GenServer.on_start()
  def start_coordinator(strip_name, coordinator_name, config) do
    DynamicSupervisor.start_child(
      workers_name(strip_name),
      %{
        # no need to be unique
        id: coordinator_name,
        start: {Coordinator, :start_link, [strip_name, coordinator_name, config]},
        restart: :transient
      }
    )
  end

  # MARK: Server side
  @impl true
  @spec init({atom, LedStrip.drivers_config_t(), keyword}) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init({strip_name, _drivers, _global_config} = init_args) do
    Logger.debug("Starting LedStrip #{strip_name}")

    children = [
      {LedStrip, init_args},
      {DynamicSupervisor, name: workers_name(strip_name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # MARK: public helper functions
  @spec supervisor_name(atom) :: GenServer.name()
  def supervisor_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :supervisor)
  end

  @spec workers_name(atom) :: GenServer.name()
  def workers_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :workers)
  end
end
