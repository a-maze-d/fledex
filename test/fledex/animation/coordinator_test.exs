# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.CoordinatorTest do
  alias ExUnit.CaptureLog
  alias Fledex.Animation.Coordinator
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.LedStripSupervisor
  alias Fledex.Supervisor.Utils
  alias Fledex.Utils.PubSub

  use ExUnit.Case, async: true

  @spec subscribers() :: [{pid(), Registry.value()}]
  defp subscribers do
    subscribers = Registry.lookup(Utils.pubsub_name(), PubSub.channel_state())
    subscribers
  end

  setup do
    start_supervised(AnimationSystem.child_spec())
    :ok
  end

  describe "test client functions" do
    test "cycle through all" do
      assert {:ok, pid} = Coordinator.start_link(:strip_name, :coordinator_name, %{})
      assert LedStripSupervisor.coordinator_exists?(:strip_name, :coordinator_name)

      assert :ok =
               Coordinator.config(:strip_name, :coordinator_name, %{
                 type: :coordinator,
                 options: [counter: 0],
                 func: fn _broadcast_state, _context, options ->
                   Keyword.update!(options, :counter, fn old_val -> old_val + 1 end)
                 end
               })

      %Coordinator{options: options1} = :sys.get_state(pid)
      counter_1 = Keyword.fetch!(options1, :counter)
      assert counter_1 == 0

      PubSub.broadcast_state(:stop_start, %{})

      %Coordinator{options: options2} = :sys.get_state(pid)
      counter_2 = Keyword.fetch!(options2, :counter)
      assert counter_2 == counter_1 + 1

      assert :ok = Coordinator.stop(:strip_name, :coordinator_name)
      Process.sleep(500) # we need to wait for the shutdown
      assert not LedStripSupervisor.coordinator_exists?(:strip_name, :coordinator_name)
    end
  end

  describe "test server functions" do
    test "init" do
      assert {:ok, %Coordinator{} = state} =
               Coordinator.init({:strip_name, :coordinator_name, %{}})

      assert state.strip_name == :strip_name
      assert state.coordinator_name == :coordinator_name
      # default function is called
      assert state.func.(:bstate, %{}, test: 1) == [test: 1]

      subscribers = subscribers()
      assert length(subscribers) == 1
      pid = self()
      assert [{^pid, _registry_val}] = subscribers

      # ensure we registered to the correct topic
      PubSub.broadcast_state(:bstate, %{})
      assert_receive {:state_change, :bstate, %{}}

      # cleanup
      Coordinator.terminate(:normal, state)
    end

    test "config change" do
      state = %Coordinator{
        options: [old: true],
        func: fn _broadcast_state, _context, options -> Keyword.put(options, :function1, true) end,
        strip_name: :strip_name,
        coordinator_name: :coordinator_name
      }

      assert state.func.(:bstate, %{}, state.options) == [function1: true, old: true]

      config = %{
        options: [],
        func: fn _broadcast_state, _context, options -> Keyword.put(options, :function2, true) end,
        type: :coordinator
      }

      assert {:noreply, state} = Coordinator.handle_cast({:config, config}, state)
      assert state.options == [old: true]
      assert state.func.(:bstate, %{}, []) == [function2: true]
    end

    test "state change" do
      state = %Coordinator{
        options: [old: true],
        func: fn _broadcast_state, context, options ->
          case Map.get(context, :raise, false) do
            false -> Keyword.put(options, :function1, true)
            true -> raise "test"
          end
        end,
        strip_name: :strip_name,
        coordinator_name: :coordinator_name
      }

      assert {:noreply, state} = Coordinator.handle_info({:state_change, :bstate, %{}}, state)
      assert state.options == [function1: true, old: true]

      log =
        CaptureLog.capture_log(fn ->
          assert {:noreply, _state} =
                   Coordinator.handle_info({:state_change, :bstate, %{raise: true}}, state)
        end)

      assert log =~ "Coordinator issue"
    end

    test "terminate" do
      {:ok, state} = Coordinator.init({:strip_name, :coordinator_name, %{}})
      assert Enum.empty?(subscribers()) == false
      assert :ok = Coordinator.terminate(:normal, state)
      assert Enum.empty?(subscribers()) == true
    end
  end
end
