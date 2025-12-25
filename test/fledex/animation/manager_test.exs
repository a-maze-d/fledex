# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.ManagerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null
  alias Fledex.ManagerTestUtils
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.LedStripSupervisor
  alias Quantum

  @strip_name :test_strip
  describe "init" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      Manager.register_strip(@strip_name, [{Null, []}], [])
      pid = Process.whereis(Manager)

      %{pid: pid, strip_name: @strip_name}
    end

    test "don't double start", %{pid: pid} do
      assert {:ok, pid} == Manager.start_link()
    end
  end

  describe "client functions" do
    setup do
      start_supervised(AnimationSystem.child_spec())

      Manager.register_strip(@strip_name, [{Null, []}], [])

      %{strip_name: @strip_name}
    end

    test "register/unregister led_strip", %{strip_name: strip_name} do
      assert AnimationSystem.led_strip_exists?(strip_name)

      Manager.unregister_strip(strip_name)
      # wait a bit
      Process.sleep(500)
      assert not AnimationSystem.led_strip_exists?(strip_name)

      Manager.register_strip(strip_name, [{Null, []}], [])
      assert AnimationSystem.led_strip_exists?(strip_name)

      capture_log(fn ->
        assert :ok == AnimationSystem.stop_led_strip(:non_existing_strip)
      end)
    end

    test "register/unregister 2 led_strips", %{strip_name: strip_name} do
      assert AnimationSystem.led_strip_exists?(strip_name)

      Manager.register_strip(:strip_name2, [{Null, []}], [])
      assert AnimationSystem.led_strip_exists?(strip_name)
      assert AnimationSystem.led_strip_exists?(:strip_name2)
    end

    test "re-register led_strip", %{strip_name: strip_name} do
      pid = ManagerTestUtils.whereis(strip_name, :led_strip, :supervisor)
      assert pid != nil
      Manager.register_strip(strip_name, [{Null, []}], [])
      pid2 = ManagerTestUtils.whereis(strip_name, :led_strip, :supervisor)
      assert pid == pid2
    end

    test "register animation", %{strip_name: strip_name} do
      config = %{
        t11: %{type: :animation},
        t12: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert LedStripSupervisor.animation_exists?(strip_name, :t11)
      assert LedStripSupervisor.animation_exists?(strip_name, :t12)
      assert not LedStripSupervisor.animation_exists?(strip_name, :t13)

      capture_log(fn ->
        assert :ok == LedStripSupervisor.stop_animation(strip_name, :non_existing_animation)
      end)
    end

    test "re-register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{type: :animation},
        t2: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert LedStripSupervisor.animation_exists?(strip_name, :t1)
      assert LedStripSupervisor.animation_exists?(strip_name, :t2)
      assert not LedStripSupervisor.animation_exists?(strip_name, :t3)

      config2 = %{
        t1: %{type: :animation},
        t3: %{type: :animation}
      }

      Manager.register_config(strip_name, config2)
      assert LedStripSupervisor.animation_exists?(strip_name, :t1)
      assert not LedStripSupervisor.animation_exists?(strip_name, :t2)
      assert LedStripSupervisor.animation_exists?(strip_name, :t3)
    end
  end

  describe "test jobs" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      :ok
    end

    test "add job" do
      use Fledex, dont_start: true, colors: :none

      config =
        led_strip :john, :config, [] do
          job :timer, ~e[* * * * * * *]e do
            :ok
          end
        end

      Manager.register_strip(:john, [{Null, []}], [])
      Manager.register_config(:john, config)

      assert length(LedStripSupervisor.get_jobs(:john)) == 1
    end

    test "change job" do
      use Fledex, dont_start: true, colors: :none

      before_config =
        led_strip :john, :config do
          job :before_timer, ~e[1 * * * * * *]e do
            :ok
          end
        end

      after_config =
        led_strip :john, :config do
          job :after_timer, ~e[1 * * * * * *]e do
            :ok
          end
        end

      Manager.register_strip(:john, [{Null, []}], [])
      Manager.register_config(:john, before_config)

      jobs = LedStripSupervisor.get_jobs(:john)
      assert length(jobs) == 1
      assert :before_timer in jobs
      assert :after_timer not in jobs

      Manager.register_config(:john, after_config)

      jobs = LedStripSupervisor.get_jobs(:john)
      assert length(jobs) == 1
      assert :before_timer not in jobs
      assert :after_timer in jobs
    end

    test "update job" do
      use Fledex, dont_start: true, colors: :none

      before_config =
        led_strip :john, :config do
          job :timer, ~e[2 * * * * * *]e do
            :ok
          end
        end

      after_config =
        led_strip :john, :config do
          job :timer, ~e[1 * * * * * *]e do
            :ok
          end
        end

      Manager.register_strip(:john, [{Null, []}], [])
      Manager.register_config(:john, before_config)

      jobs1 = LedStripSupervisor.get_jobs(:john)
      assert length(jobs1) == 1
      assert :timer in jobs1
      job1 = ManagerTestUtils.get_job_config(:john, :timer)
      assert job1.job.schedule == ~e[2 * * * * * *]e

      Manager.register_config(:john, after_config)

      jobs2 = LedStripSupervisor.get_jobs(:john)
      assert length(jobs2) == 1
      assert :timer in jobs2
      job2 = ManagerTestUtils.get_job_config(:john, :timer)
      assert job2.job.schedule == ~e[1 * * * * * *]e
    end

    test "delete job" do
      use Fledex, dont_start: true, colors: :none

      before_config =
        led_strip :john, :config do
          job :before_timer, ~e[* * * * * * *]e do
            :ok
          end
        end

      after_config =
        led_strip :john, :config do
        end

      Manager.register_strip(:john, [{Null, []}], [])
      Manager.register_config(:john, before_config)

      assert length(LedStripSupervisor.get_jobs(:john)) == 1

      Manager.register_config(:john, after_config)
      assert Enum.empty?(LedStripSupervisor.get_jobs(:john))
    end
  end

  describe "test coordinators" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      Manager.register_strip(@strip_name, [{Null, []}], [])
      %{strip_name: @strip_name}
    end

    test "create coordinator", %{strip_name: strip_name} do
      use Fledex, dont_start: true, colors: :none

      config1 =
        led_strip strip_name, :config do
          coordinator :coord1, [] do
            {_state, _context, opts} -> Keyword.put(opts, :test1, true)
          end
        end

      :ok = Manager.register_config(strip_name, config1)
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord1) != nil
    end

    test "update coordinator", %{strip_name: strip_name} do
      use Fledex, dont_start: true, colors: :none

      config1 =
        led_strip strip_name, :config do
          coordinator :coord1, [] do
            {_state, _context, opts} -> Keyword.put(opts, :test1, true)
          end
        end

      config2 =
        led_strip strip_name, :config do
          coordinator :coord1 do
            {_state, _context, opts} -> Keyword.put(opts, :test2, true)
          end

          coordinator :coord2, [] do
            {_state, _context, opts} -> Keyword.put(opts, :test1, false)
          end
        end

      :ok = Manager.register_config(strip_name, config1)
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord1) != nil
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord2) == nil

      :ok = Manager.register_config(strip_name, config2)
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord1) != nil
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord2) != nil
    end

    test "delete coordinator", %{strip_name: strip_name} do
      use Fledex, dont_start: true, colors: :none

      config1 =
        led_strip strip_name, :config do
          coordinator :coord1, [] do
            {_state, _context, opts} -> Keyword.put(opts, :test1, true)
          end
        end

      config2 =
        led_strip strip_name, :config do
        end

      :ok = Manager.register_config(strip_name, config1)
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord1) != nil

      :ok = Manager.register_config(strip_name, config2)
      assert ManagerTestUtils.whereis(strip_name, :coordinator, :coord1) == nil
    end
  end
end

defmodule Fledex.Animation.ManagerTest2 do
  use ExUnit.Case, async: false

  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null
  alias Fledex.Supervisor.AnimationSystem

  setup do
    {:ok, _pid} = start_supervised(AnimationSystem.child_spec())
    :ok
  end

  describe "Animation with wrong type" do
    test "register animation with a broken animation type" do
      :ok = Manager.register_strip(:some_strip, [{Null, []}], [])

      config = %{
        t1: %{
          type: :test
        }
      }

      response = Manager.register_config(:some_strip, config)

      assert response == {:error, "An unknown type was encountered #{inspect(config)}"}
    end
  end
end
