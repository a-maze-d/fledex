# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Manager do
  @moduledoc """
  > #### Note {: .info}
  >
  > You probably do not want to use this module directly but use the DSL defined
  > in `Fledex`

  The animation manager manages several animations (and potentially
  serveral led strips at the same time.
  Usually you don't start the service yoursel, but it gets automatically
  started when calling `use Fledex` and gets used by the `Fledex` macros.
  Thus, you rarely have to interact with it directly.

  The 3 main functions are:

  * `register_strip/2`: to add a new led strip. This will also create
  the necessary `Fledex.LedStrip` and configures it.
  * `unregister_strip/1`: this will remove an led strip again
  * `register_config/2`: this registers (or reregisters) a set of
    animations. Any animation that is not part of a reregistration will
    be dropped.
  """
  use GenServer

  require Logger

  alias Fledex.Scheduler.Runner
  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler2, as: JobScheduler
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem
  alias Fledex.Supervisor.LedStripSupervisor
  alias Fledex.Supervisor.Utils

  @type config_t :: %{
          atom => Animator.config_t() | JobScheduler.config_t() | Coordinator.config_t()
        }

  @typep state_t :: %{
           jobs: %{atom => JobScheduler.config_t()}
         }

  @doc """
  provides a child_spec of this module so that it can easily be added to
  a supervision tree.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(init_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, init_args}
    }
  end

  ### MARK: client side
  @doc """
  This starts a new `Fledex.Animation.Manager`. Only a single animation manager will be started
  even if called serveral times (thus it's save to call it repeatedly).
  In general you want to start the function without options, since they are only for
  debugging purposes.
  """
  @spec start_link(keyword) :: {:ok, pid()}
  def start_link(opts \\ []) do
    # GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    case GenServer.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @doc """
  Register a new LED strip with the specific `strip_name`. The LED strip
  needs to be configured, either through a simple module (for predefined
  configurations, or a touple with module and keyword list to adjust the
  configuration.(see [`LedStrip`](Fledex.LedStrip.html) for details).
  """
  @spec register_strip(atom, LedStrip.drivers_config_t(), keyword) :: :ok
  def register_strip(strip_name, drivers, strip_config) do
    strip_config = Keyword.put_new(strip_config, :group_leader, Process.group_leader())

    # Logger.debug("register strip: #{strip_name}")
    GenServer.call(__MODULE__, {:register_strip, strip_name, drivers, strip_config})
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
  Register a set of configurations (animations, jobs, ...) for a specific led strip.
  This function can be called as many times as desired to reconfigure the strip.
  It should be noted that any animation, job, ... that was defined before calling
  this function again, will be stopped if they are not part of the configuration anymore.
  Newly defined animations will be started.

  > #### Note {: .info}
  >
  > The animation functions might get called quite frequently and
  > therefore any work within them should be kept to a minimum.
  """
  @spec register_config(atom, %{atom => map}) :: :ok
  def register_config(strip_name, configs) do
    # Logger.debug("register animation: #{strip_name}, #{inspect configs}")
    GenServer.call(__MODULE__, {:register_config, strip_name, configs})
  end

  ### MARK: server side
  @impl GenServer
  @spec init(keyword) :: {:ok, state_t}
  def init(_opts) do
    Logger.debug("starting Animation.Manager")

    # ensure that the terminate function is called (whenever possible)
    Process.flag(:trap_exit, true)

    state = %{
      jobs: %{}
    }

    {:ok, state}
  end

  @impl GenServer
  @spec handle_call(
          {:regiseter_strip, atom, LedStrip.drivers_config_t(), keyword},
          GenServer.from(),
          state_t
        ) ::
          {:reply, :ok, state_t}
  def handle_call({:register_strip, strip_name, drivers, strip_config}, _pid, state)
      when is_atom(strip_name) do
    if AnimationSystem.led_strip_exists?(strip_name) do
      # we have a bit of a problem when using the kino driver, since it will not be reinitialized
      # when calling this function again (and thereby we don't get any frame/display).
      # Therefore we add here an extra step to reinitiate the the drivers while registering the strip.
      LedStrip.reinit(Utils.via_tuple(strip_name, :led_strip, :strip), drivers, strip_config)
      {:reply, :ok, state}
    else
      {:reply, :ok, do_register_strip(state, strip_name, drivers, strip_config)}
    end
  end

  @spec handle_call({:register_config, atom, map}, GenServer.from(), state_t) ::
          {:reply, :ok, state_t} | {:reply, {:error, String.t()}, state_t}
  def handle_call({:register_config, strip_name, configs}, _pid, state) do
    {animations, coordinators, jobs} = split_config(configs)

    state =
      state
      |> register_animations(strip_name, animations)
      |> register_coordinators(strip_name, coordinators)
      |> register_jobs(strip_name, jobs)

    {:reply, :ok, state}
  rescue
    e in RuntimeError -> {:reply, {:error, e.message}, state}
  end

  @spec handle_call({:unregister_strip, atom}, GenServer.from(), state_t) ::
          {:reply, :ok, state_t}
  def handle_call({:unregister_strip, strip_name}, _pid, state) when is_atom(strip_name) do
    {:reply, :ok, do_unregister_strip(state, strip_name)}
  end

  @impl GenServer
  @spec terminate(atom, state_t) :: :ok
  def terminate(_reason, state) do
    Logger.debug("shutting down Animation.Manager")
    strip_names = AnimationSystem.get_led_strips()

    _state =
      Enum.reduce(strip_names, state, fn strip_name, state ->
        do_unregister_strip(state, strip_name)
      end)

    :ok
  end

  ### MARK: private helper fucntions
  # we split the "animation" into the different aspects
  # animations, coordinators and (cron)jobs
  @spec split_config(map) :: {map, map, map}
  defp split_config(config) do
    {coordinators, rest} =
      Map.split_with(config, fn {_key, value} -> value.type == :coordinator end)

    {jobs, rest} = Map.split_with(rest, fn {_key, value} -> value.type == :job end)

    {animations, rest} =
      Map.split_with(rest, fn {_key, value} -> value.type in [:animation, :static] end)

    if map_size(rest) != 0 do
      raise RuntimeError, "An unknown type was encountered #{inspect(rest)}"
    end

    {animations, coordinators, jobs}
  end

  @spec do_register_strip(state_t, atom, LedStrip.drivers_config_t(), keyword) :: state_t
  defp do_register_strip(state, strip_name, drivers, strip_config) do
    _result = AnimationSystem.start_led_strip(strip_name, drivers, strip_config, [])

    %{state | jobs: Map.put_new(state.jobs, strip_name, nil)}
  end

  @spec do_unregister_strip(state_t, atom) :: state_t
  defp do_unregister_strip(state, strip_name) do
    # Logger.info("unregistering led_strip_ #{strip_name}")
    shutdown_coordinators(strip_name, LedStripSupervisor.get_coordinators(strip_name))
    shutdown_jobs(strip_name, Map.keys(state.jobs[strip_name] || %{}))
    shutdown_animators(strip_name, LedStripSupervisor.get_animations(strip_name))

    AnimationSystem.stop_led_strip(strip_name)

    %{state | jobs: Map.drop(state.jobs, [strip_name])}
  end

  @spec register_animations(state_t, atom, map) :: state_t
  defp register_animations(state, strip_name, configs) do
    # Logger.debug(("defining config for #{strip_name}, animations: #{inspect Map.keys(configs)}")

    # configs is a list of registration structs.
    # we check the current state and drop any animator we didn't receive
    # we update every animator we did receive
    # and we create any new filter_configanimator
    {dropped, updated, created} =
      filter_configs2(LedStripSupervisor.get_animations(strip_name), configs)

    # Logger.debug("updating config: #{inspect {dropped, updated, created}}")
    shutdown_animators(strip_name, dropped)
    update_animators(strip_name, updated)
    create_animators(strip_name, created)

    state
  end

  @spec shutdown_animators(atom, [atom]) :: :ok
  defp shutdown_animators(strip_name, dropped_animations) do
    Enum.each(dropped_animations, fn animation_name ->
      LedStripSupervisor.stop_animation(strip_name, animation_name)
    end)
  end

  @spec update_animators(atom, map) :: :ok
  defp update_animators(strip_name, animations) do
    Enum.each(animations, fn {animation_name, config} ->
      Animator.change_config(Utils.via_tuple(strip_name, :animator, animation_name), config)
    end)
  end

  @spec create_animators(atom, map) :: :ok
  defp create_animators(strip_name, created_animations) do
    Enum.each(created_animations, fn {animation_name, config} ->
      LedStripSupervisor.start_animation(
        strip_name,
        animation_name,
        config,
        name: Utils.via_tuple(strip_name, :animator, animation_name)
      )
    end)
  end

  @spec filter_configs2(list, map) :: {[atom], map, map}
  defp filter_configs2([], new_configs) do
    # Logger.info("filter: nil, #{inspect new_animations}")
    # since we have no animation, none need to be dropped or updated. All are new
    {[], %{}, new_configs}
  end

  defp filter_configs2(animations, new_configs) do
    # Logger.info("filter: #{inspect old_animations}, #{inspect new_animations}")
    {dropped, present} =
      Enum.reduce(animations, {[], []}, fn animation, {dropped, present} ->
        # Logger.info("filtering: #{key}")
        if Map.has_key?(new_configs, animation) do
          # Logger.info("filtering2: #{key} is in configs")
          {dropped, [animation | present]}
        else
          # Logger.info("filtering2: #{key} is NOT in configs")
          {[animation | dropped], present}
        end
      end)

    {existing, created} = Map.split(new_configs, present)
    {dropped, existing, created}
  end

  @spec filter_configs(map, map) :: {[atom], map, map}
  defp filter_configs(nil, new_configs) do
    # Logger.info("filter: nil, #{inspect new_animations}")
    # since we have no animation, none need to be dropped or updated. All are new
    {[], %{}, new_configs}
  end

  defp filter_configs(old_configs, new_configs) do
    # Logger.info("filter: #{inspect old_animations}, #{inspect new_animations}")
    {dropped, present} =
      Enum.reduce(old_configs, {[], []}, fn {key, _value}, {dropped, present} ->
        # Logger.info("filtering: #{key}")
        if Map.has_key?(new_configs, key) do
          # Logger.info("filtering2: #{key} is in configs")
          {dropped, [key | present]}
        else
          # Logger.info("filtering2: #{key} is NOT in configs")
          {[key | dropped], present}
        end
      end)

    {existing, created} = Map.split(new_configs, present)
    {dropped, existing, created}
  end

  @spec register_coordinators(state_t, atom, map) :: state_t
  defp register_coordinators(state, strip_name, coordinators) do
    {dropped, updated, created} =
      filter_configs2(LedStripSupervisor.get_coordinators(strip_name), coordinators)

    shutdown_coordinators(strip_name, dropped)
    update_coordinators(strip_name, updated)
    create_coordinators(strip_name, created)

    state
  end

  @spec create_coordinators(atom, map) :: :ok
  defp create_coordinators(strip_name, created_coordinators) do
    Enum.each(created_coordinators, fn {coordinator_name, config} ->
      LedStripSupervisor.start_coordinator(
        strip_name,
        coordinator_name,
        config,
        name: Utils.via_tuple(strip_name, :coordinator, coordinator_name)
      )
    end)
  end

  @spec update_coordinators(atom, map) :: :ok
  defp update_coordinators(strip_name, coordinators) do
    Enum.each(coordinators, fn {coordinator_name, config} ->
      Coordinator.change_config(
        Utils.via_tuple(strip_name, :coordinator, coordinator_name),
        config
      )
    end)
  end

  @spec shutdown_coordinators(atom, [atom]) :: :ok
  defp shutdown_coordinators(strip_name, coordinator_names) do
    Enum.each(coordinator_names, fn coordinator_name ->
      LedStripSupervisor.stop_coordinator(strip_name, coordinator_name)
    end)
  end

  @spec register_jobs(state_t, atom, map) :: state_t
  defp register_jobs(state, strip_name, jobs) do
    {dropped, updated, created} = filter_configs(Map.get(state.jobs, strip_name), jobs)

    shutdown_jobs(strip_name, dropped)
    update_jobs(strip_name, updated)
    create_jobs(strip_name, created)

    %{state | jobs: Map.put(state.jobs, strip_name, jobs)}
  end

  @spec shutdown_jobs(atom, [atom]) :: :ok
  defp shutdown_jobs(strip_name, job_names) do
    Enum.each(job_names, fn job_name ->
      LedStripSupervisor.stop_job(strip_name, job_name)
    end)
  end

  @spec update_jobs(atom, map) :: :ok
  defp update_jobs(strip_name, jobs) do
    Enum.each(jobs, fn {job_name, job_config} ->
      job = JobScheduler.create_job(strip_name, job_name, job_config)
      Runner.change_config(Utils.via_tuple(strip_name, :job, job_name), job, [])
    end)
  end

  @spec create_jobs(atom, map) :: :ok
  defp create_jobs(strip_name, jobs) do
    Enum.each(jobs, fn {job_name, job_config} ->
      LedStripSupervisor.start_job(strip_name, job_name, job_config, [])
    end)
  end
end
