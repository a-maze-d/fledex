# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.Utils do
  @moduledoc """
  Some utilities related to the animatino system.
  """
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
end
