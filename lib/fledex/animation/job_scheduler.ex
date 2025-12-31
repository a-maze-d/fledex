# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.JobScheduler do
  @moduledoc """
  This module is a small wrapper around hte Fledex.Scheduler library and adds
  Fledex specific aspsects into the scheduler.

  > #### Note {: .info}
  >
  > You probably do not want to use this module directly but use the DSL defined
  > in `Fledex`

  A job scheduler
  """

  alias Fledex.Scheduler.Job
  alias Fledex.Scheduler.Runner
  alias Fledex.Supervisor.Utils

  @type job :: Job.t()
  @typedoc """
  The configuration of a job.

  * `:type`: This must be `:job`
  * `:schedule`: This is the crontab pattern or interval describing when to trigger the job
  * `:options`: Some options to finetune the job
  ** `:timezone`: default `UTC`
  ** `:overlap`: whether jobs are allowed to overlap (if execution is longer than the interval between runs)
  * `:func`: The function that will be executed when the job runs.
  """
  @type config_t :: %{
          type: :job,
          schedule: Job.schedule(),
          options: keyword,
          func: (-> any)
        }

  @doc """
  converts a config to a job
  """
  @spec to_job(atom, atom, config_t()) :: job()
  def to_job(strip_name, job_name, job_config) do
    Job.new()
    |> Job.set_name(job_name)
    |> Job.set_task(job_config.func)
    |> Job.set_schedule(job_config.schedule)
    |> Job.set_timezone(Keyword.get(job_config.options, :timezone, "Etc/UTC"))
    |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
    |> Job.set_repeat(Keyword.get(job_config.options, :repeat, true))
    |> Job.set_run_once(Keyword.get(job_config.options, :run_once, false))
    |> Job.set_context(%{strip_name: strip_name, job: job_name})
  end

  @doc """
  starts a new JobScheduler with the given `strip_name` and `job_name`
  """
  @spec start_link(atom, atom, job(), keyword) :: GenServer.on_start()
  def start_link(strip_name, job_name, job, server_opts) do
    # IO.puts("Starting job: #{inspect {strip_name, job_name, config, server_opts}}")
    server_opts = Keyword.put_new(server_opts, :name, Utils.via_tuple(strip_name, :job, job_name))
    Runner.start_link(job, [], server_opts)
  end

  @doc """
  Changes the scheduling configuration of an already existing `JobScheduler`
  """
  @spec change_config(GenServer.server(), job()) :: :ok
  def change_config(server, job) do
    Runner.change_config(server, job, [])
    :ok
  end
end
