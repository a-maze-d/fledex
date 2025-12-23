# Copyright 2025, Matthias Reik <fledex@reik.org>
# Modified version of : https://github.com/SchedEx/SchedEx
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT
defmodule Fledex.Scheduler.SchedExTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Crontab.CronExpression.Parser
  alias Fledex.Scheduler.SchedEx
  alias Fledex.Scheduler.SchedEx.Job
  alias Fledex.Scheduler.SchedEx.Runner
  alias Fledex.Scheduler.SchedEx.Stats
  alias Fledex.Scheduler.SchedEx.Stats.Value

  doctest Fledex.Scheduler.SchedEx

  @sleep_duration 200
  @sleep_duration_plus_margin @sleep_duration + 10

  defmodule TestCallee do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> [] end)
    end

    def append(pid, x) do
      Agent.update(pid, &Kernel.++(&1, [x]))
    end

    def clear(pid) do
      Agent.get_and_update(pid, fn val -> {val, []} end)
    end
  end

  defmodule TestTimeScale do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def now(timezone) do
      GenServer.call(__MODULE__, {:now, timezone})
    end

    def speedup do
      GenServer.call(__MODULE__, {:speedup})
    end

    def init({base_time, speedup}) do
      Process.flag(:trap_exit, true)

      {:ok, %{base_time: base_time, time_0: DateTime.utc_now(), speedup: speedup}}
    end

    def handle_call(
          {:now, timezone},
          _from,
          %{base_time: base_time, time_0: time_0, speedup: speedup} = state
        ) do
      diff = DateTime.diff(DateTime.utc_now(), time_0, :millisecond) * speedup

      now =
        base_time
        |> DateTime.shift(microsecond: {diff * 1000, 6})
        |> DateTime.shift_zone!(timezone)

      {:reply, now, state}
    end

    def handle_call({:speedup}, _from, %{speedup: speedup} = state) do
      {:reply, speedup, state}
    end

    def terminate(_reason, _state) do
      # we can add here some debugging stuff
      # IO.puts("TestTimeScale terminating...")
    end
  end

  setup do
    {:ok, agent} = start_supervised(TestCallee)
    {:ok, agent: agent}
  end

  describe "run_at" do
    test "runs the m,f,a at the expected time", context do
      SchedEx.run_at(
        TestCallee,
        :append,
        [context.agent, 1],
        DateTime.shift(DateTime.utc_now(), microsecond: {@sleep_duration * 1000, 3})
      )

      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "runs the fn at the expected time", context do
      SchedEx.run_at(
        fn -> TestCallee.append(context.agent, 1) end,
        DateTime.shift(DateTime.utc_now(), microsecond: {@sleep_duration * 1000, 3})
      )

      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "runs immediately (but not in process) if the expected time is in the past", context do
      SchedEx.run_at(
        TestCallee,
        :append,
        [context.agent, 1],
        DateTime.shift(DateTime.utc_now(), microsecond: {@sleep_duration * 1000, 3})
      )

      # Add a bit of wiggle_room
      Process.sleep(@sleep_duration_plus_margin)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "is cancellable", context do
      {:ok, pid} =
        SchedEx.run_at(
          TestCallee,
          :append,
          [context.agent, 1],
          DateTime.shift(DateTime.utc_now(), microsecond: {@sleep_duration * 1000, 3})
        )

      :ok = SchedEx.cancel(pid)
      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == []
    end
  end

  describe "run_in" do
    test "runs the m,f,a after the expected delay", context do
      SchedEx.run_in(TestCallee, :append, [context.agent, 1], @sleep_duration)
      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "runs the m,f,a after the expected delay (with unit, milliseconds)", context do
      SchedEx.run_in(TestCallee, :append, [context.agent, 1], {@sleep_duration, :ms})
      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [1]
      SchedEx.run_in(TestCallee, :append, [context.agent, 1], {@sleep_duration, :milliseconds})
      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [1]
    end

    @name :unit_check
    test "check delay with implicit milliseconds" do
      job = Job.new(@name, fn -> :ok end, 1_000, %{}, repeat: true)

      SchedEx.run_job(job, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1_000
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (seconds)" do
      SchedEx.run_in(fn -> :ok end, {1, :seconds}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (sec)" do
      job = Job.new(@name, fn -> :ok end, {1, :sec}, %{}, repeat: true)

      SchedEx.run_job(job, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (s)" do
      SchedEx.run_in(fn -> :ok end, {1, :s}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (minutes)" do
      SchedEx.run_in(fn -> :ok end, {1, :minutes}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (min)" do
      SchedEx.run_in(fn -> :ok end, {1, :min}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (m)" do
      SchedEx.run_in(fn -> :ok end, {1, :m}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (h)" do
      SchedEx.run_in(fn -> :ok end, {1, :h}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (hours)" do
      SchedEx.run_in(fn -> :ok end, {1, :hours}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (days)" do
      SchedEx.run_in(fn -> :ok end, {1, :days}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60 * 24
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (d)" do
      SchedEx.run_in(fn -> :ok end, {1, :d}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60 * 24
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (weeks)" do
      SchedEx.run_in(fn -> :ok end, {1, :weeks}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60 * 24 * 7
      SchedEx.cancel(@name)
    end

    test "check bigger delays are correct (w)" do
      SchedEx.run_in(fn -> :ok end, {1, :w}, name: @name)
      {_sched, _quant_sched, delay} = Runner.next_schedule(@name)
      assert delay == 1 * 1_000 * 60 * 60 * 24 * 7
      SchedEx.cancel(@name)
    end

    test "runs the fn after the expected delay", context do
      SchedEx.run_in(fn -> TestCallee.append(context.agent, 1) end, @sleep_duration)
      Process.sleep(2 * @sleep_duration_plus_margin)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "optionally passes the runtime into the m,f,a", context do
      now = DateTime.utc_now()
      expected_time = DateTime.shift(now, microsecond: {@sleep_duration * 1000, 6})

      SchedEx.run_in(
        TestCallee,
        :append,
        [context.agent, :sched_ex_scheduled_time],
        @sleep_duration,
        start_time: now
      )

      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [expected_time]
    end

    test "optionally passes the runtime into the fn", context do
      now = DateTime.utc_now()
      expected_time = DateTime.shift(now, microsecond: {@sleep_duration * 1000, 6})

      SchedEx.run_in(
        fn time -> TestCallee.append(context.agent, time) end,
        @sleep_duration,
        start_time: now
      )

      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == [expected_time]
    end

    test "can repeat", context do
      SchedEx.run_in(fn -> TestCallee.append(context.agent, 1) end, @sleep_duration, repeat: true)
      Process.sleep(round(2.5 * @sleep_duration))
      calls = TestCallee.clear(context.agent)
      assert length(calls) >= 2
      assert length(calls) <= 4
    end

    test "respects timescale", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1000}}, restart: :temporary)

      SchedEx.run_in(
        fn -> TestCallee.append(context.agent, 1) end,
        1000 * @sleep_duration,
        repeat: true,
        time_scale: TestTimeScale
      )

      Process.sleep(round(2.5 * @sleep_duration))
      assert TestCallee.clear(context.agent) == [1, 1]
    end

    test "runs immediately (but not in process) if the expected delay is non-positive", context do
      SchedEx.run_in(TestCallee, :append, [context.agent, 1], -100_000)
      Process.sleep(@sleep_duration_plus_margin)
      assert TestCallee.clear(context.agent) == [1]
    end

    test "is cancellable", context do
      {:ok, pid} = SchedEx.run_in(TestCallee, :append, [context.agent, 1], @sleep_duration)
      :ok = SchedEx.cancel(pid)
      Process.sleep(2 * @sleep_duration)
      assert TestCallee.clear(context.agent) == []
    end
  end

  describe "run_every" do
    test "runs the m,f,a per the given crontab", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      SchedEx.run_every(
        TestCallee,
        :append,
        [context.agent, 1],
        "* * * * *",
        time_scale: TestTimeScale
      )

      Process.sleep(2000)
      calls = TestCallee.clear(context.agent)
      assert length(calls) >= 2
      assert length(calls) <= 4
    end

    test "runs the fn per the given crontab", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      SchedEx.run_every(
        fn -> TestCallee.append(context.agent, 1) end,
        "* * * * *",
        time_scale: TestTimeScale
      )

      Process.sleep(2000)
      runs = length(TestCallee.clear(context.agent))
      assert runs >= 2
      assert runs <= 3
    end

    test "respects the repeat flag", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      {:ok, pid} =
        SchedEx.run_every(
          fn -> TestCallee.append(context.agent, 1) end,
          "* * * * *",
          repeat: false,
          time_scale: TestTimeScale
        )

      Process.sleep(2000)
      assert TestCallee.clear(context.agent) == [1]
      refute Process.alive?(pid)
    end

    test "terminates after running if the crontab never fires again", context do
      now = DateTime.utc_now()
      then = DateTime.shift(now, second: 30)

      crontab =
        Parser.parse!(
          "#{then.second} #{then.minute} #{then.hour} #{then.day} #{then.month} * #{then.year}",
          true
        )

      {:ok, _pid} = start_supervised({TestTimeScale, {now, 60}}, restart: :temporary)

      {:ok, pid} =
        SchedEx.run_every(
          fn -> TestCallee.append(context.agent, 1) end,
          crontab,
          time_scale: TestTimeScale
        )

      Process.sleep(2000)

      runs = length(TestCallee.clear(context.agent))
      assert runs >= 1
      assert runs <= 2
      refute Process.alive?(pid)
    end

    test "doesn't start up if the crontab never fires in the future" do
      now = DateTime.utc_now()
      then = DateTime.shift(now, second: -30)

      crontab =
        Parser.parse!(
          "#{then.second} #{then.minute} #{then.hour} #{then.day} #{then.month} * #{then.year}",
          true
        )

      # we do start, but will terminate more or less immediately
      assert {:ok, pid} = SchedEx.run_every(fn -> :ok end, crontab)
      # the process will shut down as soon as it realizes that nothing needs to be done
      Process.sleep(100)
      refute Process.alive?(pid)
    end

    test "supports parsing extended strings", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1}}, restart: :temporary)

      SchedEx.run_every(
        fn -> TestCallee.append(context.agent, 1) end,
        "* * * * * * *",
        time_scale: TestTimeScale
      )

      Process.sleep(2000)

      runs = length(TestCallee.clear(context.agent))
      assert runs >= 2
      assert runs <= 3
    end

    test "supports crontab expressions (and extended ones at that)", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1}}, restart: :temporary)

      crontab = Parser.parse!("* * * * * *", true)

      SchedEx.run_every(
        fn -> TestCallee.append(context.agent, 1) end,
        crontab,
        time_scale: TestTimeScale
      )

      Process.sleep(2000)

      runs = length(TestCallee.clear(context.agent))
      assert runs >= 2
      assert runs <= 3
    end

    test "optionally passes the runtime into the m,f,a", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      {:ok, crontab} = Parser.parse("* * * * *")

      {:ok, expected_naive_time} =
        Crontab.Scheduler.get_next_run_date(crontab, NaiveDateTime.utc_now())

      expected_time = DateTime.from_naive!(expected_naive_time, "Etc/UTC")

      SchedEx.run_every(
        TestCallee,
        :append,
        [context.agent, :sched_ex_scheduled_time],
        "* * * * *",
        time_scale: TestTimeScale
      )

      Process.sleep(1000)
      assert hd(TestCallee.clear(context.agent)) == expected_time
    end

    test "optionally passes the runtime into the fn", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      {:ok, crontab} = Parser.parse("* * * * *")

      {:ok, expected_naive_time} =
        Crontab.Scheduler.get_next_run_date(crontab, NaiveDateTime.utc_now())

      expected_time = DateTime.from_naive!(expected_naive_time, "Etc/UTC")

      SchedEx.run_every(
        fn time -> TestCallee.append(context.agent, time) end,
        "* * * * *",
        time_scale: TestTimeScale
      )

      Process.sleep(1000)
      assert hd(TestCallee.clear(context.agent)) == expected_time
    end

    test "supports interpreting crontab in a given timezone", context do
      now = DateTime.now!("America/Chicago")
      {:ok, _pid} = start_supervised({TestTimeScale, {now, 86_400}}, restart: :temporary)
      {:ok, crontab} = Parser.parse("0 1 * * *")

      {:ok, naive_expected_time} =
        Crontab.Scheduler.get_next_run_date(crontab, DateTime.to_naive(now))

      expected_time = DateTime.from_naive!(naive_expected_time, "America/Chicago")

      SchedEx.run_every(
        fn time -> TestCallee.append(context.agent, time) end,
        "0 1 * * *",
        timezone: "America/Chicago",
        time_scale: TestTimeScale
      )

      Process.sleep(1000)
      assert hd(TestCallee.clear(context.agent)) == expected_time
    end

    test "skips non-existent times when configured to do so and crontab refers to a non-existent time",
         context do
      # Next time will resolve to 2:30 AM CDT, which doesn't exist
      now = DateTime.from_naive!(~N[2019-03-10 00:30:00], "America/Chicago")
      {:ok, _pid} = start_supervised({TestTimeScale, {now, 86_400}}, restart: :temporary)

      # Skip invocations until the next valid one
      expected_time_for_skip = DateTime.from_naive!(~N[2019-03-11 02:30:00], "America/Chicago")

      SchedEx.run_every(
        fn time -> TestCallee.append(context.agent, time) end,
        "30 2 * * *",
        timezone: "America/Chicago",
        nonexistent_time_strategy: :skip,
        time_scale: TestTimeScale
      )

      # Needs an extra second to sleep since it's going a day forward
      Process.sleep(2000)
      assert hd(TestCallee.clear(context.agent)) == expected_time_for_skip
    end

    test "adjusts non-existent times when configured to do so and crontab refers to a non-existent time",
         context do
      # Next time will resolve to 2:30 AM CDT, which doesn't exist
      now = DateTime.from_naive!(~N[2019-03-10 00:30:00], "America/Chicago")
      {:ok, _pid} = start_supervised({TestTimeScale, {now, 86_400}}, restart: :temporary)

      # Adjust the invocation forward so it's the same number of seconds from midnight
      expected_time_for_adjust = DateTime.from_naive!(~N[2019-03-10 03:30:00], "America/Chicago")

      SchedEx.run_every(
        fn time -> TestCallee.append(context.agent, time) end,
        "30 2 * * *",
        timezone: "America/Chicago",
        nonexistent_time_strategy: :adjust,
        time_scale: TestTimeScale
      )

      Process.sleep(1000)
      [adjusted_time] = TestCallee.clear(context.agent)

      # Elixir 1.14.2 changes the behaviour here wrt microsecond adjustment, so just compare to
      # the nearest second so that this test works everywhere
      adjusted_time = DateTime.truncate(adjusted_time, :second)

      assert adjusted_time == expected_time_for_adjust
    end

    test "takes the later time when configured to do so and crontab refers to an ambiguous time",
         context do
      # Next time will resolve to 1:00 AM CST, which is ambiguous
      now = DateTime.from_naive!(~N[2017-11-05 00:30:00], "America/Chicago")
      {:ok, _pid} = start_supervised({TestTimeScale, {now, 86_400}}, restart: :temporary)

      # Pick the later of the two ambiguous times
      expected_time = DateTime.from_naive(~N[2017-11-05 01:00:00], "America/Chicago") |> elem(2)

      SchedEx.run_every(
        fn time -> TestCallee.append(context.agent, time) end,
        "0 1 * * *",
        timezone: "America/Chicago",
        time_scale: TestTimeScale
      )

      Process.sleep(1000)
      assert TestCallee.clear(context.agent) == [expected_time]
    end

    test "is cancellable", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      {:ok, pid} =
        SchedEx.run_every(
          TestCallee,
          :append,
          [context.agent, 1],
          "* * * * *",
          time_scale: TestTimeScale
        )

      :ok = SchedEx.cancel(pid)
      Process.sleep(1000)
      assert TestCallee.clear(context.agent) == []
    end

    test "handles invalid crontabs", context do
      {:error, error} = SchedEx.run_every(TestCallee, :append, [context.agent, 1], "O M G W T")
      assert error == "Can't parse O as minute."
    end

    test "accepts a name option", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 60}}, restart: :temporary)

      {:ok, pid} =
        SchedEx.run_every(
          fn -> TestCallee.append(context.agent, 1) end,
          "* * * * *",
          name: :name_test,
          time_scale: TestTimeScale
        )

      assert pid == Process.whereis(:name_test)
      Process.sleep(10)
      # IO.puts("test done!")
    end
  end

  describe "run_job" do
    test "run job with crontab", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1}}, restart: :temporary)

      crontab = Parser.parse!("* * * * * *", true)

      job =
        Job.new()
        |> Job.set_name(:test_job)
        |> Job.set_schedule(crontab)
        |> Job.set_task(fn -> TestCallee.append(context.agent, 1) end)
        |> Job.set_repeat(true)
        |> Job.set_timezone("Etc/UTC")
        |> Job.set_overlap(false)
        |> Job.set_context(%{strip_name: :test_strip, job: :test_job})

      SchedEx.run_job(job, time_scale: TestTimeScale)

      Process.sleep(2000)
      # if we are unlucky we might get more than 2
      assert length(TestCallee.clear(context.agent)) >= 2
    end

    test "update job", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1}}, restart: :temporary)

      job =
        Job.new()
        |> Job.set_name(:test_job)
        |> Job.set_schedule({@sleep_duration, :ms})
        |> Job.set_task(fn -> TestCallee.append(context.agent, 1) end)
        |> Job.set_repeat(true)

      {:ok, pid} = SchedEx.run_job(job, time_scale: TestTimeScale)
      Process.sleep(@sleep_duration_plus_margin)

      job2 = job |> Job.set_task(fn -> TestCallee.append(context.agent, 2) end)

      SchedEx.update_job(pid, job2, time_scale: TestTimeScale)
      Process.sleep(@sleep_duration_plus_margin)

      assert TestCallee.clear(context.agent) >= [1, 2]
    end

    test "update job that does not reschedule", context do
      {:ok, _pid} =
        start_supervised({TestTimeScale, {DateTime.utc_now(), 1}}, restart: :temporary)

      job =
        Job.new()
        |> Job.set_name(:test_job)
        |> Job.set_schedule({@sleep_duration, :ms})
        |> Job.set_task(fn -> TestCallee.append(context.agent, 1) end)
        |> Job.set_repeat(true)
        |> Job.set_timezone("Etc/UTC")

      {:ok, pid} = SchedEx.run_job(job, time_scale: TestTimeScale)
      Process.sleep(@sleep_duration_plus_margin)

      now = DateTime.utc_now()

      crontab =
        Parser.parse!(
          "#{now.second} #{now.minute} #{now.hour} #{now.day} #{now.month} * #{now.year - 1}",
          true
        )

      job2 =
        job
        |> Job.set_task(fn -> TestCallee.append(context.agent, 2) end)
        |> Job.set_schedule(crontab)

      assert :shutdown == SchedEx.update_job(pid, job2, time_scale: TestTimeScale)
    end
  end

  describe "timer process supervision" do
    defmodule TerminationHelper do
      use GenServer

      def start_link(_opts) do
        GenServer.start_link(__MODULE__, [])
      end

      def schedule_job(pid, m, f, a, delay) do
        GenServer.call(pid, {:schedule_job, m, f, a, delay})
      end

      def self_destruct(pid, delay) do
        GenServer.call(pid, {:self_destruct, delay})
      end

      def init(_opts) do
        {:ok, %{}}
      end

      def handle_call({:schedule_job, m, f, a, delay}, _from, state) do
        {:ok, timer} = SchedEx.run_in(m, f, a, delay)
        {:reply, timer, state}
      end

      def handle_call({:self_destruct, delay}, from, state) do
        {:ok, timer} = SchedEx.run_in(fn -> 2 + 2 end, delay)
        send(timer, {:EXIT, from, :normal})
        {:reply, timer, state}
      end
    end

    setup do
      {:ok, helper} = start_supervised(TerminationHelper, restart: :temporary)
      {:ok, helper: helper}
    end

    test "timers should die along with their creator process", context do
      timer =
        TerminationHelper.schedule_job(
          context.helper,
          TestCallee,
          :append,
          [context.agent, 1],
          5 * @sleep_duration
        )

      GenServer.stop(context.helper)
      Process.sleep(@sleep_duration)

      refute Process.alive?(context.helper)
      refute Process.alive?(timer)

      Process.sleep(10 * @sleep_duration)
      assert TestCallee.clear(context.agent) == []
    end

    test "timers that exit normally should not take their creator process along with them",
         context do
      defmodule Quitter do
        def leave do
          Process.exit(self(), :normal)
        end
      end

      timer = TerminationHelper.schedule_job(context.helper, Quitter, :leave, [], @sleep_duration)
      Process.sleep(2 * @sleep_duration)

      assert Process.alive?(context.helper)
      refute Process.alive?(timer)
    end

    test "timers that die should take their creator process along with them by default",
         context do
      defmodule Crasher do
        def boom do
          raise "boom"
        end
      end

      warnings =
        capture_log(fn ->
          timer =
            TerminationHelper.schedule_job(context.helper, Crasher, :boom, [], @sleep_duration)

          Process.sleep(5 * @sleep_duration)

          refute Process.alive?(context.helper)
          refute Process.alive?(timer)
        end)

      assert warnings =~ "(RuntimeError) boom"
    end

    @tag exit: true
    test "timers should ignore messages from processes that exit normally.", context do
      timer = TerminationHelper.self_destruct(context.helper, @sleep_duration)
      Process.sleep(div(@sleep_duration, 2))
      assert Process.alive?(timer)
    end
  end

  describe "stats" do
    test "returns stats on the running job", context do
      {:ok, pid} =
        SchedEx.run_in(TestCallee, :append, [context.agent, 1], @sleep_duration, repeat: true)

      Process.sleep(@sleep_duration_plus_margin)

      %Stats{
        scheduling_delay: %Value{
          min: sched_min,
          max: sched_max,
          avg: sched_avg,
          count: sched_count
        },
        execution_time: %Value{
          min: exec_min,
          max: exec_max,
          avg: exec_avg,
          count: exec_count
        }
      } = SchedEx.stats(pid)

      assert sched_count == 1
      # Assume that scheduling delay is 1..3000 usec
      assert sched_avg > 1.0
      assert sched_avg < 3000.0
      assert sched_min == sched_avg
      assert sched_max == sched_avg

      assert exec_count == 1
      # Assume that execution time is 1..200 usec
      assert exec_avg > 1.0
      assert exec_avg < 200.0
      assert exec_min == exec_avg
      assert exec_max == exec_avg
    end
  end
end
