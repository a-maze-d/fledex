defmodule Fledex.LedAnimationManager do
  @behaviour GenServer

  require Logger

  alias Fledex.LedAnimator
  alias Fledex.LedsDriver

  ### for debugging only
  def run do
    {:ok, pid} = __MODULE__.start_link()
    __MODULE__.register_strip(:t, :none)
    __MODULE__.register_animations(:t, %{t1: %{}, t2: %{}})
    __MODULE__.register_animations(:t, %{t1: %{}, t3: %{}})
    Process.sleep(5_000)
    GenServer.stop(pid)
    :ok
  end

  ### client side
  def start_link do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_strip(strip_name, driver_config) do
    GenServer.call(__MODULE__, {:register_strip, strip_name, driver_config}, :infinity)
  end
  def unregister_strip(strip_name) do
    GenServer.call(__MODULE__, {:unregister, strip_name}, :infinity)
  end
  def register_animations(strip_name, configs) do
    GenServer.call(__MODULE__, {:register, strip_name, configs}, :infinity)
  end

  ### server side
  @impl true
  def init(_init_args) do
    state = %{}
    {:ok, state}
  end

  @impl true
  def handle_call({:register_strip, strip_name, driver_config}, _pid, state) when is_atom(strip_name) do
    if Process.whereis(strip_name) == nil do
      {:reply, :ok, register_strip(strip_name, driver_config, state)}
    else
      {:reply, {:error, "Process already exists"}, state}
    end
  end
  def handle_call({:register, strip_name, configs}, _pid, state) do
    {:reply, :ok, register(strip_name, configs, state)}
  end
  def handle_call({:unregister_strip, strip_name}, _pid, state) when is_atom(strip_name) do
    {:reply, :ok, unregister_strip(strip_name, state)}
  end

  defp register_strip(strip_name, driver_config, state) do
    {:ok, _pid} = LedsDriver.start_link(driver_config, strip_name)
    Map.put_new(state, strip_name, nil)
  end
  defp unregister_strip(strip_name, state) do
    keys = Map.keys(state[strip_name])
    shutdown_animators(strip_name, keys)
    GenServer.stop(strip_name, :shutdown)
    Map.drop(state, [strip_name])
  end
  defp register(strip_name, configs, state) do
    # configs is a list of registration structs.
    # we check the current state and drop any animator we didn't receive
    # we update every animator we did receive
    # and we create any new animator
    {dropped_animations, present_animations} = filter_animations(Map.get(state, strip_name), configs)
    {existing_animations, created_animations} = Map.split(configs, present_animations)

    # Logger.info("#{inspect dropped}, #{inspect present}")
    shutdown_animators(strip_name, dropped_animations)
    update_animators(strip_name, existing_animations)
    create_animators(strip_name, created_animations)

    Map.put(state, strip_name, configs)
  end

  defp shutdown_animators(strip_name, dropped_animations) do
    Enum.each(dropped_animations, fn animator_name ->
      Logger.info("shutting down: #{animator_name}")
      LedAnimator.shutdown(strip_name, animator_name)
    end)
  end

  defp update_animators(strip_name, present_animations) do
    Enum.each(present_animations, fn {animator_name, value} ->
      Logger.info("updating: #{animator_name}")
      LedAnimator.config(strip_name, animator_name, value)
    end)
  end

  defp create_animators(strip_name, created_animations) do
    Enum.each(created_animations, fn {animator_name, config} ->
      Logger.info("creating: #{animator_name}")
      LedAnimator.start_link(config, strip_name, animator_name)
    end)
  end

  defp filter_animations(nil, _new_animations) do
    {%{}, []}
  end
  defp filter_animations(old_animations, new_animations) do
    # Logger.info("filter: #{Map.to_list(state)}, #{Map.to_list(configs)}")
    {dropped_animations, present_animations} = Enum.reduce(old_animations, {[], []}, fn {key, _value}, {dropped_animations, present_animations} ->
      # Logger.info("filtering: #{key}, #{inspect Map.keys(configs)}. #{is_atom(key)}")
      if Map.has_key?(new_animations, key) do
        # Logger.info("filtering2: #{key} is in configs")
        {dropped_animations, [key | present_animations]}
      else
        # Logger.info("filtering2: #{key} is NOT in configs")
        {[key | dropped_animations], present_animations}
      end
    end)

    {dropped_animations, present_animations}
  end

  @impl true
  def terminate(_reason, state) do
    strip_names = Map.keys(state)
    Enum.reduce(strip_names, state, fn strip_name, state ->
      unregister_strip(strip_name, state)
    end)
  end
end
