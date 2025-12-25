# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.Utils do
  @moduledoc """
  Some utilities related to the animation system.
  """

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler

  @pubsub Mix.Project.config()[:app]
  @app_supervisor Fledex.DynamicSupervisor
  @registry Fledex.Supervisor.WorkersRegistry
  @strip_supervisors Fledex.Supervisor.Strips

  @type worker_types :: led_strip_worker_types | :led_strip
  @type led_strip_worker_types :: :animator | :coordinator | :job

  @doc """
  Defines the name of the pubsub system that is used by Fledex
  """
  @spec pubsub_name() :: atom
  def pubsub_name, do: @pubsub

  @doc """
  The name of the application Supervisor to which we can add
  dynamically supervisors. The AnimationSystem can be added to it
  """
  @spec app_supervisor() :: module
  def app_supervisor, do: @app_supervisor

  @doc """
  The name of the registry to which the workers will be registered
  """
  @spec worker_registry() :: module
  def worker_registry, do: @registry

  @doc """
  The name of the supervisor that observes all the workers in the AnimationSystem
  """
  @spec strip_supervisors() :: module
  def strip_supervisors, do: @strip_supervisors

  @doc """
  used to register the workers with the registry
  """
  @spec via_tuple(atom, worker_types(), atom) :: GenServer.name()
  def via_tuple(strip_name, type, animation_name),
    do: {:via, Registry, {@registry, {strip_name, type, animation_name}}}

  @spec supervisor_name(atom) :: GenServer.name()
  def supervisor_name(strip_name) do
    via_tuple(strip_name, :led_strip, :supervisor)
  end

  @spec strip_workers_name(atom) :: GenServer.name()
  def strip_workers_name(strip_name) do
    via_tuple(strip_name, :led_strip, :workers)
  end

  @mapping %{
    animator: Animator,
    coordinator: Coordinator,
    job: JobScheduler
  }
  @spec start_worker(
          atom,
          atom,
          led_strip_worker_types(),
          Animator.config_t() | Coordinator.config_t() | JobScheduler.config_t(),
          keyword
        ) :: DynamicSupervisor.on_start_child()
  def start_worker(strip_name, name, type, config, opts) do
    DynamicSupervisor.start_child(
      strip_workers_name(strip_name),
      %{
        # no need to be unique
        id: name,
        start: {@mapping[type], :start_link, [strip_name, name, config, opts]},
        restart: :transient
      }
    )
    # |> dbg()
  end

  @spec get_worker(atom, worker_types(), atom) :: pid()
  def get_worker(strip_name, type, name) do
    case Registry.lookup(worker_registry(), {strip_name, type, name}) do
      [{pid, _value}] ->
        pid

      other ->
        Logger.warning(
          "Looking for worker #{inspect({strip_name, type, name})}, but got: #{inspect(other)}"
        )

        nil
    end
  end

  @spec worker_exists?(atom, worker_types(), atom) :: boolean
  def worker_exists?(strip_name, type, name) do
    case Registry.lookup(worker_registry(), {strip_name, type, name}) do
      [{_pid, _value}] -> true
      _other -> false
    end
  end

  @spec get_workers(atom, worker_types(), atom) :: list(atom)
  def get_workers(strip_name, type, name) do
    Registry.select(worker_registry(), [
      {
        {{strip_name, type, name}, :_, :_},
        [],
        [:"$1"]
      }
    ])
  end

  @spec stop_worker(GenServer.name(), atom, worker_types(), atom) :: :ok
  def stop_worker(supervisor, strip_name, type, name) do
    case get_worker(strip_name, type, name) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(supervisor, pid)
    end

    :ok
  end
end
