# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.ManagerTest do
  use ExUnit.Case, async: false

  alias Fledex.Animation.JobScheduler
  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null
  alias Fledex.ManagerTestUtils
  alias Fledex.Supervisor.AnimationSystem
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
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]
      assert ManagerTestUtils.whereis(strip_name, :led_strip) != nil

      Manager.unregister_strip(strip_name)
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == []
      assert ManagerTestUtils.whereis(strip_name, :led_strip) == nil

      Manager.register_strip(strip_name, [{Null, []}], [])
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]
      assert ManagerTestUtils.whereis(strip_name, :led_strip) != nil
    end

    test "register/unregister 2 led_strips", %{strip_name: strip_name} do
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]

      Manager.register_strip(:strip_name2, [{Null, []}], [])

      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name, :strip_name2]
    end

    test "re-register led_strip", %{strip_name: strip_name} do
      pid = ManagerTestUtils.whereis(strip_name, :led_strip)
      assert pid != nil
      Manager.register_strip(strip_name, [{Null, []}], [])
      pid2 = ManagerTestUtils.whereis(strip_name, :led_strip)
      assert pid == pid2
    end

    test "register animation", %{strip_name: strip_name} do
      config = %{
        t11: %{type: :animation},
        t12: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert config == ManagerTestUtils.get_manager_config(strip_name)

      Enum.each(Map.keys(config), fn key ->
        assert ManagerTestUtils.whereis(strip_name, :animator, key) != nil
      end)
    end

    test "re-register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{type: :animation},
        t2: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert ManagerTestUtils.whereis(strip_name, :animator, :t2) != nil

      config2 = %{
        t1: %{type: :animation},
        t3: %{type: :animation}
      }

      Manager.register_config(strip_name, config2)
      assert config2 == ManagerTestUtils.get_manager_config(strip_name)

      assert ManagerTestUtils.whereis(strip_name, :animator, :t2) == nil

      Enum.each(Map.keys(config2), fn key ->
        assert ManagerTestUtils.whereis(strip_name, :animator, key) != nil
      end)
    end
  end

  describe "test jobs" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      :ok
    end

    test "add job" do
      use Fledex, dont_start: true

      config =
        led_strip :john, :config, [] do
          job :timer, ~e[* * * * * * *]e do
            :ok
          end
        end

      Manager.register_strip(:john, [{Null, []}], [])
      Manager.register_config(:john, config)

      assert ManagerTestUtils.get_manager_config(:jobs, :john) == config
      assert length(JobScheduler.jobs()) == 1
    end

    test "change job" do
      use Fledex, dont_start: true

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

      jobs = ManagerTestUtils.get_manager_config(:jobs, :john)
      assert Map.has_key?(jobs, :before_timer)
      assert not Map.has_key?(jobs, :after_timer)
      jobs = JobScheduler.jobs()
      assert length(jobs) == 1
      assert Keyword.has_key?(jobs, :before_timer)
      assert not Keyword.has_key?(jobs, :after_timer)

      Manager.register_config(:john, after_config)

      jobs = ManagerTestUtils.get_manager_config(:jobs, :john)
      assert not Map.has_key?(jobs, :before_timer)
      assert Map.has_key?(jobs, :after_timer)
      jobs = JobScheduler.jobs()
      assert length(jobs) == 1
      assert not Keyword.has_key?(jobs, :before_timer)
      assert Keyword.has_key?(jobs, :after_timer)
    end

    test "update job" do
      use Fledex, dont_start: true

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

      jobs1 = ManagerTestUtils.get_manager_config(:jobs, :john)
      assert Map.has_key?(jobs1, :timer)
      jobs1 = JobScheduler.jobs()
      assert length(jobs1) == 1
      assert Keyword.has_key?(jobs1, :timer)

      Manager.register_config(:john, after_config)

      jobs2 = ManagerTestUtils.get_manager_config(:jobs, :john)
      assert Map.has_key?(jobs2, :timer)
      jobs2 = JobScheduler.jobs()
      assert length(jobs2) == 1
      assert Keyword.has_key?(jobs2, :timer)

      schedule1 = Keyword.fetch!(jobs1, :timer) |> Map.fetch!(:schedule)
      schedule2 = Keyword.fetch!(jobs2, :timer) |> Map.fetch!(:schedule)
      assert schedule1 != schedule2
    end

    test "delete job" do
      use Fledex, dont_start: true

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

      assert length(JobScheduler.jobs()) == 1

      Manager.register_config(:john, after_config)
      assert Enum.empty?(JobScheduler.jobs())
    end
  end

  describe "test coordinators" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      Manager.register_strip(@strip_name, [{Null, []}], [])
      %{strip_name: @strip_name}
    end

    test "create coordinator", %{strip_name: strip_name} do
      use Fledex, dont_start: true

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
      use Fledex, dont_start: true

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
      use Fledex, dont_start: true

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
  use ExUnit.Case

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
