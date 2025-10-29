# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.Utils do
  @moduledoc """
  Some utilities related to the animatino system.
  """

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator

  @pubsub Mix.Project.config()[:app]
  @app_supervisor Fledex.DynamicSupervisor
  @registry Fledex.Supervisor.WorkersRegistry
  @supervisor Fledex.Supervisor.WorkersSupervisor

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
  @spec workers_supervisor() :: module
  def workers_supervisor, do: @supervisor

  @doc """
  used to register the workers with the registry
  """
  @spec via_tuple(atom, :animator | :job | :coordinator | :led_strip, atom) :: GenServer.name()
  def via_tuple(strip_name, type, animation_name),
    do: {:via, Registry, {@registry, {strip_name, type, animation_name}}}

  @spec supervisor_name(atom) :: GenServer.name()
  def supervisor_name(strip_name) do
    via_tuple(strip_name, :led_strip, :supervisor)
  end

  @spec workers_name(atom) :: GenServer.name()
  def workers_name(strip_name) do
    via_tuple(strip_name, :led_strip, :workers)
  end

  @spec start_worker(
          atom,
          atom,
          Animator | Coordinator,
          Animator.config_t() | Coordinator.config_t()
        ) :: DynamicSupervisor.on_start_child()
  def start_worker(strip_name, name, type, config) do
    DynamicSupervisor.start_child(
      workers_name(strip_name),
      %{
        # no need to be unique
        id: name,
        start: {type, :start_link, [strip_name, name, config]},
        restart: :transient
      }
    )
  end

  @spec worker_exists?(atom, :coordinator | :animator | :led_strip, atom) :: boolean
  def worker_exists?(strip_name, type, name) do
    case Registry.lookup(worker_registry(), {strip_name, type, name}) do
      [{_pid, _value}] -> true
      _other -> false
    end
  end

  @spec get_workers(atom, :coordinator | :animator | :led_strip, atom) :: list(atom)
  def get_workers(strip_name, type, name) do
    Registry.select(worker_registry(), [
      {
        {{strip_name, type, name}, :_, :_},
        [],
        [:"$1"]
      }
    ])
  end

  @spec stop_worker(GenServer.name(), atom, :coordinator | :animator | :led_strip, atom) :: :ok
  def stop_worker(supervisor, strip_name, type, name) do
    case Registry.lookup(worker_registry(), {strip_name, type, name}) do
      [{pid, _value}] -> DynamicSupervisor.terminate_child(supervisor, pid)
      _other -> :ok
    end

    :ok
  end
end
