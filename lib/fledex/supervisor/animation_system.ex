# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.AnimationSystem do
  use Supervisor

  require Logger

  alias Fledex.Animation.JobScheduler
  alias Fledex.Animation.Manager
  alias Fledex.Supervisor.Utils

  def child_spec(init_args \\ []) do
    %{
      id: Fledex.Supervisor.AnimationSystem,
      start: {Fledex.Supervisor.AnimationSystem, :start_link, init_args}
    }
  end

  def start_link(init_args \\ []) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    Supervisor.stop(__MODULE__, reason, timeout)
  end

  @impl true
  @spec init(keyword) ::
      {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec() | :supervisor.child_spec()]}} | :ignore
  def init(init_args) do
    Logger.debug("starting AnimationSystem")

    children = [
      {Registry, keys: :unique, name: Utils.worker_registry()},
      {DynamicSupervisor, strategy: :one_for_one, name: Utils.worker_supervisor()},
      {Phoenix.PubSub, adapter_name: :pg2, name: Utils.pubsub_name()},
      JobScheduler,
      {Manager, init_args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
