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
  Typical states of an effect or an animation that should be published

  An animation or effect can publish state events that a `Fledex.Animation.Coordinator` (or anyone who listens to them) can react to. Any atom can be used as an event and animations and effects can create their own, but this list are the most common and re-occuring ones.
  If possible try to use them.

  * `:start`: effect will start with the next iteration (and will move into the :progress state).
  * `:middle`: offen an effect consists of 2 phases (back and forth, wanish and reappear, ...). This event indicates the mid-point.
  * `:end`:  effect has reached it's final state. IF the effect cycles in rounds, the the next step will restart the effect.
  * `:disabled`: the effect or animation has been disabled

  > #### Note {: .info}
  >
  > This is not used yet and still very much in flux
  """
  @type effect_state_t :: :start | :middle | :end | :disabled

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
  * The `context` is a map containing information of `strip_name`, `animation_name` and effect `index`.

  The function returns

  * a list of LEDs (color integers),
  * the new count of the list (usually it's the same, but does not need to be)
  * and a (potentially modified) `triggers` map. This allows to retain some state between applying the filter in consecutive calls.

  The most simplest effect is the one that simply returns the passed in parameters:

  ```elixir
  def apply(leds, count, _config, trigggers, _context) do
    {leds, count, triggers}
  end
  ```

  You probably do not want to implement this function, which has a default
  implementation, but the `do_apply/5` version (which takes the same arguments).
  This way you don't need to explicitly handle the case that the effect is disabled.
  """
  @callback apply(
              leds :: [Types.colorint()],
              count :: non_neg_integer,
              config :: keyword,
              triggers :: map,
              context :: map
            ) ::
              {list(Types.colorint()), non_neg_integer, map}

  @doc """
  a standardized interface to check whether the effect is enabled or disabled
  """
  @callback enabled?(config :: keyword) :: boolean

  @doc """
  By using this Interface you get a lot boilerplate functionality of
  enabling and disabling the effect for free.

  The only thing you need to implement is the `do_apply/5` function.
  Both `apply/5` and `do_apply/5` have a default implementation and can
  be overwritten.
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      @behaviour Fledex.Effect.Interface
      alias Fledex.Effect.Interface

      @doc delegate_to: {Interface, :enabled?, 1}
      @impl Interface
      @spec enabled?(config :: keyword) :: boolean
      def enabled?(config) do
        Keyword.get(config, :enabled, true)
      end

      @doc delegate_to: {Interface, :apply, 5}
      @impl Interface
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

      @doc """
      Similar to the `apply/5` function, but you don't have to handle
      the enable/disable states.

      The default implementation of `apply/5` will handle that for you
      and you can focus purely on the effect aspect.
      """
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
