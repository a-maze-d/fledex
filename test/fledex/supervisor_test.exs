# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.SupervisorTest do
  use ExUnit.Case

  alias Fledex.Animation.Manager
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.Utils
  alias Fledex.Supervisor.WorkerSupervisor

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

  describe "worker supervisor" do
    test "start stop" do
      {:ok, pid} = WorkerSupervisor.start_link([])
      assert pid != nil

      GenServer.stop(pid, :normal)
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
