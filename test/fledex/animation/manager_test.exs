# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.ManagerTest do
  use ExUnit.Case, async: false

  import Mox

  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null
  alias Fledex.ManagerTestUtils
  alias Quantum

  @strip_name :test_strip
  setup do
    {:ok, pid} =
      start_supervised(%{
        id: Manager,
        start: {Manager, :start_link, []}
      })

    Manager.register_strip(@strip_name, [{Null, []}], [])
    %{pid: pid, strip_name: @strip_name}
  end

  describe "init" do
    test "don't double start", %{pid: pid} do
      assert pid == GenServer.whereis(Manager)
      assert {:ok, pid} == Manager.start_link()
    end
  end

  describe "client functions" do
    test "register/unregister led_strip", %{strip_name: strip_name} do
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]
      assert GenServer.whereis(strip_name) != nil

      Manager.unregister_strip(strip_name)
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == []
      assert GenServer.whereis(strip_name) == nil

      Manager.register_strip(strip_name, [{Null, []}], [])
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]
      assert GenServer.whereis(strip_name) != nil
    end

    test "register/unregister 2 led_strips", %{strip_name: strip_name} do
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]

      Manager.register_strip(:strip_name2, [{Null, []}], [])

      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name, :strip_name2]
    end

    test "re-register led_strip", %{strip_name: strip_name} do
      pid = GenServer.whereis(strip_name)
      assert pid != nil
      Manager.register_strip(strip_name, [{Null, []}], [])
      pid2 = GenServer.whereis(strip_name)
      assert pid == pid2
    end

    test "register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{type: :animation},
        t2: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert config == ManagerTestUtils.get_manager_config(strip_name)

      Enum.each(Map.keys(config), fn key ->
        assert GenServer.whereis(String.to_atom("Elixir.#{strip_name}.#{:animator}.#{key}")) !=
                 nil
      end)
    end

    test "re-register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{type: :animation},
        t2: %{type: :animation}
      }

      Manager.register_config(strip_name, config)
      assert GenServer.whereis(String.to_atom("Elixir.#{strip_name}.#{:animator}.#{:t2}")) != nil

      config2 = %{
        t1: %{type: :animation},
        t3: %{type: :animation}
      }

      Manager.register_config(strip_name, config2)
      assert config2 == ManagerTestUtils.get_manager_config(strip_name)

      assert GenServer.whereis(String.to_atom("Elixir.#{strip_name}.#{:animator}.#{:t2}")) == nil

      Enum.each(Map.keys(config2), fn key ->
        assert GenServer.whereis(String.to_atom("Elixir.#{strip_name}.#{:animator}.#{key}")) !=
                 nil
      end)
    end
  end

  describe "test jobs" do
    test "add job" do
      Fledex.MockJobScheduler
      |> expect(:create_job, fn _name, _schedule, _strip_name ->
        Quantum.Job.new(Quantum.scheduler_config([], Fledex.MockJobScheduler, JobScheduler))
      end)
      |> expect(:add_job, fn _job -> :ok end)

      use Fledex

      config =
        led_strip :john, :config, [] do
          job :timer, ~e[* * * * * * *]e do
            :ok
          end
        end

      state = %{
        jobs: %{},
        animations: %{},
        coordinators: %{},
        impls: %{
          job_scheduler: Fledex.MockJobScheduler,
          led_strip: Fledex.LedStrip
        }
      }

      {:reply, :ok, state} =
        Manager.handle_call({:register_strip, :john, [{Null, []}], []}, self(), state)

      {:reply, :ok, _state} =
        Manager.handle_call({:register_config, :john, config}, self(), state)

      Mox.verify!()
    end

    test "update job" do
      Fledex.MockJobScheduler
      |> expect(:create_job, fn _name, _schedule, _strip_name ->
        Quantum.Job.new(Quantum.scheduler_config([], Fledex.MockJobScheduler, JobScheduler))
      end)
      |> expect(:delete_job, fn _name -> :ok end)
      |> expect(:add_job, fn _job -> :ok end)

      use Fledex

      config =
        led_strip :john, :config do
          job :timer, ~e[1 * * * * * *]e do
            :ok
          end
        end

      state = %{
        animations: %{john: %{}},
        coordinators: %{john: %{}},
        jobs: %{
          john: %{
            timer: %{
              type: :job,
              pattern: ~e[* * * * * * *]e,
              options: [],
              func: fn -> :ok end
            }
          }
        },
        impls: %{
          job_scheduler: Fledex.MockJobScheduler,
          led_strip: Fledex.LedStrip
        }
      }

      {:reply, :ok, _state} =
        Manager.handle_call({:register_config, :john, config}, self(), state)

      Mox.verify!()
    end

    test "delete job" do
      Fledex.MockJobScheduler
      |> expect(:delete_job, fn _name -> :ok end)

      use Fledex

      config =
        led_strip :john, :config do
        end

      state = %{
        animations: %{john: %{}},
        coordinators: %{john: %{}},
        jobs: %{
          john: %{
            timer: %{
              type: :job,
              pattern: ~e[* * * * * * *]e,
              options: [],
              func: fn -> :ok end
            }
          }
        },
        impls: %{
          job_scheduler: Fledex.MockJobScheduler,
          led_strip: Fledex.LedStrip
        }
      }

      {:reply, :ok, _state} =
        Manager.handle_call({:register_config, :john, config}, self(), state)

      Mox.verify!()
    end
  end
end

defmodule Fledex.Animation.ManagerTest2 do
  use ExUnit.Case

  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null

  describe "Animation with wrong type" do
    test "register animation with a broken animation type" do
      {:ok, pid} = Manager.start_link()
      :ok = Manager.register_strip(:some_strip, [{Null, []}], [])

      config = %{
        t1: %{
          type: :test
        }
      }

      response = Manager.register_config(:some_strip, config)

      assert response == {:error, "An unknown type was encountered #{inspect(config)}"}
      Process.exit(pid, :normal)
    end
  end
end
