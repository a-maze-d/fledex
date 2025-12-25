# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Animation.JobSchedulerTest do
  use ExUnit.Case, async: true
  import Crontab.CronExpression

  alias Fledex.Animation.JobScheduler

  describe "job creation" do
    test "full job specs" do
      job =
        JobScheduler.create_job(
          :strip_name,
          :the_job,
          %{
            pattern: ~e[* * * * * * *]e,
            func: fn -> :ok end,
            options: [
              timezone: :utc,
              overlap: false
            ]
          }
        )

      assert %Fledex.Scheduler.Job{
        func: _func,
        schedule: schedule,
        context: %{},
        opts: [
          run_once: false,
          repeat: true,
          overlap: false,
          timezone: "Etc/UTC"
        ]
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
