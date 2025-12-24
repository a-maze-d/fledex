# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.JobScheduler2 do
  @moduledoc """
  > #### Note {: .info}
  >
  > You probably do not want to use this module directly but use the DSL defined
  > in `Fledex`

  A job scheduler
  """

  alias Fledex.Scheduler.Job

  @type job :: Job.t()
  @typedoc """
  The configuration of a job.

  * `:type`: This must be `:job`
  * `:pattern`: This is the crontab pattern describing when to trigger the job
  * `:options`: Some options to finetune the job
  ** `:timezone`: default `UTC`
  ** `:overlap`: whether jobs are allowed to overlap (if execution is longer than the interval between runs)
  * `:func`: The function that will be executed when the job runs.
  """
  @type config_t :: %{
          type: :job,
          pattern: Crontab.CronExpression.t(),
          options: keyword,
          func: (-> any)
        }

  @doc """
  creates a new job

  **Note:** The job name is NOT unique across led strips. It's your
  responsibility to avoid interferences (the strip_name is currently
  not used, but this might change in the future)
  """
  @spec create_job(atom, config_t(), atom) :: job()
  def create_job(job, job_config, strip_name) do
    Job.new()
    |> Job.set_name(job)
    |> Job.set_task(job_config.func)
    |> Job.set_schedule(job_config.pattern)
    |> Job.set_timezone(Keyword.get(job_config.options, :timezone, "Etc/UTC"))
    |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
    |> Job.set_repeat(Keyword.get(job_config.options, :repeat, true))
    |> Job.set_run_once(Keyword.get(job_config.options, :run_once, false))
    |> Job.set_context(%{strip_name: strip_name, job: job})
  end
end
