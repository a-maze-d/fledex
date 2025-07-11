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
  def pubsub_name, do: @pubsub

  @doc """
  The name of the application Supervisor to which we can add
  dynamically supervisors. The AnimationSystem can be added to it
  """
  def app_supervisor, do: @app_supervisor

  @doc """
  The name of the registry to which the workers will be registered
  """
  def worker_registry, do: @registry

  @doc """
  The name of the supervisor that observes all the workers in the AnimationSystem
  """
  def workers_supervisor, do: @supervisor

  @spec via_tuple(atom, :animator | :job | :coordinator | :led_strip, atom) :: GenServer.name()
  def via_tuple(strip_name, type, animation_name),
    do: {:via, Registry, {@registry, {strip_name, type, animation_name}}}
end
