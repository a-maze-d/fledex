# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.SupervisorTest do
  use ExUnit.Case, async: false

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.Manager
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.LedStripSupervisor
  alias Fledex.Supervisor.Utils

  describe "animation system" do
    test "start in supervisor" do
      {:ok, pid} = AnimationSystem.start_link()
      assert Process.whereis(Manager) != nil

      Supervisor.terminate_child(AnimationSystem, Manager)
      assert Process.whereis(Manager) == nil

      AnimationSystem.stop()
      assert not Process.alive?(pid)
    end

    test "double start system" do
      {:ok, pid} = use Fledex, supervisor: :none
      {:ok, pid2} = use Fledex, supervisor: :none
      assert pid == pid2

      AnimationSystem.stop()
    end
  end

  defp count_workers do
    DynamicSupervisor.count_children(Utils.workers_supervisor())
    |> Map.get(:active)
  end

  defp count_workers(strip_name) do
    DynamicSupervisor.count_children(LedStripSupervisor.workers_name(strip_name))
    |> Map.get(:active)
  end

  defp supervisor_workers(strip_name) do
    DynamicSupervisor.count_children(LedStripSupervisor.supervisor_name(strip_name))
    |> Map.get(:active)
  end

  defp animation_workers(strip_name) do
    DynamicSupervisor.count_children(LedStripSupervisor.workers_name(strip_name))
    |> Map.get(:active)
  end

  @test_strip :test_strip
  @test_anim :my_anim
  @test_coord :my_coordinator
  describe "workers" do
    setup do
      start_supervised(AnimationSystem.child_spec())
      :ok
    end

    test "ensure correct naming for workers" do
      assert Utils.via_tuple(:testA, :animator, :testB) ==
               {:via, Registry, {Fledex.Supervisor.WorkersRegistry, {:testA, :animator, :testB}}}
    end

    test "led strip worker" do
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)
      assert count_workers() == 1
      LedStripSupervisor.stop(@test_strip)
      assert count_workers() == 0
    end

    defp get_led_strip_pid(strip_name) do
      Supervisor.which_children(LedStripSupervisor.supervisor_name(strip_name))
      |> Enum.filter(fn {_name, _pid, type, _module} -> type == :worker end)
      |> List.first()
      |> elem(1)
    end

    test "kill led strip" do
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)
      assert count_workers() == 1

      led_strip_pid1 = get_led_strip_pid(@test_strip)
      Process.exit(led_strip_pid1, :kill)
      led_strip_pid2 = get_led_strip_pid(@test_strip)
      assert led_strip_pid2 != nil
      assert led_strip_pid1 != led_strip_pid2

      LedStripSupervisor.stop(@test_strip)
      assert count_workers() == 0
    end

    test "animation worker" do
      # the animation requires an led strip
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)

      assert count_workers() == 1
      assert supervisor_workers(@test_strip) == 2
      assert animation_workers(@test_strip) == 0
      LedStripSupervisor.start_animation(@test_strip, @test_anim, %{type: :animation})

      assert count_workers() == 1
      assert supervisor_workers(@test_strip) == 2
      assert animation_workers(@test_strip) == 1

      Animator.stop(@test_strip, @test_anim)
      assert count_workers() == 1
      assert supervisor_workers(@test_strip) == 2
      assert animation_workers(@test_strip) == 0

      # cleanup
      LedStripSupervisor.stop(@test_strip)
      assert count_workers() == 0
    end

    def worker_pid(strip_name, worker_type, worker_name) do
      Registry.select(Utils.worker_registry(), [
        {
          {:"$1", :"$2", :"$3"},
          [],
          [{{:"$1", :"$2", :"$3"}}]
        }
      ])
      |> Enum.filter(fn {name, _pid, _other} ->
        {strip_name, worker_type, worker_name} == name
      end)
      |> List.first()
      |> elem(1)
    end

    test "kill animation" do
      # the animation requires an led strip
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)

      assert count_workers() == 1
      assert supervisor_workers(@test_strip) == 2
      assert animation_workers(@test_strip) == 0
      LedStripSupervisor.start_animation(@test_strip, @test_anim, %{type: :animation})

      animation_pid1 = worker_pid(@test_strip, :animator, @test_anim)
      assert animation_pid1 != nil

      # Logger.debug("killing animation #{inspect(animation_pid1)}...")
      Process.exit(animation_pid1, :kill)

      # give it some time to recove
      Process.sleep(2_000)

      animation_pid2 = worker_pid(@test_strip, :animator, @test_anim)
      assert animation_pid2 != nil
      assert animation_pid1 != animation_pid2

      LedStripSupervisor.stop(@test_strip)
    end

    test "coordinator worker" do
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)
      assert count_workers() == 1
      assert count_workers(@test_strip) == 0

      LedStripSupervisor.start_coordinator(@test_strip, @test_coord, %{
        func: fn _state, _context, _options -> :ok end
      })

      assert count_workers(@test_strip) == 1
      Coordinator.stop(@test_strip, @test_coord)
      assert count_workers(@test_strip) == 0
    end
  end

  describe "system supervisor" do
    test "app supervisor" do
      start_supervised(
        {DynamicSupervisor,
         name: Utils.app_supervisor(), strategy: :one_for_one, restart: :transient}
      )

      assert Enum.empty?(DynamicSupervisor.which_children(Utils.app_supervisor()))

      use Fledex, supervisor: :app
      assert not Enum.empty?(DynamicSupervisor.which_children(Utils.app_supervisor()))

      Supervisor.stop(Utils.app_supervisor(), :normal)
    end

    test "kino supervisor" do
      start_supervised(
        {DynamicSupervisor,
         name: Elixir.Kino.DynamicSupervisor, strategy: :one_for_one, restart: :transient}
      )

      workers = length(DynamicSupervisor.which_children(Elixir.Kino.DynamicSupervisor))

      use Fledex, supervisor: :kino

      assert length(DynamicSupervisor.which_children(Elixir.Kino.DynamicSupervisor)) ==
               workers + 1

      Supervisor.stop(Elixir.Kino.DynamicSupervisor, :normal)
    end

    test "dynamic supervisor" do
      start_supervised(
        {DynamicSupervisor,
         name: __MODULE__.DynSupervisor, strategy: :one_for_one, restart: :transient}
      )

      assert Enum.empty?(DynamicSupervisor.which_children(__MODULE__.DynSupervisor))

      use Fledex, supervisor: {:dynamic, __MODULE__.DynSupervisor}
      assert not Enum.empty?(DynamicSupervisor.which_children(__MODULE__.DynSupervisor))

      Supervisor.stop(__MODULE__.DynSupervisor, :normal)
    end
  end
end
