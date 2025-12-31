# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Rotation do
  @moduledoc """
  This effect will apply a rotation to the leds

  ## Options
  This effect accepts the following options:
  * `:direction`: The direction the rotation should go. You should either specify `:left` (default) or `:right`.
  * `:publish`: whether to publish state events (`true`, the default) or not. For more information see below.
  * `:trigger_name`: the name of the trigger that results in a step in the rotation. the value in `trigger[trigger_name]` (or 0 if not defined) will then result in an offset of the leds.
  * `:divisor`: We can slow the animation down by specifying a divisor. It will devide the trigger by this amount (and truncate the result). Thus, if the `:divisor` is `10` then it would take 10 steps of the trigger before a single step of the leds would be visible (similar to a 10:1 gear ratio)
  * `:stretch`: The leds can be rotated within themselves  or stretched over more leds. For example, you you have a 10 led sequences that you stretch over 20 leds, then the 10 leds will move over the 20 leds. Note the rules of the LedStrip still apply, that leds that are painted to non-physical leds will not be visible.

  ## state information
  The rotation effect publishes a couple of state events (except if `:publish` is set to `false`). Here a description on what the various events mean:

  Lets assume we have the following 20 leds:
  ```
           1         0
  98765432109876543210
  ```
  that are getting stretched over 40 leds:

  ```
           3         2         1         0
  9876543210987654321098765432109876543210
  ```

  lets rotate to the right, we then have the
  following interesting points:

  * we start with the rotation left aligned (as shown above) (`:start`)
  * we move slowly to the right. crossing through the mid-point (`:middle`)
  * we touch with the right side of the leds at the right side of the stretched part (`:touch`). We are in the run-out, i.e. leds are moving "out" of the stretched part
  * the last led has reached the right side of the stretched part (no more rotation is visible). The next step will correspond to the first one where we started. (`:end`)

  Don't forget that the effect is a rotation, so leds that "drop out on the right will reappear on the left. You might be wondering on what happens if you don't stretch your animation. The same events will be published, but

  """
  use Fledex.Effect.Interface

  alias Fledex.Color.Types
  alias Fledex.Utils.PubSub

  @doc """
  Implementation of the Rotation effect.

  This is making use of the `Fledex.Effect.Interface.__using__/1` functionalty.
  """
  @spec do_apply(
          [Fledex.Color.Types.colorint()],
          non_neg_integer(),
          config :: keyword(),
          triggers :: map(),
          context :: map()
        ) :: {[Fledex.Color.Types.colorint()], non_neg_integer(), map()}
  def do_apply(leds, count, config, triggers, context) do
    left = Keyword.get(config, :direction, :left) != :right
    publish = Keyword.get(config, :publish, true)
    trigger_name = Keyword.get(config, :trigger_name, :default)
    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    stretch = Keyword.get(config, :stretch, 0)

    {leds, count} = stretch(leds, count, stretch)
    offset = trunc(offset / divisor)
    remainder = rem(offset, count)
    _ignore = if publish and remainder == 0, do: PubSub.broadcast_state(:stop_start, context)
    {rotate(leds, count, remainder, left), count, triggers}
  end

  @doc """
  Helper function mainy intended for internal use to rotate the sequence of values by an `offset`.

  The rotation can happen with the offset to the left or to the right.
  """
  @spec rotate(list(Types.colorint()), non_neg_integer, pos_integer, boolean) ::
          list(Types.colorint())
  def rotate(vals, _count, 0, _rotate_left), do: vals

  def rotate(vals, count, offset, rotate_left) do
    offset = if rotate_left, do: offset, else: count - offset
    Enum.slide(vals, 0..rem(offset - 1 + count, count), count)
  end

  # stretch the number of led_count to be the same as stretch
  # we ignore the stretching if a too small number is specified
  # (we don't support shrinking, i.e. negative stretching)
  @spec stretch([Fledex.Color.Types.colorint()], non_neg_integer(), integer) ::
          {[Fledex.Color.Types.colorint()], non_neg_integer()}
  defp stretch(leds, led_count, stretch)
       when stretch == led_count or
              stretch < led_count do
    {leds, led_count}
  end

  defp stretch(leds, led_count, stretch) when stretch > led_count do
    missing = stretch - led_count
    missng_leds = Enum.map(1..missing, fn _index -> 0x000000 end)
    {leds ++ missng_leds, stretch}
  end
end
