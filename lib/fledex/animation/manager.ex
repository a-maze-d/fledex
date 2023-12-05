defmodule Fledex.Animation.Manager do
  @moduledoc """
  The animation manager manages several animations (and potentially
  serveral led strips at the same time.
  Usually you don't start the service yoursel, but it gets automatically
  started when calling `use Fledex` and gets used by the `Fledex` macros.
  Thus, you rarely have to interact with it directly.

  The 3 main functions are:

  * `regiseter_strip/2`: to add a new led strip. This will also create
  the necessary `Fledex.LedStrip` and configures it.
  * `unregister_strip/1`: this will remove an led strip again
  * `register_animations/2`: this registers (or reregisters) a set of
    animations. Any animation that is not part of a reregistration will
    be dropped.
  """
  use GenServer

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Interface
  alias Fledex.LedStrip

  @typep state_t :: %{
    type_config: map(),
    animations: map()
  }

  ### client side
  @doc """
  This starts a new `Fledex.Animation.Manager`. Only a single animation manager will be started
  even if called serveral times (thus it's save to call it repeatedly).
  The `type_config` specifies the list of supported animations and their module mapping
  (see `Fledex.fledex_config/0` for the configurations used by default.)
  """
  @spec start_link(%{atom => module}) :: {:ok, pid()}
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

  @doc """
  Register a new LED strip with the specific `strip_name`. The LED strip
  needs to be configured, either through a simple atom (for predefined
  configurations, or through a map with all the configurations (see
  [`LedStrip`](Fledex.LedStrip.html) for details).
  """
  @spec register_strip(atom, atom | map) :: :ok
  def register_strip(strip_name, driver_config) do
    # Logger.debug("register strip: #{strip_name}")
    GenServer.call(__MODULE__, {:register_strip, strip_name, driver_config})
  end

  @doc """
  Unregisters a previously registered led strip. All resources related
  to the led strip will be freed.
  """
  @spec unregister_strip(atom) :: :ok
  def unregister_strip(strip_name) do
    # Logger.debug("unregister strip: #{strip_name}")
    GenServer.call(__MODULE__, {:unregister_strip, strip_name})
  end

  @doc """
  Register a set of animations for a specific led strip. This function can
  be called as many times as desired to reconfigure the animations.
  It should be noted that animations were defined before calling this function
  again, will be stopped if they are not part of the configuration anymore.
  Newly defined animations will be started.

  Different types of animations exist, see `Fledex.fledex_config/0` for
  the default configurations that will be used when using `use Fledex`.

  Note: the animation functions might get called quite frequently and
  therefore any work within them should be kept to a minimum.
  """
  @spec register_animations(atom, %{atom => map}) :: :ok
  def register_animations(strip_name, configs) do
    # Logger.debug("register animation: #{strip_name}, #{inspect configs}")
    GenServer.call(__MODULE__, {:register_animations, strip_name, configs})
  end

  @doc """
  In some circumstances it can be useful to get information on what has
  been configured and this function allows to retrieve this information.
  The function can either be called with a strip name, or with `:all`
  (the default) to retrieve all configurations at the same time.
  """
  @spec get_info(atom) :: map
  def get_info(strip_name \\ :all) do
    GenServer.call(__MODULE__, {:info, strip_name})
  end

  ### server side
  @impl GenServer
  @spec init(map) :: {:ok, state_t}
  def init(type_config) when is_map(type_config) do
    state = %{
      type_config: type_config,
      animations: %{}
    }
    {:ok, state}
  end

  @impl GenServer
  @spec handle_call({:regiseter_strip, atom, atom | map}, GenServer.from, state_t) :: {:reply, :ok, state_t}
  def handle_call({:register_strip, strip_name, driver_config}, _pid, state) when is_atom(strip_name) do
    pid = Process.whereis(strip_name)
    if pid == nil do
      {:reply, :ok, register_strip(strip_name, driver_config, state)}
    else
      # we have a bit of a problem when using the kino driver, since it will not be reinitialized
      # when calling this function again (and thereby we don't get any frame/display).
      # Therefore we add here an extra step to reinitiate the the drivers while registering the strip.
      :ok = LedStrip.reinit_drivers(strip_name)
      {:reply, :ok, state}
    end
  end
  @spec handle_call({:register_animation, atom, map}, GenServer.from, state_t) ::
    {:reply, :ok, state_t} | {:reply, {:error, String.t}, state_t}
  def handle_call({:register_animations, strip_name, configs}, _pid, state) do
    {:reply, :ok, register_animations(strip_name, configs, state)}
  rescue
    RuntimeError -> {:reply, {:error, "Animator is wrongly configured"}, state}
  end
  @spec handle_call({:unregister_strip, atom}, GenServer.from, state_t) :: {:reply, :ok, state_t}
  def handle_call({:unregister_strip, strip_name}, _pid, state) when is_atom(strip_name) do
    {:reply, :ok, unregister_strip(strip_name, state)}
  end
  @spec handle_call({:info, atom}, GenServer.from, state_t) :: {:reply, {:ok, map}, state_t}
  def handle_call({:info, strip_name}, _from, state) do
    return_value = case strip_name do
      :all -> state.animations
      other -> state.animations[other]
    end
    {:reply, {:ok, return_value}, state}
  end

  @spec register_strip(atom, atom | map, state_t) :: state_t
  defp register_strip(strip_name, driver_config, state) do
    # Logger.info("registering led_strip: #{strip_name}")
    {:ok, _pid} = LedStrip.start_link(strip_name, driver_config)
    %{state | animations: Map.put_new(state.animations, strip_name, nil)}
  end

  @spec unregister_strip(atom, state_t) :: state_t
  defp unregister_strip(strip_name, state) do
    # Logger.info("unregistering led_strip_ #{strip_name}")
    map = state[strip_name] || %{}
    animation_names = Map.keys(map)
    shutdown_animators(strip_name, animation_names)
    GenServer.stop(strip_name)
    %{state | animations: Map.drop(state.animations, [strip_name])}
  end

  @spec register_animations(atom, map, state_t) :: state_t
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

  @spec shutdown_animators(atom, [atom]) :: :ok
  defp shutdown_animators(strip_name, dropped_animations) do
    Enum.each(dropped_animations, fn animation_name ->
      GenServer.stop(Interface.build_animator_name(strip_name, animation_name), :normal)
    end)
  end

  @spec update_animators(atom, map, map) :: :ok
  defp update_animators(strip_name, animations, type_config) do
    Enum.each(animations, fn {animation_name, config} ->
      type = config[:type] || :animation
      module_name = type_config[type] || Animator
      module_name.config(strip_name, animation_name, config)
    end)
  end

  @spec create_animators(atom, map, map) :: :ok
  defp create_animators(strip_name, created_animations, type_config) do
    Enum.each(created_animations, fn {animation_name, config} ->
      type = config[:type] || :animation
      module_name = type_config[type] || Animator
      {:ok, pid} = module_name.start_link(config, strip_name, animation_name)
      server_name = Interface.build_animator_name(strip_name, animation_name)
      case Process.info(pid, :registered_name) do
        {:registered_name, ^server_name} -> :ok
        # we could register the name if it does not exist and we could unregister and reregister
        # the process if it have the wrong name, but that's not gonna end well. It's better to
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

  @spec filter_animations(map, map) :: {[atom], [atom]}
  defp filter_animations(nil, _new_animations) do
    # Logger.info("filter: nil, #{inspect new_animations}")
    # since we have no animation, none are dropped and none are existing ones
    {[], []}
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

  @impl GenServer
  @spec terminate(atom, state_t) :: :ok
  def terminate(_reason, state) do
    strip_names = Map.keys(state.animations)
    Enum.reduce(strip_names, state, fn strip_name, state ->
      unregister_strip(strip_name, state)
    end)
  end
end
