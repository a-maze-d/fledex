# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.AnimatorBase do
  alias Fledex.Animation.AnimatorInterface
  alias Fledex.Leds

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts
      @behaviour Fledex.Animation.AnimatorInterface

      alias Fledex.Animation.AnimatorBase
      alias Fledex.Animation.AnimatorInterface

      # MARK: client side
      @doc false
      @spec start_link(config :: config_t, strip_name :: atom, animation_name :: atom) ::
              GenServer.on_start()
      def start_link(config, strip_name, animation_name) do
        {:ok, _pid} =
          GenServer.start_link(__MODULE__, {config, strip_name, animation_name},
            name: AnimatorInterface.build_name(strip_name, :animator, animation_name)
          )
      end

      @doc false
      @spec config(atom, atom, config_t) :: :ok
      def config(strip_name, animation_name, config) do
        GenServer.cast(
          AnimatorInterface.build_name(strip_name, :animator, animation_name),
          {:config, config}
        )
      end

      @doc false
      @spec enable(atom, atom, :all | pos_integer, boolean) :: :ok
      def enable(strip_name, animation_name, what, enable) do
        GenServer.cast(
          AnimatorInterface.build_name(strip_name, :animator, animation_name),
          {:enable, what, enable}
        )
      end

      @doc false
      @spec shutdown(atom, atom) :: :ok
      def shutdown(strip_name, animation_name) do
        GenServer.stop(
          AnimatorInterface.build_name(strip_name, :animator, animation_name),
          :normal
        )
      end

      defoverridable start_link: 3, config: 3, shutdown: 2

      # MARK: server side
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
