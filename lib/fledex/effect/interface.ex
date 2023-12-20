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

  @doc """
  Applies an effect to the list of LEDs.

  Every LED in the list can be modified at will, however, the amount should NOT be changed.
  The function can either return a list of LEDs (color integers) or a tuple with the first
  part being the LEDs and the second being a modified triggers map. This allows to retain
  some state between applying the filter in consecutive calls.
  """
  @callback apply(leds :: [Types.colorint], config :: keyword, triggers :: map)
      :: list(Types.colorint) | {list(Types.colorint), map}
end
