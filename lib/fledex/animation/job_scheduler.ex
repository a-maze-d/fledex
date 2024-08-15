# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
# MARK: Quantum
defmodule Fledex.Animation.JobScheduler do
  alias Quantum.Job

  @opaque job :: Job.t()
  @type config_t :: %{
          type: :job,
          pattern: Crontab.CronExpression.t(),
          options: map,
          func: (-> any)
        }

  @callback start_link() ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}
  @callback stop() :: :ok
  @callback create_job(atom, config_t, atom) :: job
  @callback add_job(job) :: :ok
  @callback run_job(atom) :: :ok
  @callback delete_job(atom) :: :ok

  use Quantum, otp_app: __MODULE__

  @impl true
  def config(opts \\ []) do
    Quantum.scheduler_config(opts, __MODULE__, __MODULE__)
    |> Keyword.put(:debug_logging, false)
  end

  @spec create_job(atom, config_t, atom) :: job
  def create_job(job, job_config, _strip_name) do
    new_job([])
    |> Job.set_name(job)
    |> Job.set_schedule(job_config.pattern)
    |> Job.set_task(job_config.func)
    |> Job.set_timezone(Keyword.get(job_config.options, :timezone, :utc))
    |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
  end
end
