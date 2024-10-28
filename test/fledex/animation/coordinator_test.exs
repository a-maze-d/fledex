defmodule Fledex.Animation.CoordinatorTest do
  alias ExUnit.CaptureLog
  alias Fledex.Animation.Coordinator
  alias Fledex.Utils.PubSub

  use ExUnit.Case

  @spec subscribers() :: [{pid(), Registry.value()}]
  defp subscribers do
    subscribers = Registry.lookup(PubSub.app(), PubSub.channel_state())
    # wait a bit to allow the `Registry` to register/deregister our subscription
    Process.sleep(50)
    subscribers
  end

  describe "test client functions" do
    test "cycle through all" do
      assert {:ok, pid} = Coordinator.start_link(:strip_name, :coordinator_name, %{})
      assert Process.alive?(pid) == true

      assert :ok =
               Coordinator.config(:strip_name, :coordinator_name, %{
                 type: :coordinator,
                 options: [],
                 func: fn _broadcast_state, _context, options -> options end
               })

      assert :ok = Coordinator.shutdown(:strip_name, :coordinator_name)
      assert Process.alive?(pid) == false
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
      assert [{^pid, _}] = subscribers

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
