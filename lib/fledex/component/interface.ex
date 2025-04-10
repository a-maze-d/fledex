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
  settings are passed in as options.
  This function can return any valid `t:Fledex.Animation.Animator.config_t` structure which will
  be passed to the `Fledex.Animation.Manager`.
  """
  @callback configure(atom, keyword) :: %{atom => Animator.config_t()}
end
