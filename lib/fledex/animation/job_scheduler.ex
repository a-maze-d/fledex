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
  @callback add_job(Quantum.Job.t() | {Crontab.CronExpression.t(), Job.task()}) ::
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

# I was thinking of removing the dependency on Quantum
# and have a higher than second precision, but I don't
# think I will need that precision and it's probably
# easier to keep it. I'm leaving the code in for now.
# NOTE: The code is not finished, but almost
# defmodule Fledex.Animation.JobScheduler do
#   alias Fledex.Animation.Job
#   alias Fledex.Animation.Job
#   use GenServer
#   # MARK: Utils
#   defmodule Utils do
#     def now_millis do
#       DateTime.utc_now() |> DateTime.to_unix(:millisecond)
#     end
#     def calculate_next_run(last_run, schedule) do
#       case schedule do
#         <<"@every_", amount::binary>> -> trunc(last_run + calc_amount(amount))
#         <<"@on_the_", timing::binary>> -> trunc(calc_timing(last_run, timing))
#         unknown -> IO.puts("unknown scheduler pattern #{inspect unknown}")
#       end
#     end
#     def calc_amount(amount) do
#       {number, unit} = case Float.parse(amount) do
#         :error -> {1, amount}
#         result -> result
#       end
#       number * from_unit(unit)
#     end
#     def calc_timing(last_run, timing) do
#       divisor = calc_amount(timing)
#       next_step = round((last_run / divisor) + 1)
#       next_step * divisor
#     end
#     @unit_map %{
#       "millisec" => 1,
#       "millisecs" => 1,
#       "sec" => 1_000,
#       "secs" => 1_000,
#       "min" => 60 * 1_000,
#       "mins" => 60 * 1_000,
#       "hour" => 60 * 60 * 1_000,
#       "hours" => 60 * 60 * 1_000,
#       "day" => 24 * 60 * 60 * 1_000,
#       "days" => 24 * 60 * 60 * 1_000,
#       "week" => 7 * 24 * 60 * 60 * 1_000,
#       "weeks" => 7 * 24 * 60 * 60 * 1_000
#     }
#     def from_unit(unit) do
#       case Map.fetch(@unit_map, unit) do
#         {:ok, amount} -> amount
#         :error -> raise ArgumentError, "Unexpected unit: #{inspect unit}!"
#       end
#     end
#   end
#   # MARK: Job
#   defmodule Job do
#     @enforce_keys [:name, :schedule, :func]
#     defstruct name: nil,
#               schedule: nil,
#               func: nil,
#               state: %{
#                 state: :deactivated,
#                 next_run: nil,
#                 last_run: nil
#               }

#     @opaque t :: %__MODULE__{
#             name: String.t(),
#             schedule: String.t() | atom,
#             func: fun,
#             state: %{
#               state: atom,
#               next_run: nil | pos_integer,
#               last_run: nil | pos_integer
#             }
#           }
#     def new(name, schedule, func) do
#       %Job{name: name, schedule: schedule, func: func}
#     end
#   end

#   # MARK: State
#   defmodule State do
#     alias Fledex.Animation.Job
#     defstruct jobs: %{}, timer_ref: nil, next_run: nil

#     @type t :: %__MODULE__{
#             jobs: %{atom => Job},
#             timer_ref: nil | reference,
#             next_run: nil | pos_integer
#           }
#   end

#   # MARK: client code
#   def start_link(opts) do
#     pid = Process.whereis(__MODULE__)

#     if pid == nil do
#       GenServer.start_link(__MODULE__, opts, name: __MODULE__)
#     else
#       # server is already running. We could reconfigure it, but we don't do this here.
#       {:ok, pid}
#     end
#   end

#   def add_job(%Job{} = job) do
#     GenServer.call(__MODULE__, {:add_job, job})
#   end

#   def update_job(%Job{} = job) do
#     GenServer.call(__MODULE__, {:update_job, job})
#   end

#   def delete_job(name) do
#     GenServer.call(__MODULE__, {:delete_job, name})
#   end

#   # MARK: server side
#   @impl true
#   def init(_opts) do
#     # :timer.send_interval(state.interval_ms, :work)
#     # # we send ourselve immediately a request
#     # send(self(), :work)
#     state = %State{}
#     %{jobs: %{}}
#     {:ok, state}
#   end

