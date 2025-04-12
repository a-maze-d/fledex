# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Animation.Coordinator do
  use GenServer

  require Logger

  alias Fledex.Animation.Utils
  alias Fledex.Utils.PubSub

  @callback start_link(strip_name :: atom, coordinator_name :: atom, configs :: keyword) ::
              GenServer.on_start()
  @callback config(atom, atom, config_t) :: :ok
  @callback shutdown(atom, atom) :: :ok

  @type config_t :: %{
          :type => :coordinator,
          :options => keyword,
          :func => (any, map, keyword -> keyword)
        }
  @typep state_t :: %__MODULE__{
           options: keyword,
           func:
             (broadcast_state :: any, context :: map(), options :: keyword() ->
                new_options :: keyword()),
           strip_name: atom,
           coordinator_name: atom
         }

  @spec default_func(any, map, keyword) :: keyword
  def default_func(_broadcast_state, _context, options), do: options

  defstruct options: [],
            func: &__MODULE__.default_func/3,
            strip_name: :default,
            coordinator_name: :default

  # MARK: client side
  @spec start_link(strip_name :: atom, coordinator_name :: atom, configs :: keyword) ::
          GenServer.on_start()
  def start_link(strip_name, animation_name, configs) do
    {:ok, _pid} =
      GenServer.start_link(__MODULE__, {strip_name, animation_name, configs},
        name: Utils.build_name(strip_name, :coordinator, animation_name)
      )
  end

  @spec config(atom, atom, config_t) :: :ok
  def config(strip_name, animation_name, config) do
    GenServer.cast(
      Utils.build_name(strip_name, :coordinator, animation_name),
      {:config, config}
    )
  end

  @spec shutdown(atom, atom) :: :ok
  def shutdown(strip_name, coordinator_name) do
    GenServer.stop(
      Utils.build_name(strip_name, :coordinator, coordinator_name),
      :normal
    )
  end

  # MARK: server side
  @impl GenServer
  @spec init({atom, atom, config_t}) :: {:ok, state_t}
  def init({strip_name, coordinator_name, configs}) do
    state = %__MODULE__{
      options: Map.get(configs, :options, []),
      func: Map.get(configs, :func, &__MODULE__.default_func/3),
      strip_name: strip_name,
      coordinator_name: coordinator_name
    }

    :ok = PubSub.subscribe(PubSub.app(), PubSub.channel_state())
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
  def terminate(_reason, _state) do
    PubSub.unsubscribe(PubSub.app(), PubSub.channel_state())
  end
end
