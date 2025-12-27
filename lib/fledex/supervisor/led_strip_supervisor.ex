# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.LedStripSupervisor do
  @moduledoc """
  This is the supervisor for an led strip and all it's workers, like `:animator`s, `:coordinator`s, and `:job`s

  You should start, stop, and interact with the workers through this module.
  """

  use Supervisor

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

  @mapping %{
    animator: Animator,
    coordinator: Coordinator,
    job: JobScheduler
  }

  @doc false
  @spec supervisor_name(atom) :: GenServer.name()
  def supervisor_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :supervisor)
  end

  @doc false
  @spec strip_workers_name(atom) :: GenServer.name()
  def strip_workers_name(strip_name) do
    Utils.via_tuple(strip_name, :led_strip, :workers)
  end

  # MARK: client side
  @doc """
  Start a new supervisor for an led strip.
  """
  @spec start_link(atom, LedStrip.drivers_config_t(), keyword, keyword) :: Supervisor.on_start()
  def start_link(strip_name, drivers, global_configs, opts) do
    global_configs =
      global_configs
      |> Keyword.put_new(:group_leader, Process.group_leader())

    Supervisor.start_link(
      __MODULE__,
      {strip_name, drivers, global_configs, opts},
      name: supervisor_name(strip_name)
    )
  end

  @doc """
  Stop the supervisor (and all it's children)
  """
  @spec stop(atom) :: :ok
  def stop(strip_name) do
    supervisor_name(strip_name)
    |> Supervisor.stop()
  end

  @doc """
  This starts a new worker.

  Differnet types of workers exist (`:animator`, `:coordinator`, and `:job`) and the configuration needs to fit to the
  type of worker.
  """
  @spec start_worker(
          atom,
          Utils.led_strip_worker_types(),
          atom,
          Utils.led_strip_worker_configs(),
          keyword
        ) :: DynamicSupervisor.on_start_child()
  def start_worker(strip_name, type, worker_name, config, server_opts \\ []) do
    server_opts =
      Keyword.put_new(server_opts, :name, Utils.via_tuple(strip_name, type, worker_name))

    DynamicSupervisor.start_child(
      strip_workers_name(strip_name),
      %{
        # no need to be unique
        id: worker_name,
        start: {@mapping[type], :start_link, [strip_name, worker_name, config, server_opts]},
        restart: :transient
      }
    )
  end

  @doc """
  This checks whether a specified worker exists
  """
  @spec worker_exists?(atom, Utils.led_strip_worker_types(), atom) :: boolean
  def worker_exists?(strip_name, type, worker_name) do
    Utils.worker_exists?(strip_name, type, worker_name)
  end

  @doc """
  This returns a list of all the defined workers of a specified type (`:animator`, `:coordinator`, or `"job`)
  """
  @spec get_workers(atom, Utils.led_strip_worker_types()) :: list(atom)
  def get_workers(strip_name, type) do
    Utils.get_workers(strip_name, type, :"$1")
  end

  @doc """
  This reconfigures a job
  """
  @spec reconfigure_worker(
          atom,
          Utils.led_strip_worker_types(),
          atom,
          Utils.led_strip_worker_configs()
        ) :: :ok
  def reconfigure_worker(strip_name, type, worker_name, config) do
    server = Utils.via_tuple(strip_name, type, worker_name)
    @mapping[type].change_config(server, config)
    :ok
  end

  @doc """
  This stops a worker.

  It is safe to call this function even if the worker does not exist
  """
  @spec stop_worker(atom, Utils.led_strip_worker_types(), atom) :: :ok
  def stop_worker(strip_name, type, worker_name) do
    supervisor = strip_workers_name(strip_name)

    case Utils.get_worker(strip_name, type, worker_name) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(supervisor, pid)
    end

    :ok
  end

  # MARK: Server side
  @impl Supervisor
  @doc false
  @spec init({atom, LedStrip.drivers_config_t(), keyword, keyword}) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init({strip_name, drivers, global_config, server_opts}) do
    Logger.debug("Starting LedStrip #{strip_name}")

    server_opts =
      Keyword.put_new(server_opts, :name, Utils.via_tuple(strip_name, :led_strip, :strip))

    children = [
      {LedStrip, {strip_name, drivers, global_config, server_opts}},
      {DynamicSupervisor, name: strip_workers_name(strip_name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
