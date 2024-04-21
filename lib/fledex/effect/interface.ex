# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Interface do
  @moduledoc """
  This module defines the interface for an LED effect. Effects can be used in Animations.
  Examples are:

  * Rotation
  * Dimming
  * Randomize
  * Wanishing
  * Blinking
  * etc.
  """

  alias Fledex.Color.Types

  @typedoc """
  The state of an effect.

  An effect can be in different states
  * `:static`: effect is a static effect (and hence can not be used in a sequencer)
  * `:start`: effect will start with the next iteration (and will move into the :progress state).
      An effect can skip this state and go directly into the :progress state
  * `:progress`: effect is in progress (and will either go into the :stop_start or :stop state)
  * `:stop_start`:  effect is done with one round and will start the next round. THe next state
      can either be :start or :progress
  * `:stop`: effect is done with it's effect and will stop
  * `:disabled`: effect is currently disabled (by enabling it goes into the :start state)

  This information can be used by some effect sequencer that plays one effect after the next.
  """
  @type effect_state_t :: :static | :start | :progress | :stop_start | :stop | :disabled

  @doc """
  Applies an effect to the list of LEDs.

  Every LED in the list can be modified at will, however, the amount should NOT be changed.
  The function can either return a list of LEDs (color integers) or a tuple with the first
  part being the LEDs and the second being a modified triggers map. This allows to retain
  some state between applying the filter in consecutive calls.
  The `count` is the amount of LEDs in the list (to avoid that we have to traverse it unnecessarily)
  """
  @callback apply(
              leds :: [Types.colorint()],
              count :: non_neg_integer,
              config :: keyword,
              triggers :: map
            ) ::
              {list(Types.colorint()), non_neg_integer, map, effect_state_t}

  @callback update_config(config :: keyword, updates :: keyword) :: keyword
  @optional_callbacks update_config: 2
end
