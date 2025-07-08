# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.Utils do
  @pubsub :fledex
  @app_supervisor Fledex.DynamicSupervisor
  @registry Fledex.Supervisor.WorkersRegistry
  @supervisor Fledex.Supervisor.WorkersSupervisor

  def pubsub_name, do: @pubsub
  def app_supervisor, do: @app_supervisor
  def worker_registry, do: @registry
  def worker_supervisor, do: @supervisor
end
