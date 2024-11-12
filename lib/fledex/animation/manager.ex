# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Manager do
  @moduledoc """
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

  alias Fledex.Animation.Animator
  alias Fledex.Animation.AnimatorInterface
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler
  alias Fledex.LedStrip

  @type configs_t :: %{
          atom => Animator.config_t() | JobScheduler.config_t() | Coordinator.config_t()
        }

  @typep state_t :: %{
           animations: %{atom => Animator.config_t()},
           coordinators: %{atom => Coordinator.config_t()},
           jobs: %{atom => JobScheduler.config_t()},
           impls: %{
             job_scheduler: module,
             animator: module,
             led_strip: module,
             coordinator: module
           }
         }

  # def child_spec(args) do
  #   %{
  #     id: Manager,
  #     start: {Manager, :start_link, [args]}
  #   }
  # end

  ### MARK: client side
  @doc """
  This starts a new `Fledex.Animation.Manager`. Only a single animation manager will be started
  even if called serveral times (thus it's save to call it repeatedly).
  In general you want to start the function without options, since they are only for
  debugging purposes.
  """
  @spec start_link(keyword) :: {:ok, pid()}
  def start_link(opts \\ []) do
    # we should only have a single server running. Therefore we check whether need to do something
    # or if the server is already running
    pid = GenServer.whereis(__MODULE__)

    if pid == nil do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    else
      {:ok, pid}
    end
  end

  @doc """
  Register a new LED strip with the specific `strip_name`. The LED strip
  needs to be configured, either through a simple module (for predefined
  configurations, or a touple with module and keyword list to adjust the
  configuration.(see [`LedStrip`](Fledex.LedStrip.html) for details).
  """
  @spec register_strip(atom, [{module, keyword}], keyword) :: :ok
  def register_strip(strip_name, drivers, strip_config) do
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

  Note: the animation functions might get called quite frequently and
  therefore any work within them should be kept to a minimum.
  """
  @spec register_config(atom, %{atom => map}) :: :ok
  def register_config(strip_name, configs) do
    # Logger.debug("register animation: #{strip_name}, #{inspect configs}")
    GenServer.call(__MODULE__, {:register_config, strip_name, configs})
  end

  ### MARK: server side
  @impl GenServer
  @spec init(keyword) :: {:ok, state_t}
  def init(opts) do
    # children = [
    #   {DynamicSupervisor, strategy: :one_for_one, name: Manager.LedStrips},
    #   {DynamicSupervisor, strategy: :one_for_one, name: Manager.Animations},
    #   {DynamicSupervisor, strategy: :one_for_one, name: Manager.Coordinators},
    #   Job
    # ]
    # Supervisor.start_link(children, strategy: :one_for_one)
    state = %{
      animations: %{},
      coordinators: %{},
      jobs: %{},
      impls: %{
        job_scheduler: Keyword.get(opts, :job_scheduler, JobScheduler),
        animator: Keyword.get(opts, :animator, Animator),
        led_strip: Keyword.get(opts, :led_strip, LedStrip),
        coordinator: Keyword.get(opts, :coordinator, Coordinator)
      }
    }

    state.impls.job_scheduler.start_link()

    {:ok, state}
  end

  @impl GenServer
  @spec handle_call(
          {:regiseter_strip, atom, [{module, keyword}], keyword},
          GenServer.from(),
          state_t
        ) ::
          {:reply, :ok, state_t}
  def handle_call({:register_strip, strip_name, drivers, strip_config}, _pid, state)
      when is_atom(strip_name) do
    pid = Process.whereis(strip_name)

    if pid == nil do
      {:reply, :ok, register_strip(state, strip_name, drivers, strip_config)}
    else
      # we have a bit of a problem when using the kino driver, since it will not be reinitialized
      # when calling this function again (and thereby we don't get any frame/display).
      # Therefore we add here an extra step to reinitiate the the drivers while registering the strip.
      state.impls.led_strip.reinit(strip_name, drivers, strip_config)
      {:reply, :ok, state}
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
    {:reply, :ok, unregister_strip(state, strip_name)}
  end

  @impl GenServer
  @spec terminate(atom, state_t) :: :ok
  def terminate(_reason, state) do
    strip_names = Map.keys(state.animations)

    state =
      Enum.reduce(strip_names, state, fn strip_name, state ->
        unregister_strip(state, strip_name)
      end)

    state.impls.job_scheduler.stop()
  end

  ### MARK: private functions
  # we split the "animation" into the different aspects
  # animations, coordinators and (cron)jobs
  defp split_config(config) do
    {coordinators, rest} =
      Map.split_with(config, fn {_key, value} -> value.type == :coordinator end)

    {jobs, rest} = Map.split_with(rest, fn {_key, value} -> value.type == :job end)

    {animations, rest} =
      Map.split_with(rest, fn {_key, value} -> value.type in [:animation, :static] end)

    if map_size(rest) != 0 do
      raise RuntimeError, "An unknown type was encountered #{inspect(rest)}"
    end

    # # animations = Enum.filter(config, fn {_key, value} -> value.type in [:animation, :static] end)
    # # coordinators = Enum.filter(config, fn {_key, value} -> value.type in [:coordinator] end)
    # # jobs = Enum.filter(config, fn {_key, value} -> value.type in [:job] end)
    {animations, coordinators, jobs}
  end

  @spec register_strip(state_t, atom, [{module, keyword}], keyword) :: state_t
  defp register_strip(state, strip_name, drivers, strip_config) do
    # Logger.info("registering led_strip: #{strip_name}")
    {:ok, _pid} = state.impls.led_strip.start_link(strip_name, drivers, strip_config)

    %{
      state
      | animations: Map.put_new(state.animations, strip_name, nil),
        coordinators: Map.put_new(state.coordinators, strip_name, nil),
        jobs: Map.put_new(state.jobs, strip_name, nil)
    }
  end

  @spec unregister_strip(state_t, atom) :: state_t
  defp unregister_strip(state, strip_name) do
    # Logger.info("unregistering led_strip_ #{strip_name}")
    shutdown_coordinators(
      state.impls,
      strip_name,
      Map.keys(state.coordinators[strip_name] || %{})
    )

    shutdown_jobs(state.impls, strip_name, Map.keys(state.jobs[strip_name] || %{}))
    shutdown_animators(state.impls, strip_name, Map.keys(state.animations[strip_name] || %{}))
    state.impls.led_strip.stop(strip_name)

    %{
      state
      | animations: Map.drop(state.animations, [strip_name]),
        coordinators: Map.drop(state.coordinators, [strip_name]),
        jobs: Map.drop(state.coordinators, [strip_name])
    }
  end

  @spec register_animations(state_t, atom, map) :: state_t
  defp register_animations(state, strip_name, configs) do
    # Logger.info("defining config for #{strip_name}, animations: #{inspect Map.keys(configs)}")

    # configs is a list of registration structs.
    # we check the current state and drop any animator we didn't receive
    # we update every animator we did receive
    # and we create any new filter_configanimator
    {dropped, updated, created} = filter_configs(Map.get(state.animations, strip_name), configs)

    # Logger.info("#{inspect dropped}, #{inspect present}")
    shutdown_animators(state.impls, strip_name, dropped)
    update_animators(state.impls, strip_name, updated)
    create_animators(state.impls, strip_name, created)

    %{state | animations: Map.put(state.animations, strip_name, configs)}
  end

  @spec shutdown_animators(%{atom => module}, atom, [atom]) :: :ok
  defp shutdown_animators(_impls, strip_name, dropped_animations) do
    Enum.each(dropped_animations, fn animation_name ->
      GenServer.stop(AnimatorInterface.build_name(strip_name, :animator, animation_name), :normal)
    end)
  end

  @spec update_animators(%{atom => module}, atom, map) :: :ok
  defp update_animators(impls, strip_name, animations) do
    Enum.each(animations, fn {animation_name, config} ->
      impls.animator.config(strip_name, animation_name, config)
    end)
  end

  @spec create_animators(%{atom => module}, atom, map) :: :ok
  defp create_animators(impls, strip_name, created_animations) do
    Enum.each(created_animations, fn {animation_name, config} ->
      {:ok, _pid} = impls.animator.start_link(config, strip_name, animation_name)
    end)
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

  defp register_coordinators(state, strip_name, coordinators) do
    {dropped, updated, created} =
      filter_configs(Map.get(state.coordinators, strip_name), coordinators)

    shutdown_coordinators(state.impls, strip_name, dropped)
    update_coordinators(state.impls, strip_name, updated)
    create_coordinators(state.impls, strip_name, created)

    %{state | coordinators: Map.put(state.coordinators, strip_name, coordinators)}
  end

  @spec create_coordinators(%{atom => module}, atom, map) :: :ok
  defp create_coordinators(impls, strip_name, created_coordinators) do
    Enum.each(created_coordinators, fn {coordinator_name, config} ->
      {:ok, _pid} = impls.coordinator.start_link(strip_name, coordinator_name, config)
    end)
  end

  @spec update_coordinators(%{atom => module}, atom, map) :: :ok
  defp update_coordinators(impls, strip_name, coordinators) do
    Enum.each(coordinators, fn {coordinator_name, config} ->
      impls.coordinator.config(strip_name, coordinator_name, config)
    end)
  end

  defp shutdown_coordinators(impls, strip_name, coordinator_names) do
    Enum.each(coordinator_names, fn coordinator_name ->
      impls.coordinator.shutdown(strip_name, coordinator_name)
    end)
  end

  defp register_jobs(state, strip_name, jobs) do
    {dropped, updated, created} = filter_configs(Map.get(state.jobs, strip_name), jobs)

    shutdown_jobs(state.impls, strip_name, dropped)
    update_jobs(state.impls, strip_name, updated)
    create_jobs(state.impls, strip_name, created)

    %{state | jobs: Map.put(state.jobs, strip_name, jobs)}
  end

  defp shutdown_jobs(impls, _strip_name, job_names) do
    Enum.each(job_names, fn job_name ->
      impls.job_scheduler.delete_job(job_name)
    end)
  end

  defp update_jobs(impls, strip_name, jobs) do
    Enum.each(jobs, fn {job, job_config} ->
      impls.job_scheduler.delete_job(job)

      impls.job_scheduler.create_job(job, job_config, strip_name)
      |> impls.job_scheduler.add_job()
    end)
  end

  defp create_jobs(impls, strip_name, jobs) do
    Enum.each(jobs, fn {job, job_config} ->
      impls.job_scheduler.create_job(job, job_config, strip_name)
      |> impls.job_scheduler.add_job()

      if Keyword.get(job_config.options, :run_once, false), do: impls.job_scheduler.run_job(job)
    end)
  end
end
