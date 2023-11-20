defmodule Fledex.Animation.LedAnimationManager do
  @behaviour GenServer

  require Logger

  alias Fledex.Animation.BaseAnimation
  alias Fledex.Animation.LedAnimator
  alias Fledex.LedsDriver

  @type ledAnimationManagerState :: %{
    config: map(),
    animations: map()
  }
  ### client side
  def start_link(type_config \\ %{}) do
    # we should only have a single server running. Therefore we check whether need to do something
    # or if the server is already running
    pid = GenServer.whereis(__MODULE__)
    if pid == nil do
      GenServer.start_link(__MODULE__, type_config, name: __MODULE__)
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
  def init(type_config) do
    state = %{
      type_config: type_config,
      animations: %{}
    }
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
  rescue
    RuntimeError -> {:reply, {:error, "Animator is wrongly configured"}, state}
  end
  def handle_call({:unregister_strip, strip_name}, _pid, state) when is_atom(strip_name) do
    {:reply, :ok, unregister_strip(strip_name, state)}
  end
  def handle_call({:info, strip_name}, _from, state) do
    return_value = case strip_name do
      :all -> state.animations
      other -> state.animations[other]
    end
    {:reply, {:ok, return_value}, state}
  end

  defp register_strip(strip_name, driver_config, state) do
    # Logger.info("registering led_strip: #{strip_name}")
    {:ok, _pid} = LedsDriver.start_link(strip_name, driver_config)
    %{state | animations: Map.put_new(state.animations, strip_name, nil)}
  end
  defp unregister_strip(strip_name, state) do
    # Logger.info("unregistering led_strip_ #{strip_name}")
    map = state[strip_name] || %{}
    animation_names = Map.keys(map)
    shutdown_animators(strip_name, animation_names)
    GenServer.stop(strip_name)
    %{state | animations: Map.drop(state.animations, [strip_name])}
  end
  defp register_animations(strip_name, configs, state) do
    # Logger.info("defining config for #{strip_name}, animations: #{inspect Map.keys(configs)}")

    # configs is a list of registration structs.
    # we check the current state and drop any animator we didn't receive
    # we update every animator we did receive
    # and we create any new animator
    {dropped_animations, present_animations} = filter_animations(Map.get(state.animations, strip_name), configs)
    {existing_animations, created_animations} = Map.split(configs, present_animations)

    # Logger.info("#{inspect dropped}, #{inspect present}")
    shutdown_animators(strip_name, dropped_animations)
    update_animators(strip_name, existing_animations, state.type_config)
    create_animators(strip_name, created_animations, state.type_config)

    %{state | animations: Map.put(state.animations, strip_name, configs)}
  end

  defp shutdown_animators(strip_name, dropped_animations) do
    Enum.each(dropped_animations, fn animation_name ->
      GenServer.stop(BaseAnimation.build_strip_animation_name(strip_name, animation_name), :normal)
    end)
  end

  defp update_animators(strip_name, present_animations, type_config) do
    Enum.each(present_animations, fn {animation_name, config} ->
      # Logger.info("updating: #{animator_name}")
      type = config[:type] || :animation
      module_name = type_config[type] || LedAnimator
      module_name.config(strip_name, animation_name, config)
    end)
  end

  defp create_animators(strip_name, created_animations, type_config) do
    Enum.each(created_animations, fn {animation_name, config} ->
      type = config[:type] || :animation
      module_name = type_config[type] || LedAnimator
      {:ok, pid} = module_name.start_link(config, strip_name, animation_name)
      server_name = BaseAnimation.build_strip_animation_name(strip_name, animation_name)
      case Process.info(pid, :registered_name) do
        {:registered_name, ^server_name} -> :ok
        # we could register the name if it does not exist and we could unregister and reregister
        # the process if it hav the wrong name, but that's not gonna end well. It' better to
        # throw this back immediately.
        # nil ->
          # Process.register(pid, server_name)
        # {:registered_name, other_name} ->
          # Process.unregister(other_name)
          # Process.register(pid, server_name)
        _anything -> raise RuntimeError, message: "The animator is not registered under the expected name"
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
    strip_names = Map.keys(state.animations)
    Enum.reduce(strip_names, state, fn strip_name, state ->
      unregister_strip(strip_name, state)
    end)
  end
end
