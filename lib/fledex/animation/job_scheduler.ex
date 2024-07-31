# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
# MARK: Quantum
defmodule Fledex.Animation.JobScheduler do
  @callback start_link() ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}
  @callback stop() :: :ok
  @callback new_job() :: Quantum.Job.t()
  @callback add_job(Quantum.Job.t() | {Crontab.CronExpression.t(), Quantum.Job.task()}) ::
              :ok
  @callback run_job(atom) :: :ok
  @callback delete_job(atom) :: :ok

  use Quantum, otp_app: __MODULE__

  @impl true
  def config(opts \\ []) do
    Quantum.scheduler_config(opts, __MODULE__, __MODULE__)
    |> Keyword.put(:debug_logging, false)
  end
end
