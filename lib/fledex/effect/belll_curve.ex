# Copyright 2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Effect.BellCurve do
  @moduledoc """
  This is an effect that will set the intensity of the LEDs according to
  a Bell curve distribution.

  ## Options
  * `:cache` (default: false): We might want to avoid (except during development) to recalculate the bell curve values in every frame of the effect. This option allows to cache the values. CAUTION: if you dynamically change the effect, you will have to first disable the cache for changes to take effect. 
  * `:multiplier` (default: 1): The bell curve is normalized, which will result in very weak brightness values. The multiplier allows to boost that the brightness.
  * `:mean` (default: `count/2`): Where the peak of the bell curve is located.
  * `:standard_deviation` (default: 5.0): This controls the width of the bell curve. A smaller value result in a sharper peak.
  * `:min` (default: 0): This indicates the minimum value on how far we should calculate the bell curve
  * `:max` (default: count): This indicates the maximum value on how far we should calculate the bell curve
  """
  use Fledex.Effect.Interface

  alias Fledex.Color
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.RGB
  alias Fledex.Color.Types
  alias Fledex.Effect.Interface

  @doc false
  @spec do_apply(
          [Types.colorint()],
          non_neg_integer(),
          config :: keyword(),
          triggers :: map(),
          context :: map()
        ) :: {[Types.colorint()], non_neg_integer(), map()}
  def do_apply(leds, count, config, triggers, _context) do
    cache = config[:cache] || false

    {window, triggers} =
      case triggers do
        %{bell_values: window} when is_map(window) ->
          triggers = if cache, do: triggers, else: Map.delete(triggers, :bell_values)
          {window, triggers}

        _other ->
          window = calculate_window(count, config)
          triggers = if cache, do: Map.put(triggers, :bell_values, window), else: triggers
          {window, triggers}
      end

    new_leds =
      Enum.with_index(leds)
      |> Enum.map(fn {led, index} ->
        strength = Map.get(window, index, 0)

        led
        |> RGB.to_tuple()
        |> CalcUtils.nscale8(strength, false)
        |> Color.to_colorint()
      end)

    {new_leds, count, triggers}
  end

  @doc """
  Calculates the bell curve values for the given count and configuration.
  """
  @spec calculate_window(integer, keyword) :: %{integer => byte}
  def calculate_window(count, config) do
    multiplier = config[:multiplier] || 1
    mean = config[:mean] || count / 2
    standard_deviation = config[:standard_deviation] || 10.0
    min = config[:min] || 0.0
    max = config[:max] || count

    # we are only interested in integer positions
    curve = points(mean, standard_deviation, min, max, 1.0)

    Enum.map(curve, fn {pos, val} ->
      # we intensify the output with a multiplier
      stetched_val =
        (val * multiplier)
        # we limit the max to the range of 0..1 (before we scale it to a byte)
        |> max(0)
        |> min(1)
        |> then(fn s -> trunc(s * 255) end)

      {trunc(pos), stetched_val}
    end)
    |> Map.new()
  end

  @doc """
  Returns the probability density at x for a normal distribution.

  ## Examples

      Fledex.Effect.BellCurve.probability_density(0, 0, 1)
      # 0.3989422804014327
  """
  @spec probability_density(float, float, float) :: float
  def probability_density(x, mean, standard_deviation)
      when standard_deviation > 0 do
    coefficient = 1 / (standard_deviation * :math.sqrt(2 * :math.pi()))

    exponent =
      -0.5 *
        :math.pow((x - mean) / standard_deviation, 2)

    coefficient * :math.exp(exponent)
  end

  @doc """
  Generates `{x, y}` points for plotting a bell curve.
  """
  @spec points(float, float, float, float, float) :: [{float, float}]
  def points(mean, standard_deviation, min, max, step) do
    Stream.iterate(min, &(&1 + step))
    |> Stream.take_while(&(&1 <= max))
    |> Enum.map(fn x ->
      {x, probability_density(x, mean, standard_deviation)}
    end)
  end
end
