# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Interface do
  @moduledoc """
  The behaviour for animations.

  This behaviour is the interface expected by the `Fledex.Animation.Manager`
  and should be implemented as a GenServer.
  If  you implement an animation you will have to implement those functions
  but you can use `Fledex.Animation.Base` to assist you.
  """

  @doc """
  Create a new animation (with a given name and configuration) for the led strip
  with the specified name.
  """
  @callback start_link(config :: any, strip_name :: atom, animation_name :: atom) ::
              GenServer.on_start()
  @doc """
  (Re-)Configure this animation. You will have to implement this function on server side.
  This will look something like the following:
  ```elixir
    @spec handle_cast({:config, config_t}, state_t) :: {:noreply, state_t}
    def handle_cast({:config, config}, state) do
      # do something here
      {:noreply, state}
    end
  ```
  """
  @callback config(strip_name :: atom, animation_name :: atom, config :: map) :: :ok

  @doc """
  When the animation is no long required, this function should be called. This will
  call (by default) GenServer.stop. The animation can implement the `terminate/2`
  function if necessary.
  """
  @callback shutdown(strip_name :: atom, animation_name :: atom) :: :ok

  @doc """
  This utility function will create an atomic name for the combination of strip name and
  animation name. This is used to name the animator. It is important that we do
  have a naming convention, because we would otherwise have a hard time to shutdown
  animators that have been removed. We do not keep a reference, but only a config
  Therefore the animator needs to adhere to this naming convention to properly be shut down.
  It is the responsibility of the Animator to set the servername correctly. The
  `Fledex.Animation.Base` is doing this by default.
  """
  @spec build_name(atom, :animation | :job | :coordinator, atom) :: atom
  def build_name(strip_name, type, animation_name)
      when is_atom(strip_name) and is_atom(animation_name) do
    Module.concat(Module.concat(strip_name, type), animation_name)
  end
end