#   @impl true
#   def handle_call({:add_job, %Job{name: name}}, _from, %{jobs: jobs} = state)
#       when is_map_key(jobs, name) do
#     {:repy, {:error, "job with this name already exists"}, state}
#   end
#   def handle_call({:add_job, %Job{} = job}, _from, state) do
#     state =
#       state
#       |> create_job(job)
#       |> update_timer

#     {:repy, :ok, state}
#   end

#   def handle_call({:update_job, %Job{name: name} = job}, _from, %{jobs: jobs} = state)
#       when is_map_key(jobs, name) do
#     state =
#       state
#       |> update_job(job)
#       |> update_timer

#     {:reply, :ok, state}
#   end
#   def handle_call({:update_job, %Job{name: name} = _job}, _from, state) do
#     {:reply, {:error, "job with name '#{inspect(name)}' not found"}, state}
#   end

#   def handle_call({:delete_job, name}, _from, %{jobs: jobs} = state)
#       when is_atom(name) and is_map_key(jobs, name) do
#     state =
#       state
#       |> remove_job(name)
#       |> update_timer

#     {:reply, :ok, state}
#   end
#   def handle_call({:delete_job, name}, _from, state) do
#     {:reply, {:error, "job with name '#{inspect(name)}' not found"}, state}
#   end

#   @impl true
#   def handle_info({:timeout, _timer_ref, {:timer, run_at}}, %State{jobs: jobs} = state) do
#     jobs = run_jobs(jobs, run_at)
#     state = %{state | jobs: jobs}

#     {:noreply, update_timer(state)}
#   end

#   # MARK: private func
#   defp create_job(%State{jobs: jobs} = state, %Job{name: name} = job) do
#     job = job |> update_job_state()
#     %{state | jobs: Map.put_new(jobs, name, job)}
#   end

#   defp update_job(%State{jobs: jobs} = state, %Job{name: name} = job) do
#     %{state| jobs: Map.update!(jobs, name, fn old_job ->
#       job |> update_job_state(old_job)
#     end)}
#   end

#   defp update_job_state(job, old_job \\ nil) do
#     last_run = job.state.last_run ||
#                 old_job.state.last_run ||
#                 Utils.now_millis()
#     next_run = Utils.calculate_next_run(last_run, job.schedule)
#     state = old_job.state.state || :active
#     %{job | state: %{state: state, last_run: last_run, next_run: next_run}}
#   end

#   defp remove_job(%State{jobs: jobs} = state, name) do
#     %{state | jobs: Map.delete(jobs, name)}
#   end

#   defp update_timer(%State{jobs: jobs, timer_ref: timer_ref, next_run: next_run} = state) do
#     jobs = filter_inactive_jobs(jobs)
#     new_next_run = Enum.reduce(jobs, nil, fn ({_key, %Job{state: %{next_run: next_run} = _value}}, acc) ->
#       case acc do
#         nil -> next_run
#         acc -> min(acc, next_run)
#       end
#     end)
#     case new_next_run do
#       nil -> state
#       new_next_run when new_next_run != next_run ->
#         timer_ref = reset_timer(timer_ref, new_next_run)
#         %{state | timer_ref: timer_ref, next_run: new_next_run}
#       _else -> state
#     end
#   end
#   defp filter_inactive_jobs(jobs) do
#     Enum.filter(jobs, fn {_key, %Job{state: %{state: job_state, next_run: next_run}} = _value} ->
#       job_state == :active && next_run != nil
#     end)
#   end

#   defp reset_timer(timer_ref, next_run) do
#     case timer_ref do
#       nil -> nil
#       timer_ref -> :erlang.cancel_timer(timer_ref)
#     end
#     :erlang.start_timer(next_run, self(), {:timer, next_run}, abs: true)
#   end

#   defp run_jobs(jobs, run_at) do
#     Enum.map(jobs, fn {name, %Job{state: %{next_run: next_run}} = job} ->
#       job = if next_run == run_at do
#         run_job(job)
#         update_next_run(job)
#       else
#         job
#       end
#       {name, job}
#     end)
#       |> Map.new()

#   end
#   defp run_job(job) do
#     job
#   end

#   defp update_next_run(job) do
#     job
#   end
# end
