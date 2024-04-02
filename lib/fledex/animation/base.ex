# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Base do

  alias Fledex.Animation.Interface
  alias Fledex.Leds

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts
      @behaviour Fledex.Animation.Interface

      alias Fledex.Animation.Base
      alias Fledex.Animation.Interface

      # client side
      @doc false
      @spec start_link(config :: config_t, strip_name::atom, animation_name::atom) :: GenServer.on_start()
      def start_link(config, strip_name, animation_name) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, {config, strip_name, animation_name},
                        name: Interface.build_name(strip_name, :animation, animation_name))
      end

      @doc false
      @spec config(atom, atom, config_t) :: :ok
      def config(strip_name, animation_name, config) do
        GenServer.cast(Interface.build_name(strip_name, :animation, animation_name), {:config, config})
      end

      @doc false
      @spec shutdown(atom, atom) :: :ok
      def shutdown(strip_name, animation_name) do
        GenServer.stop(Interface.build_name(strip_name, :animation, animation_name), :normal)
      end

      defoverridable start_link: 3, config: 3, shutdown: 2

      # server side
      @impl GenServer
      @spec handle_call(:info, {pid, any}, state_t) :: {:reply, {:ok, map}, state_t}
      def handle_call(:info, _from, state) do
        {:reply, {:ok, state}, state}
      end

      defoverridable handle_call: 3
    end
  end

  @doc false
  @default_leds Leds.leds()
  @spec default_def_func(map) :: Leds.t()
  def default_def_func(_triggers) do
    @default_leds
  end

  @doc false
  @spec default_send_config_func(map) :: %{}
  def default_send_config_func(_triggers) do
    %{}
  end
end
