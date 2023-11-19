defmodule Fledex.LedAnimationManager do
  @behaviour GenServer

  require Logger

  alias Fledex.LedAnimator
  alias Fledex.LedsDriver

  ### client side
  def start_link do
    # we should only have a single server running. Therefore we check whether need to do something
    # or if the server is already running
    pid = GenServer.whereis(__MODULE__)
    if pid == nil do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    else
      {:ok, pid}
    end
  end

  def register_strip(strip_name, driver_config) do
    # Logger.debug("register strip: #{strip_name}")
    GenServer.call(__MODULE__, {:register_strip, strip_name, driver_config})
  end
  def unregister_strip(strip_name) do
    # Logger.debug("unregister strip: #{strip_name}")
    GenServer.call(__MODULE__, {:unregister_strip, strip_name})
  end
  def register_animations(strip_name, configs) do
    # Logger.debug("register animation: #{strip_name}, #{inspect configs}")
    GenServer.call(__MODULE__, {:register_animations, strip_name, configs})
  end
  def get_info(strip_name \\ :all) do
    GenServer.call(__MODULE__, {:info, strip_name})
  end

  ### server side
  @impl true
  def init(_init_args) do
    state = %{}
    {:ok, state}
  end

  @impl true
  def handle_call({:register_strip, strip_name, driver_config}, _pid, state) when is_atom(strip_name) do
    pid = Process.whereis(strip_name)
    if pid == nil do
      {:reply, :ok, register_strip(strip_name, driver_config, state)}
    else
      # we have a bit of a problem when using the kino driver, since it will not be reinitialized
      # when calling this function again (and thereby we don't get any frame/display).
      # Therefore we add here an extra step to reinitiate the the drivers while registering the strip.
      :ok = LedsDriver.reinit_drivers(strip_name)
      {:reply, :ok, state}
    end
  end
  def handle_call({:register_animations, strip_name, configs}, _pid, state) do
    {:reply, :ok, register_animations(strip_name, configs, state)}
  end
  def handle_call({:unregister_strip, strip_name}, _pid, state) when is_atom(strip_name) do
    {:reply, :ok, unregister_strip(strip_name, state)}
  end
  def handle_call({:info, strip_name}, _from, state) do
    return_value = case strip_name do
      :all -> state
      other -> state[other]
    end
    {:reply, {:ok, return_value}, state}
  end

  defp register_strip(strip_name, driver_config, state) do
    # Logger.info("registering led_strip: #{strip_name}")
    {:ok, _pid} = LedsDriver.start_link(strip_name, driver_config)
    Map.put_new(state, strip_name, nil)
  end
  defp unregister_strip(strip_name, state) do
    # Logger.info("unregistering led_strip_ #{strip_name}")
    map = state[strip_name] || %{}
    animation_names = Map.keys(map)
    shutdown_animators(strip_name, animation_names)
    GenServer.stop(strip_name)
    Map.drop(state, [strip_name])
  end
  defp register_animations(strip_name, configs, state) do
    # Logger.info("defining config for #{strip_name}, animations: #{inspect Map.keys(configs)}")

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
      # Logger.info("shutting down: #{animator_name}")
      LedAnimator.shutdown(strip_name, animator_name)
    end)
  end

  defp update_animators(strip_name, present_animations) do
    Enum.each(present_animations, fn {animator_name, value} ->
      # Logger.info("updating: #{animator_name}")
      LedAnimator.config(strip_name, animator_name, value)
    end)
  end

  defp create_animators(strip_name, created_animations) do
    Enum.each(created_animations, fn {animator_name, config} ->
      case config[:type] do
      # Logger.info("creating: #{strip_name}-#{animator_name}")
        nil -> LedAnimator.start_link(config, strip_name, animator_name)
        :animation -> LedAnimator.start_link(config, strip_name, animator_name)
        # :component ->
        # :static -> LedAnimator.start_link(config, strip_name, animator_name)
      end
    end)
  end

  defp filter_animations(nil, _new_animations) do
    # Logger.info("filter: nil, #{inspect new_animations}")
    # since we have no animation, none are dropped and none are existing ones
    {%{}, []}
  end
  defp filter_animations(old_animations, new_animations) do
    # Logger.info("filter: #{inspect old_animations}, #{inspect new_animations}")
    {dropped_animations, present_animations} = Enum.reduce(old_animations, {[], []}, fn {key, _value}, {dropped_animations, present_animations} ->
      # Logger.info("filtering: #{key}")
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
