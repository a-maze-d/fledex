# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.SupervisorTest do
  use ExUnit.Case

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.Manager
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem
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

  def count_workers do
    DynamicSupervisor.count_children(Utils.workers_supervisor())
    |> Map.get(:workers)
  end

  @test_strip :test_strip
  @test_anim :my_anim
  @test_coord :my_coordinator
  describe "workers" do
    setup do
      start_supervised(AnimationSystem.child_spec([]))
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
      LedStrip.stop(@test_strip)
      assert count_workers() == 0
    end

    test "animation worker" do
      # the animation requires an led strip
      assert count_workers() == 0
      AnimationSystem.start_led_strip(@test_strip)

      assert count_workers() == 1
      AnimationSystem.start_animation(@test_strip, @test_anim, %{type: :animation})
      assert count_workers() == 2
      Animator.stop(@test_strip, @test_anim)
      assert count_workers() == 1

      # cleanup
      LedStrip.stop(@test_strip)
      assert count_workers() == 0
    end

    test "coordinator worker" do
      assert count_workers() == 0
      AnimationSystem.start_coordinator(@test_strip, @test_coord, %{
        func: fn _state, _context, _options -> :ok end})
      assert count_workers() == 1
      Coordinator.stop(@test_strip, @test_coord)
      assert count_workers() == 0
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
