# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Scheduler.SchedEx.Job do
  @moduledoc """
  A job that determines the behaviour of scheduler. Instead of calling
  `Fledex.Scheduler.SchedEx.run_at/2`, `Fledex.Scheduler.SchedEx.run_in/2`, and `Fledex.Scheduler.SchedEx.run_every` you
  can specify your job and use `Fledex.Scheduler.SchedEx.run_job/2`
  """

  alias __MODULE__
  alias Crontab.CronExpression

  # This is what we have in fledex:
  # def create_job(job, job_config, _strip_name) do
  #   new_job([])
  #   |> Job.set_name(job)
  #   |> Job.set_schedule(job_config.pattern)
  #   |> Job.set_task(job_config.func)
  #   |> Job.set_timezone(Keyword.get(job_config.options, :timezone, :utc))
  #   |> Job.set_overlap(Keyword.get(job_config.options, :overlap, false))
  # end
  @type unit ::
          :milliseconds
          | :ms
          | :seconds
          | :sec
          | :s
          | :minutes
          | :min
          | :m
          | :hours
          | :h
          | :weeks
          | :w

  @type task :: (-> any) | (DateTime.t() -> any)
  @type schedule :: CronExpression.t() | {pos_integer(), unit()}

  defstruct name: nil, func: nil, schedule: nil, context: %{}, opts: []

  @type t :: %__MODULE__{
          name: GenServer.name() | nil,
          func: task() | nil,
          schedule: schedule() | nil,
          context: map,
          opts: keyword
        }

  @spec new(GenServer.name(), task(), CronExpression.t() | {pos_integer, unit()}, map, keyword) ::
          __MODULE__.t()
  def new(name, func, schedule, context, opts) do
    %__MODULE__{name: name, func: func, schedule: schedule, context: context, opts: opts}
  end

  @spec new :: t()
  def new, do: %__MODULE__{}
  @spec set_name(t(), GenServer.name()) :: t()
  def set_name(%Job{} = job, name), do: %{job | name: name}
  @spec set_task(t(), task()) :: t()
  def set_task(%Job{} = job, func), do: %{job | func: func}
  @spec set_schedule(t(), CronExpression.t()) :: t()
  def set_schedule(%Job{} = job, schedule), do: %{job | schedule: schedule}

  # coveralls-ignore-start
  @doc deprecation:
         "Use `Etc/UTC` instead of `:utc` as timezone. This is for compatibility with Quantum only"
  @spec set_timezone(__MODULE__.t(), :utc | String.t()) :: __MODULE__.t()
  def set_timezone(job, :utc), do: set_timezone(job, "Etc/UTC")
  # coveralls-ignore-stop
  def set_timezone(%Job{opts: opts} = job, timezone),
    do: %{job | opts: Keyword.put(opts, :timezone, timezone)}

  @spec set_overlap(__MODULE__.t(), boolean) :: __MODULE__.t()
  def set_overlap(%Job{opts: opts} = job, overlap),
    do: %{job | opts: Keyword.put(opts, :overlap, overlap)}

  @spec set_repeat(__MODULE__.t(), boolean) :: __MODULE__.t()
  def set_repeat(%Job{opts: opts} = job, repeat),
    do: %{job | opts: Keyword.put(opts, :repeat, repeat)}

  @spec set_run_once(__MODULE__.t(), boolean) :: __MODULE__.t()
  def set_run_once(%Job{opts: opts} = job, run_once),
    do: %{job | opts: Keyword.put(opts, :run_once, run_once)}

  @spec set_context(__MODULE__.t(), map) :: __MODULE__.t()
  def set_context(%Job{} = job, context), do: %{job | context: context}

  # def dummy() do
  #   Job.new()
  #   |> Job.set_name(:test)
  #   |> Job.set_task(fn -> :ok end)
  #   |> Job.set_schedule({1000, :ms})
  #   |> Job.set_timezone("Etc/UTC")
  #   |> Job.set_overlap(true)
  #   |> Job.set_context(%{strip_name: :john, job: :repeater})
  # end

  # def dummy2() do
  #   import Crontab.CronExpression

  #   Job.new()
  #   |> Job.set_name(:test)
  #   |> Job.set_task(fn -> IO.puts(".") end)
  #   |> Job.set_schedule(~e[* * * * * * *]e)
  #   |> Job.set_timezone("Etc/UTC")
  #   |> Job.set_overlap(true)
  #   |> Job.set_context(%{strip_name: :john, job: :repeater})
  # end
end
