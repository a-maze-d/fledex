# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Utils do
  alias Fledex.Leds
  # TODO: the description needs to change
  # @doc """
  # This utility function will create an atomic name for the combination of strip name and
  # animation name. This is used to name the animator. It is important that we do
  # have a naming convention, because we would otherwise have a hard time to shutdown
  # animators that have been removed. We do not keep a reference, but only a config
  # Therefore the animator needs to adhere to this naming convention to properly be shut down.
  # It is the responsibility of the Animator to set the servername correctly. The
  # `Fledex.Animation.Animator` is doing this by default.
  # """
  # @spec build_name(atom, :animator | :job | :coordinator | :led_strip, atom) :: GenServer.name()
  # def build_name(strip_name, type, animation_name)
  #     when is_atom(strip_name) and is_atom(animation_name) do
  #   Module.concat([strip_name, type, animation_name])
  # end

  # @spec only_name(atom, :animator | :job | :coordinator | :led_strip, atom) :: GenServer.name()
  # def only_name(strip_name, _type, _other) when is_atom(strip_name) do
  #   strip_name
  # end

  @doc false
  @default_leds Leds.leds()
  @spec default_def_func(map) :: Leds.t()
  def default_def_func(_triggers) do
    @default_leds
  end

  @doc false
  @spec default_send_config_func(map) :: []
  def default_send_config_func(_triggers) do
    []
  end
end
