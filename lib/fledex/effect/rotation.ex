defmodule Fledex.Effect.Rotation do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types

  @impl true
  @spec apply(leds :: list(Types.colorint), count :: non_neg_integer, config :: keyword, triggers :: map) :: list(Types.colorint)
  def apply(leds, _count, config, triggers) do
    left = Keyword.get(config, :direction, :left) != :right
    trigger_name = Keyword.get(config, :trigger_name, :default)
    offset = triggers[trigger_name] || 0
    divisor = Keyword.get(config, :divisor, 1)
    offset = trunc(offset / divisor)
    rotate(leds, offset, left)
  end

  @doc """
  Helper function mainy intended for internal use to rotate the sequence of values by an `offset`.

  The rotation can happen with the offset to the left or to the right.
  """
  @spec rotate(list(Types.colorint), pos_integer, boolean) :: list(Types.colorint)
  def rotate(vals, 0, _rotate_left), do: vals
  def rotate(vals, offset, rotate_left) do
    count = Enum.count(vals)
    offset = rem(offset, count)
    offset = if rotate_left, do: offset, else: count - offset
    Enum.slide(vals, 0..rem(offset - 1 + count, count), count)
  end
end
