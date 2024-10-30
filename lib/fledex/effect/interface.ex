# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
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
  Typical states of an effect that should be published

  Note: This is not used yet and still very much in flux

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

  Every LED in the list can be modified at will, however, the amount should NOT (but can be
  as can be seen in the offset effect) be changed.
  The function takes the following parameters:

  * The `leds` is a list of colorints representing the different colors
  * The `count` is the amount of LEDs in the list (to avoid that we have to traverse it unnecessarily)
  * The `config` are some settings that can be used to configure the effect
  * The `triggers` map contains all the triggers can that can be used by the effect. It
    does contain also the extra parameters passed in in previous calls (see below)
  * The `context` is a tuple of `strip_name`, `animation_name` and effect `index`.

  The function returns

  * a list of LEDs (color integers),
  * the new count of the list,
  * and a (potentially modified) `triggers` map. This allows to retain some state between applying
  the filter in consecutive calls.

  The most simplest filter is the one that simply returns the passed in parameters:

  ```elixir
  def apply(leds, count, _config, trigggers, _context) do
    {leds, count, triggers}
  end
  ```
  """
  @callback apply(
              leds :: [Types.colorint()],
              count :: non_neg_integer,
              config :: keyword,
              triggers :: map,
              context :: map
            ) ::
              {list(Types.colorint()), non_neg_integer, map}

  @callback enabled?(config :: keyword) :: boolean

  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      @behaviour Fledex.Effect.Interface

      @impl true
      @spec enabled?(config :: keyword) :: boolean
      def enabled?(config) do
        Keyword.get(config, :enabled, true)
      end

      @impl true
      @spec apply(
              leds :: list(Types.colorint()),
              count :: non_neg_integer,
              config :: keyword,
              triggers :: map,
              context :: map
            ) ::
              {list(Types.colorint()), non_neg_integer, map}
      def apply(leds, 0, _config, triggers, _context), do: {leds, 0, triggers}

      def apply(leds, count, config, triggers, context) do
        case enabled?(config) do
          true ->
            do_apply(leds, count, config, triggers, context)

          false ->
            {leds, count, config}
        end
      end

      @spec do_apply(
              leds :: list(Types.colorint()),
              count :: non_neg_integer,
              config :: keyword,
              triggers :: map,
              context :: map
            ) ::
              {list(Types.colorint()), non_neg_integer, map}
      def do_apply(leds, count, _config, triggers, _context) do
        {leds, count, triggers}
      end

      defoverridable apply: 5, do_apply: 5
    end
  end
end
