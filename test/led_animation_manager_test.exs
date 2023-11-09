defmodule Fledex.LedAnimationManagerTest do
  use ExUnit.Case

  alias Fledex.LedAnimationManager

  @strip_name :test_strip
  setup do
    {:ok, pid} = start_supervised(
      %{
        id: LedAnimationManager,
        start: {LedAnimationManager, :start_link, []}
      })
    LedAnimationManager.register_strip(@strip_name, :none)
    %{pid: pid, strip_name: @strip_name}
  end

  describe "init" do
    test "don't double start", %{pid: pid} do
      assert pid == GenServer.whereis(LedAnimationManager)
      assert {:ok, pid} == LedAnimationManager.start_link()
    end
  end
  describe "client functions" do
    test "register/unregister led_strip", %{strip_name: strip_name} do
      {:ok, state} = LedAnimationManager.get_info()
      assert Map.keys(state) == [strip_name]
      assert GenServer.whereis(strip_name) != nil

      LedAnimationManager.unregister_strip(strip_name)
      {:ok, state} = LedAnimationManager.get_info()
      assert Map.keys(state) == []
      assert GenServer.whereis(strip_name) == nil

      LedAnimationManager.register_strip(strip_name, :none)
      {:ok, state} = LedAnimationManager.get_info()
      assert Map.keys(state) == [strip_name]
      assert GenServer.whereis(strip_name) != nil
    end
    test "register/unregister 2 led_strips", %{strip_name: strip_name} do
      {:ok, state} = LedAnimationManager.get_info()
      assert Map.keys(state) == [strip_name]

      LedAnimationManager.register_strip(:strip_name2, :none)

      {:ok, state} = LedAnimationManager.get_info()
      assert Map.keys(state) == [strip_name, :strip_name2]
    end
    test "re-register led_strip", %{strip_name: strip_name} do
      pid = GenServer.whereis(strip_name)
      assert pid != nil
      LedAnimationManager.register_strip(strip_name, :none)
      pid2 = GenServer.whereis(strip_name)
      assert pid == pid2
    end
    test "register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{},
        t2: %{}
      }
      LedAnimationManager.register_animations(strip_name, config)
      assert {:ok, config} == LedAnimationManager.get_info(strip_name)

      Enum.each(Map.keys(config), fn key ->
       assert GenServer.whereis(String.to_atom("#{strip_name}_#{key}")) != nil
      end)
    end
    test "re-register animation", %{strip_name: strip_name} do
      config = %{
        t1: %{},
        t2: %{}
      }
      LedAnimationManager.register_animations(strip_name, config)
      assert GenServer.whereis(String.to_atom("#{strip_name}_#{:t2}")) != nil

      config2 = %{
        t1: %{},
        t3: %{}
      }
      LedAnimationManager.register_animations(strip_name, config2)
      assert {:ok, config2} == LedAnimationManager.get_info(strip_name)

      assert GenServer.whereis(String.to_atom("#{strip_name}_#{:t2}")) == nil
      Enum.each(Map.keys(config2), fn key ->
       assert GenServer.whereis(String.to_atom("#{strip_name}_#{key}")) != nil
      end)
    end
  end
end
