# Copyright 2025, Matthias Reik <fledex@reik.org>
# Modified version of : https://github.com/SchedEx/SchedEx
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT
defmodule Fledex.Scheduler.SchedEx.Runner do
  @moduledoc false

  use GenServer

  alias Fledex.Scheduler.SchedEx.IdentityTimeScale
  alias Fledex.Scheduler.SchedEx.Stats
  alias Fledex.Supervisor.Utils

  @type executor_opts :: keyword
  @type t :: %{
          job: Job.t() | nil,
          timer_ref: reference() | nil,
          quantized_scheduled_at: DateTime.t() | nil,
          scheduled_at: DateTime.t() | nil,
          delay: pos_integer() | nil,
          stats: Stats.t(),
          opts: keyword
        }
  @doc """
  Main point of entry into this module. Starts and returns a process which will
  run the given function per the specified `job` definition
  """
  @spec run(Job.t(), executor_opts()) :: GenServer.on_start()
  def run(%Job{name: name} = job, opts) do
    GenServer.start_link(__MODULE__, {job, opts}, name: name)
  end

  # this is temporary only until we move the via_tuple out.
  @spec start_link(atom, atom, Job.t(), keyword) :: GenServer.on_start()
  def start_link(led_strip, job_name, job, server_opts \\ []) do
    server_opts = Keyword.put_new(server_opts, :name, Utils.via_tuple(led_strip, :job, job_name))
    GenServer.start_link(__MODULE__, {job, []}, server_opts)
  end

  @doc """
  This job allows to change an already existing job.

  The job is identified through it's name and that's the only part that is not
  allowed to change. The arguments are otherwise the same as for `run/2`.
  If there is nothing to schedule (or an error happens, the process will terminate)
  """
  @spec update(Job.t(), executor_opts()) :: :ok
  def update(%Job{name: name} = job, opts) do
    GenServer.call(name, {:update, job, opts})
  end

  # temporarily
  def update(strip_name, %Job{name: job_name} = job, opts) do
    server = Utils.via_tuple(strip_name, :job, job_name)
    GenServer.call(server, {:update, job, opts})
  end

  @doc """
  This function allows to interrogate when the specified job will run the
  next time relative to the last time the job was scheduled.

  The response is a tuple with the `scheduled date/time`, the `quantized
  scheduled date/time`, and the `delay` (in milliseconds) until the next run.
  """
  @spec next_schedule(Job.t()) :: {DateTime.t(), DateTime.t(), pos_integer}
  def next_schedule(%Job{name: name} = _job) do
    GenServer.call(name, :next_schedule)
  end

  def next_schedule(name) do
    GenServer.call(name, :next_schedule)
  end

  @doc """
  Returns stats for the given process.
  """
  @spec stats(GenServer.server()) :: Stats.t()
  def stats(name) do
    GenServer.call(name, :stats)
  end

  @doc """
  Cancels future invocation of the given process. If it has already been invoked, does nothing.
  """
  @spec cancel(GenServer.server()) :: :ok
  def cancel(name) do
    :shutdown = GenServer.call(name, :shutdown)
    :ok
  end

  # MARK: Server API
  @impl GenServer
  @spec init({Job.t(), keyword}) :: {:ok, t(), {:continue, {DateTime.t(), keyword}}}
  def init({%Job{} = job, opts}) do
    Process.flag(:trap_exit, true)

    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())

    {
      :ok,
      %{
        job: job,
        timer_ref: nil,
        quantized_scheduled_at: start_time,
        scheduled_at: start_time,
        delay: nil,
        stats: %Stats{},
        opts: opts
      },
      {:continue, {}}
    }
  end

  @spec to_job(Job.task(), Job.schedule() | pos_integer(), keyword) :: Job.t()
  def to_job(func, spec, job_opts) do
    spec =
      case spec do
        milliseconds when is_integer(milliseconds) -> {milliseconds, :ms}
        {_value, _unit} = delay -> delay
        %Crontab.CronExpression{} = crontab -> crontab
      end
    repeat =
      # we need to ensure that we run our scheduler at least
      # once, therefore we translate it to the integer version
      # except if we always want to run it
      case Keyword.get(job_opts, :repeat) do
        nil -> 1
        false -> 1
        true -> true
        other when is_integer(other) -> other
        _ -> raise "repeat is neither a boolean nor a positive integer"
      end
    %Job{
      name: Keyword.get(job_opts, :name, :default_name),
      func: func,
      schedule: spec,
      opts: [
        timezone: Keyword.get(job_opts, :timezone, "Etc/UTC"),
        overlap: Keyword.get(job_opts, :overlap, false),
        run_once: Keyword.get(job_opts, :run_once, false),
        repeat: repeat
      ],
      context: Keyword.get(job_opts, :context, %{})
    }
  end

  @impl GenServer
  @spec handle_continue({DateTime.t(), keyword}, t()) ::
          {:no_reply, t()} | {:stop, :normal, t()}
  def handle_continue({}, %{job: job} = state) do
    state
    |> run_func_if_necessary(Keyword.get(job.opts, :run_once, false))
    |> prepare_for_next_iteration()
  end

  @impl GenServer
  def handle_call(
        :next_schedule,
        _from,
        %{
          scheduled_at: scheduled_at,
          quantized_scheduled_at: quantized_next_time,
          delay: delay
        } = state
      ) do
    {:reply, {scheduled_at, quantized_next_time, delay}, state}
  end

  def handle_call(:stats, _from, %{stats: stats} = state) do
    {:reply, stats, state}
  end

  def handle_call(
        {:update, %Job{} = job, opts},
        _from,
        %{
          timer_ref: timer_ref,
        } = state
      ) do
    _ignore = Process.cancel_timer(timer_ref)

    start_time = Keyword.get(opts, :start_time, DateTime.utc_now())
    state = %{state |
        job: job,
        timer_ref: nil,
        scheduled_at: start_time,
        quantized_scheduled_at: start_time,
        delay: nil,
        opts: opts
    }

    result = state
    |> run_func_if_necessary(Keyword.get(job.opts, :run_once, false))
    |> prepare_for_next_iteration()

    # IO.puts("result: #{inspect result}")

    case result do
      {:noreply, state} -> {:reply, :ok, state}
      {:stop, :normal, state} -> {:reply, :shutdown, state}
    end

    # IO.puts("handle_call...")
    # new_state =
    # {:reply, :ok, new_state}
  end

  def handle_call(:shutdown, _from, state) do
    {:stop, :normal, :shutdown, state}
  end

  @impl GenServer
  def handle_info(:run, state) do
    state
    |> run_func_if_necessary(true)
    |> prepare_for_next_iteration()
  end

  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  @spec run_func(DateTime.t(), Job.task()) :: :ok
  defp run_func(this_time, func) do
    if is_function(func, 1) do
      func.(this_time)
    else
      func.()
    end

    :ok
  end

  @spec schedule_next(DateTime.t(), Job.t(), keyword) ::
          {DateTime.t(), DateTime.t(), pos_integer(), reference()} | :error
  defp schedule_next(%DateTime{} = from, job, opts) do
    case get_next_and_delay(from, job, opts) do
      :error ->
        :error

      {next_time, next_delay} ->
        # IO.puts("scheduling next: #{inspect {next_time, next_delay}}")
        timer_ref = Process.send_after(self(), :run, next_delay)

        {
          next_time,
          DateTime.shift(DateTime.utc_now(), microsecond: {next_delay * 1000, 6}),
          next_delay,
          timer_ref
        }
    end
  end

  @spec get_next_and_delay(DateTime.t(), Job.t(), keyword) ::
          {DateTime.t(), pos_integer()} | :error
  defp get_next_and_delay(from, %Job{schedule: milliseconds} = job, opts)
       when is_integer(milliseconds) do
    get_next_and_delay(from, %{job | schedule: {milliseconds, :milliseconds}}, opts)
  end

  defp get_next_and_delay(from, %Job{schedule: {value, unit}} = _job, opts) do
    time_scale = Keyword.get(opts, :time_scale, IdentityTimeScale)

    delay = to_millis(value, unit)
    delay = round(delay / time_scale.speedup())

    next = DateTime.shift(from, microsecond: {delay * 1000, 6})
    new_delay = max(DateTime.diff(next, from, :millisecond), 0)

    {next, new_delay}
  end

  defp get_next_and_delay(
         %DateTime{} = _from,
         %Job{
           schedule: crontab,
           opts: job_opts
         } = job,
         opts
       ) do
    time_scale = Keyword.get(opts, :time_scale, IdentityTimeScale)
    timezone = Keyword.get(job_opts, :timezone, "Etc/UTC")
    from = time_scale.now(timezone)

    naive_from = from |> DateTime.to_naive()

    case Crontab.Scheduler.get_next_run_date(crontab, naive_from) do
      {:ok, naive_next} ->
        next = convert_naive_to_timezone(naive_next, job, timezone, opts)
        delay = max(DateTime.diff(next, from, :millisecond), 0)
        delay = round(delay / time_scale.speedup())
        {next, delay}

      {:error, _msg} ->
        :error
    end
  end

  defp to_millis(value, :milliseconds), do: value
  defp to_millis(value, :ms), do: value

  defp to_millis(value, :seconds), do: to_millis(value, :s)
  defp to_millis(value, :sec), do: to_millis(value, :s)
  defp to_millis(value, :s), do: to_millis(value, :ms) * 1000

  defp to_millis(value, :minutes), do: to_millis(value, :m)
  defp to_millis(value, :min), do: to_millis(value, :m)
  defp to_millis(value, :m), do: to_millis(value, :s) * 60

  defp to_millis(value, :hours), do: to_millis(value, :h)
  defp to_millis(value, :h), do: to_millis(value, :m) * 60

  defp to_millis(value, :days), do: to_millis(value, :d)
  defp to_millis(value, :d), do: to_millis(value, :h) * 24

  defp to_millis(value, :weeks), do: to_millis(value, :w)
  defp to_millis(value, :w), do: to_millis(value, :d) * 7

  defp convert_naive_to_timezone(naive_next, job, timezone, opts) do
    next = DateTime.from_naive(naive_next, timezone)

    case next do
      {:gap, _just_before, just_after} ->
        case Keyword.get(opts, :nonexistent_time_strategy, :skip) do
          :skip ->
            {next, _delay} = get_next_and_delay(just_after, job, opts)
            next

          :adjust ->
            adjust_non_existent_time(naive_next, timezone)
        end

      {:ambiguous, _first_dt, second_dt} ->
        second_dt

      {:ok, dt} ->
        dt
    end
  end

  defp adjust_non_existent_time(
         %NaiveDateTime{} = naive_date,
         timezone
       ) do
    # Assume that midnight of the non-existent day is in a valid period
    naive_start_of_day = NaiveDateTime.beginning_of_day(naive_date)
    difference_from_midnight = NaiveDateTime.diff(naive_date, naive_start_of_day)

    naive_start_of_day
    |> DateTime.from_naive!(timezone)
    |> DateTime.shift(second: difference_from_midnight)
  end

  defp run_func_if_necessary(state, false), do: state
  defp run_func_if_necessary(%{
    job: job,
    scheduled_at: this_time,
    quantized_scheduled_at: quantized_this_time,
    stats: stats
  } = state, true) do
    start_time = DateTime.utc_now()
    run_func(this_time, job.func)
    end_time = DateTime.utc_now()

    stats = Stats.update(stats, this_time, quantized_this_time, start_time, end_time)
    %{state | stats: stats}
  end
  defp prepare_for_next_iteration(%{
    job: job,
    opts: opts,
    scheduled_at: start_time
    } = state) do
    # IO.puts("prepare_for_next_iteration: #{inspect state}")
    repeat = Keyword.get(job.opts, :repeat, false)
    # IO.puts("repeat: #{inspect repeat}")

    if is_integer(repeat) and repeat > 0 || is_boolean(repeat) and repeat do
      state = %{state | job: %{
        job |
        opts: Keyword.update(job.opts, :repeat, false, fn
          old when is_integer(old) and old > 0 -> old - 1
          old -> old
        end)}
      }

      case schedule_next(start_time, job, opts) do
        :error ->
          # IO.puts("stopping...")
          # adjusting to do the same as the normal operation (see handle_info)
          # add the job and opts to the state to support debugging.
          {:stop, :normal, state}

        # :ignore

        {next_time, quantized_next_time, next_delay, timer_ref} ->
          # stats = %Stats{}

          {:noreply,
          %{
            state
            | timer_ref: timer_ref,
            quantized_scheduled_at: quantized_next_time,
            scheduled_at: next_time,
            delay: next_delay,
            opts: opts
          }}
      end
    else
      {:stop, :normal, state}
    end
  end
end
