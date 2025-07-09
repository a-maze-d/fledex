# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor do
  use Supervisor

  alias Fledex.Animation.JobScheduler
  alias Fledex.Animation.Manager

  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    Supervisor.stop(__MODULE__, reason, timeout)
  end

  @impl true
  def init(init_args) do
    children = [
      {Manager, init_args},
  #     # {DynamicSupervisor, strategy: :one_for_one, name: Manager.LedStrips},
  #     # {DynamicSupervisor, strategy: :one_for_one, name: Manager.Animations},
  #     # {DynamicSupervisor, strategy: :one_for_one, name: Manager.Coordinators},
      JobScheduler
    ]
      #   # impls: %{
  #   #   job_scheduler: Keyword.get(opts, :job_scheduler, JobScheduler),
  #   #   animator: Keyword.get(opts, :animator, Animator),
  #   #   led_strip: Keyword.get(opts, :led_strip, LedStrip),
  #   #   coordinator: Keyword.get(opts, :coordinator, Coordinator)
  #   # }

  # children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
