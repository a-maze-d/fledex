# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Animation.Coordinator do
  @moduledoc """
  > #### Note {: .info}
  >
  > You probably do not want to use this module directly but use the DSL defined
  > in `Fledex`

  The coordinator is a module that is responsible for running the coordinator
  function.

  This module is rather simple:
  * It listens to events on the `Fledex.Utils.PubSub.channel_state()` channel
  * Passes the events to the function (`:func`) with which it was configured (or changed through the `config/3` function)
  * And keeps track of some settings, that the function can use in it's processing

  See `t:config_t/0` for more details on how to implement the function.
  """
  use GenServer

  require Logger

  alias Fledex.Supervisor.Utils
  alias Fledex.Utils.PubSub

  @typedoc """
  The configuration of a coordinator.

  The most important part is the `:func` which is a function that
  takes 3 parameters
  * `broadcast_state`: event (usually an atom),
  * `context`: descriptor to describe who has sent ou the event. It usually contains the strip_name and/or the animation_name and/or information about the effect.
  * `state`: contains the state of the coordinator. The first time the function is called the `:options` are passed in as `state`. The Coordinator should return a `new_state`.

  You probably would impelment it something like this:
  ```elixir
  func: fn
    {:stop_start, %{strip_name: :john, animation_name: :doe}, state} ->
      # ... do something with the animations or effects
      # ... update the state if necessary
      state
    _ ->
      # do nothing
      state
  end
  ```
  """
  @type config_t :: %{
          :type => :coordinator,
          :options => keyword,
          :func => (broadcast_state :: any, context :: map, state :: keyword ->
                      new_state :: keyword)
        }
  @typep state_t :: %__MODULE__{
           strip_name: atom,
           coordinator_name: atom,
           func: (broadcast_state :: any, context :: map(), options :: keyword() ->
                    new_options :: keyword()),
           options: keyword
         }

  defstruct strip_name: :default,
            coordinator_name: :default,
            func: &__MODULE__.default_func/3,
            options: []

  # MARK: client side
  @doc """
  Start a new coordinator for the given led strip with the specified config
  """
  @spec start_link(strip_name :: atom, coordinator_name :: atom, config :: config_t) ::
          GenServer.on_start()
  def start_link(strip_name, coordinator_name, config) do
    {:ok, _pid} =
      GenServer.start_link(__MODULE__, {strip_name, coordinator_name, config},
        name: Utils.via_tuple(strip_name, :coordinator, coordinator_name)
      )
  end

  @doc """
  Change the config of the given coordinator
  """
  @spec config(atom, atom, config_t) :: :ok
  def config(strip_name, coordinator_name, config) do
    GenServer.cast(
      Utils.via_tuple(strip_name, :coordinator, coordinator_name),
      {:config, config}
    )
  end

  @doc """
  Stop the coordinator
  """
  @spec stop(atom, atom) :: :ok
  def stop(strip_name, coordinator_name) do
    GenServer.stop(
      Utils.via_tuple(strip_name, :coordinator, coordinator_name),
      :normal
    )
  end

  # MARK: server side
  @impl GenServer
  @spec init({atom, atom, config_t}) :: {:ok, state_t}
  def init({strip_name, coordinator_name, configs}) do
    Logger.debug(
      "starting coordinator: #{inspect({strip_name, coordinator_name})}",
      %{strip_name: strip_name, coordinator_name: coordinator_name, configs: configs}
    )

    # make sure we call the terminate function whenever possible
    Process.flag(:trap_exit, true)

    state = %__MODULE__{
      options: Map.get(configs, :options, []),
      func: Map.get(configs, :func, &__MODULE__.default_func/3),
      strip_name: strip_name,
      coordinator_name: coordinator_name
    }

    :ok = PubSub.subscribe(PubSub.channel_state())
    {:ok, state}
  end

  @impl GenServer
  @spec handle_cast({:config, config_t}, state_t) :: {:noreply, state_t}
  def handle_cast({:config, config}, %__MODULE__{options: options} = state) do
    # make sure to keep options, because they might be added as part of the coordination
    {:noreply,
     %__MODULE__{state | func: config.func, options: Keyword.merge(options, config.options)}}
  end

  @impl GenServer
  @spec handle_info({:state_change, any, map}, state_t) :: {:noreply, state_t}
  def handle_info(
        {:state_change, broadcast_state, context},
        %__MODULE__{func: func, options: options} = state
      ) do
    state =
      try do
        %__MODULE__{state | options: func.(broadcast_state, context, options)}
      rescue
        value ->
          Logger.warning(
            "Coordinator issue, caught #{inspect(value)} (context: #{inspect(context)})"
          )

          state
      end

    {:noreply, state}
  end

  @impl GenServer
  @spec terminate(reason, state :: term()) :: term()
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, %{strip_name: strip_name, coordinator_name: coordinator_name} = _state) do
    Logger.debug(
      "shutting down coordinator: #{inspect({strip_name, coordinator_name})}",
      %{strip_name: strip_name, coordinator_name: coordinator_name}
    )

    PubSub.unsubscribe(PubSub.channel_state())
  end

  # MARK: public helper functions
  @doc false
  @spec default_func(any, map, keyword) :: keyword
  def default_func(_broadcast_state, _context, options), do: options
end
