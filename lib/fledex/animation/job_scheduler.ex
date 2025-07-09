# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
# MARK: Quantum
defmodule Fledex.Animation.JobScheduler do
  use Quantum, otp_app: __MODULE__

  require Logger

  alias Quantum.Job

  @opaque job :: Job.t()

  @type config_t :: %{
          type: :job,
          pattern: Crontab.CronExpression.t(),
          options: keyword,
          func: (-> any)
        }

  def config(opts \\ []) do
    # the start_link function is auto-generated, so we are adding
    # the log here. It gets called just before we start the server
    # note it's on client and not server side. Also we can't observe
    # the shutdown.
    Logger.debug("starting Animation.Manager")

    Quantum.scheduler_config(opts, __MODULE__, __MODULE__)
    # |> Keyword.put(:debug_logging, false)
  end

  @spec create_job(atom, Interace.config_t(), atom) :: Interface.job()
  def create_job(job, job_config, _strip_name) do
    new_job([])
    |> Job.set_name(job)
    |> Job.set_schedule(job_config.pattern)
    |> Job.set_task(job_config.func)
    |> Job.set_timezone(Keyword.get(job_config.options, :timezone, :utc))
    |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
  end
end
