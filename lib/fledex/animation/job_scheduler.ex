# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.JobScheduler do
  use Quantum, otp_app: __MODULE__

  require Logger

  alias Quantum.Job

  @type job :: Job.t()
  @type config_t :: %{
          type: :job,
          pattern: Crontab.CronExpression.t(),
          options: keyword,
          func: (-> any)
        }

  @spec create_job(atom, config_t(), atom) :: job()
  def create_job(job, job_config, _strip_name) do
    new_job([])
    |> Job.set_name(job)
    |> Job.set_schedule(job_config.pattern)
    |> Job.set_task(job_config.func)
    |> Job.set_timezone(Keyword.get(job_config.options, :timezone, :utc))
    |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
  end

  @impl true
  def init(opts) do
    Logger.debug("starting JobScheduler ")
    opts
  end
end
