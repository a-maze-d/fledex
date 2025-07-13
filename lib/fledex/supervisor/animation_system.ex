# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.AnimationSystem do
  @moduledoc """
  This module starts and supervises all the services required for running
  animations. You rarely will use this module directly, but rather use it
  through the `Fledex` DSL.

  This includes:
  * The animation manager
  * The job scheduler
  * The messaging services
  * The workers

  You can start the whole subsystem by calling
  ```elixir
  AnimationSystem.start_link/1
  ```
  It's more common to add it to a Supervision tree by calling:
  ```elixir
   Supervisor.start_link(AnimationSystem.child_spec(opts), strategy: :one_for_one)
  ```
  or for adding it to a dynamic supervisor:
  ```elixir
  DynamicSupervisor.start_child(AnimationSystem.child_spec(opts))
  ```
  or for adding in a livebook to a Kino supervisor:
  ```elixir
  Kino.start_child(AnimationSystem.child_spec(opts))
  ```

  The dynamic options are probably not something you want to do manually, but it's
  something you want to trigger when calling `use Fledex`.

  Once the `AnimationSystem` is up and running you can add workers through
  `start_led_strip`, `start_animation`, `start_coordinator`. The following
  worker types exist:
  * the led strip workers (controlling the led strip)
  * the animation workers (running withni an led strip). Note: this requires an led_strip
  * the coordinators (that can control and coordinate the various animations)
  """
  use Supervisor

  require Logger

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler
  alias Fledex.Animation.Manager
  alias Fledex.Driver.Impl.Null
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

  @doc """
  This is a child_spec that can be used when starting the `AnimationSystem`
  under a supervision tree.
  """
  @spec child_spec(keyword) :: Supervisor.child_spec()
  def child_spec(init_args \\ []) do
    %{
      id: Fledex.Supervisor.AnimationSystem,
      start: {Fledex.Supervisor.AnimationSystem, :start_link, init_args}
    }
  end

  @doc """
  starts the AnimationSystem and all necessary subsystems
  """
  @spec start_link(keyword) ::
          {:ok, pid()} | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}
  def start_link(init_args \\ []) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc """
  stops the Supervisor and all it's attached services
  """
  @spec stop(term, timeout) :: :ok
  def stop(reason \\ :normal, timeout \\ :infinity) do
    Supervisor.stop(__MODULE__, reason, timeout)
  end

  @doc """
  This starts a new led_strip to which we can send some led sequences,
  and, if we update it in regular intervals, can play an animation
  """
  @spec start_led_strip(atom, module | {module, keyword} | [{module, keyword}], keyword) ::
          GenServer.on_start()
  def start_led_strip(strip_name, drivers \\ Null, strip_config \\ []) do
    DynamicSupervisor.start_child(
      Utils.workers_supervisor(),
      %{
        # no need to be unique
        id: strip_name,
        start: {LedStrip, :start_link, [strip_name, drivers, strip_config]},
        restart: :transient
      }
    )
  end

  @doc """
  This starts a new animation. It should be noted that it's expected
  that the led_strip is already up and running
  """
  @spec start_animation(atom, atom, Animator.config_t()) :: GenServer.on_start()
  def start_animation(strip_name, animation_name, config) do
    DynamicSupervisor.start_child(
      Utils.workers_supervisor(),
      %{
        # no need to be unique
        id: animation_name,
        start: {Animator, :start_link, [strip_name, animation_name, config]},
        restart: :transient
      }
    )
  end

  @doc """
  This starts a new coordinator. Which can receive events and react to those
  by impacting the running annimations.
  """
  @spec start_coordinator(atom, atom, Coordinator.config_t()) :: GenServer.on_start()
  def start_coordinator(strip_name, coordinator_name, config) do
    DynamicSupervisor.start_child(
      Utils.workers_supervisor(),
      %{
        # no need to be unique
        id: coordinator_name,
        start: {Coordinator, :start_link, [strip_name, coordinator_name, config]},
        restart: :transient
      }
    )
  end

  # MARK: server side

  @impl true
  @spec init(keyword) ::
          {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec() | :supervisor.child_spec()]}}
          | :ignore
  def init(init_args) do
    Logger.debug("starting AnimationSystem")

    children = [
      {Registry, keys: :unique, name: Utils.worker_registry()},
      {DynamicSupervisor, strategy: :one_for_one, name: Utils.workers_supervisor()},
      {Phoenix.PubSub, adapter_name: :pg2, name: Utils.pubsub_name()},
      JobScheduler,
      {Manager, init_args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
