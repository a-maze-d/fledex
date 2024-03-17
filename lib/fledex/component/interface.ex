# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Component.Interface do
  @moduledoc """
  This interface needs to be implemente by a compoenent. It should be noted
  that a component is always an animation.
  """

  alias Fledex.Animation.Animator

  @doc """
  This function will be called during initialization of a component. The various
  settings are passed in as options and are usually just saved in the options
  structure.

  The important part of an component is the `:def_func`. The function needs to be the
  arity 2 version, i.e the one that gets in a trigger and a list of options. The options
  are (in general) the same as the one that are passed to the configure function.

  It's however up to you to decide on how you want to implement the component, you
  probably can even use a macro to actually define your `def_func`.
  """
  @callback configure(atom, keyword) :: %{atom => Animator.config_t()}
end
