# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Animation.JobSchedulerTest do
  use ExUnit.Case
  import Crontab.CronExpression

  alias Fledex.Animation.JobScheduler

  describe "job creation" do
    test "full job specs" do
      job =
        JobScheduler.create_job(
          :the_job,
          %{
            pattern: ~e[* * * * * * *]e,
            func: fn -> :ok end,
            options: [
              timezone: :utc,
              overlap: false
            ]
          },
          :strip_name
        )

      assert %Quantum.Job{
               run_strategy: %Quantum.RunStrategy.Random{nodes: :cluster},
               overlap: false,
               timezone: :utc,
               name: :the_job,
               schedule: schedule,
               task: _func,
               state: :active
             } = job

      assert %Crontab.CronExpression{
               extended: true,
               second: [:*],
               minute: [:*],
               hour: [:*],
               day: [:*],
               month: [:*],
               weekday: [:*],
               year: [:*]
             } = schedule
    end
  end
end
