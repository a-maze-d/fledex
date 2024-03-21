# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.ManagerTest do
  use ExUnit.Case, async: false

  alias Fledex.Animation.Manager
  alias Fledex.ManagerTestUtils

  @strip_name :test_strip
  setup do
    {:ok, pid} = start_supervised(
      %{
        id: Manager,
        start: {Manager, :start_link, []}
      })
    Manager.register_strip(@strip_name, :null)
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

      Manager.register_strip(strip_name, :none)
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]
      assert GenServer.whereis(strip_name) != nil
    end
    test "register/unregister 2 led_strips", %{strip_name: strip_name} do
      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name]

      Manager.register_strip(:strip_name2, :none)

      config = ManagerTestUtils.get_manager_config()
      assert Map.keys(config) == [strip_name, :strip_name2]
    end
    test "re-register led_strip", %{strip_name: strip_name} do
      pid = GenServer.whereis(strip_name)
      assert pid != nil
      Manager.register_strip(strip_name, :none)
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
       assert GenServer.whereis(String.to_atom("#{strip_name}_#{key}")) != nil
      end)
    end
    test "re-register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{type: :animation},
        t2: %{type: :animation}
      }
      Manager.register_config(strip_name, config)
      assert GenServer.whereis(String.to_atom("#{strip_name}_#{:t2}")) != nil

      config2 = %{
        t1: %{type: :animation},
        t3: %{type: :animation}
      }
      Manager.register_config(strip_name, config2)
      assert config2 == ManagerTestUtils.get_manager_config(strip_name)

      assert GenServer.whereis(String.to_atom("#{strip_name}_#{:t2}")) == nil
      Enum.each(Map.keys(config2), fn key ->
       assert GenServer.whereis(String.to_atom("#{strip_name}_#{key}")) != nil
      end)
    end
  end
end

defmodule Fledex.Animation.ManagerTest2 do
  defmodule TestAnimator do
    @type config_t :: map
    @type state_t :: map
    use Fledex.Animation.Base
    @impl true
    def start_link(_config, _strip_name, _animation_name) do
      pid = Process.spawn(fn -> Process.sleep(1_000) end, [:link])
      Process.register(pid, :hello)
      {:ok, pid}
    end
    @impl true
    def config(_strip_name, _animation_name, _config) do
      :ok
    end
    @impl true
    def shutdown(_strip_name, _animation_name) do
      :ok
    end
    @impl true
    def init(init_arg) do
      {:ok, init_arg}
    end
  end

  use ExUnit.Case

  alias Fledex.Animation.Manager

  describe "Animation with wrong name" do
    test "register animation with a broken server_name" do
      {:ok, pid} = Manager.start_link(%{test: TestAnimator})
      :ok = Manager.register_strip(:some_strip, :none)

      config = %{
        t1: %{
          type: :test
        }
      }
      response = Manager.register_config(:some_strip, config)

      assert response == {:error, "Animator is wrongly configured"}
      Process.exit(pid, :normal)
    end
  end
end
