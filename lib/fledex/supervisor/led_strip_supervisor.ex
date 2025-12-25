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
  alias Fledex.Animation.JobScheduler2
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

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
      name: Utils.supervisor_name(strip_name)
    )
  end

  @doc """
  Stop the supervisor (and all it's children)
  """
  @spec stop(atom) :: :ok
  def stop(strip_name) do
    Utils.supervisor_name(strip_name)
    |> Supervisor.stop()
  end

  @doc """
  This starts a new animation attached to the specified led strip.

  It should be noted that it's expected that the led_strip supervisor is
  already up and running
  """
  @spec start_animation(atom, atom, Animator.config_t(), keyword) :: GenServer.on_start()
  def start_animation(strip_name, animation_name, config, opts \\ []) do
    config =
      config
      |> Map.put_new(:strip_server, Utils.via_tuple(strip_name, :led_strip, :strip))

    opts = Keyword.put_new(opts, :name, Utils.via_tuple(strip_name, :animator, animation_name))
    Utils.start_worker(strip_name, animation_name, :animator, config, opts)
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
    Utils.strip_workers_name(strip_name)
    |> Utils.stop_worker(strip_name, :animator, animation_name)
  end

  @doc """
  This starts a new job.

  This allows to run some task at a well defined time or interval
  """
  @spec start_job(atom, atom, JobScheduler2.config_t(), keyword) ::
          DynamicSupervisor.on_start_child()
  def start_job(strip_name, job_name, config, opts) do
    opts = Keyword.put_new(opts, :name, Utils.via_tuple(strip_name, :job, job_name))
    Utils.start_worker(strip_name, job_name, :job, config, opts)
    # |> dbg()
  end

  @doc """
  This checks whether a specified job exists
  """
  @spec job_exists?(atom, atom) :: boolean
  def job_exists?(strip_name, coordinator_name) do
    Utils.worker_exists?(strip_name, :job, coordinator_name)
  end

  @doc """
  This returns a list of all the defined jobs
  """
  @spec get_jobs(atom) :: list(atom)
  def get_jobs(strip_name) do
    Utils.get_workers(strip_name, :job, :"$1")
  end

  @doc """
  This stops a coordinator.

  It is safe to call this function even if the job does not exist
  """
  @spec stop_job(atom, atom) :: :ok
  def stop_job(strip_name, coordinator_name) do
    Utils.strip_workers_name(strip_name)
    |> Utils.stop_worker(strip_name, :job, coordinator_name)
  end

  @doc """
  This starts a new coordinator. Which can receive events and react to those
  by impacting the running annimations.
  """
  @spec start_coordinator(atom, atom, Coordinator.config_t(), keyword) ::
          DynamicSupervisor.on_start_child()
  def start_coordinator(strip_name, coordinator_name, config, opts \\ []) do
    opts =
      Keyword.put_new(opts, :name, Utils.via_tuple(strip_name, :coordinator, coordinator_name))

    Utils.start_worker(strip_name, coordinator_name, :coordinator, config, opts)
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
    Utils.strip_workers_name(strip_name)
    |> Utils.stop_worker(strip_name, :coordinator, coordinator_name)
  end

  # MARK: Server side
  @impl Supervisor
  @doc false
  @spec init({atom, LedStrip.drivers_config_t(), keyword}) ::
          {:ok,
           {Supervisor.sup_flags(),
            [Supervisor.child_spec() | (old_erlang_child_spec :: :supervisor.child_spec())]}}
  def init({strip_name, drivers, global_config, server_opts}) do
    Logger.debug("Starting LedStrip #{strip_name}")

    server_opts =
      Keyword.put_new(server_opts, :name, Utils.via_tuple(strip_name, :led_strip, :strip))

    children = [
      {LedStrip, {strip_name, drivers, global_config, server_opts}},
      {DynamicSupervisor, name: Utils.strip_workers_name(strip_name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
