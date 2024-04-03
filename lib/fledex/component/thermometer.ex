# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Component.Thermometer do
  @moduledoc """
  This is only an example component to demonstrate how a component could look like.
  The component is not properly tested no major effort will be spend on getting this
  to a better state.

  This component is used in one of the  example livebooks though and therefore this
  should not be removed.
  """
  @behaviour Fledex.Component.Interface

  alias Fledex.Color.Names
  alias Fledex.Leds

  @impl true
  # @spec configure(atom, keyword) :: %{atom => Animator.config_t()}
  def configure(name, options) when is_atom(name) and is_list(options) do
    name_helper = String.to_atom("#{name}.helper")
    case Keyword.keyword?(options) do
      true ->
        %{
          name => %{
            type: :animation,
            def_func: &def_func/2,
            options: options,
            effects: []
          },
          name_helper => %{
            type: :static,
            def_func: &def_func_helper/2,
            options: options,
            effects: []
          }
        }

      false ->
        raise "Options for #{name} need to be a keyword list, but got #{inspect(options)}"
    end
  end

  def configure(name, options),
    do: raise("Unexpected syntax, got name: #{inspect(name)}, options: #{inspect(options)}")

  @out_of_range 10_000
  defp def_func(triggers, options) do
    range = Keyword.fetch!(options, :range)
    trigger_name = Keyword.fetch!(options, :trigger)
    neg_color = Keyword.get(options, :negative, :blue)
    null_color = Keyword.get(options, :null, :may_green)
    pos_color = Keyword.get(options, :positive, :red)

    temp = triggers[trigger_name] || @out_of_range
    temp = round(temp)

    temp =
      if temp == @out_of_range do
        temp
      else
        temp = min(temp, range.last)
        max(temp, range.first)
      end

    {total_leds, neg_in_range, null_in_range, pos_in_range, null_offset, pos_offset} =
      calculate_metrics(range)

    {leds, offset} =
      case temp do
        temp when temp == @out_of_range ->
          {Leds.leds(total_leds)
           |> cond_add(neg_in_range, neg_color, 1, abs(range.first))
           |> cond_add(null_in_range, null_color, null_offset, 1)
           |> cond_add(pos_in_range, pos_color, pos_offset, range.last), 1}

        temp when temp < 0 and temp > range.first ->
          {Leds.leds(1) |> Leds.light(neg_color) |> Leds.repeat(abs(temp)), pos_offset + temp - 1}

        temp when temp == 0 ->
          {Leds.leds(1) |> Leds.light(null_color), null_offset}

        temp when temp > 0 ->
          {Leds.leds(1) |> Leds.light(pos_color) |> Leds.repeat(abs(temp)), pos_offset}
      end

    Leds.leds(total_leds) |> Leds.light(leds, offset)
  end

  defp def_func_helper(_triggers, options) do
    range = Keyword.fetch!(options, :range)
    marker = Keyword.get(options, :marker, Names.black())
    marker_distance = Keyword.get(options, :marker_distance, 5)

    negative_scale =
      Leds.leds(marker_distance)
      |> Leds.light(marker)
      |> Leds.repeat(trunc(abs(range.first) / marker_distance))

    positive_scale =
      Leds.leds(marker_distance)
      |> Leds.light(marker, marker_distance)
      |> Leds.repeat(trunc(range.last / marker_distance))

    Leds.leds(Range.size(range))
    |> Leds.light(negative_scale)
    |> Leds.light(marker)
    |> Leds.light(positive_scale)
  end

  defp cond_add(leds, condition, color, offset, repeat) do
    if condition do
      leds |> Leds.light(color, offset, repeat)
    else
      leds
    end
  end

  defp calculate_metrics(range) do
    null_in_range = range.first <= 0 and range.last >= 0
    neg_in_range = range.first <= 0
    pos_in_range = range.last >= 0
    total_leds = abs(range.last - range.first) + if null_in_range, do: 1, else: 0
    null_offset = abs(range.first) + 1
    pos_offset = null_offset + if null_in_range, do: 1, else: 0
    {total_leds, neg_in_range, null_in_range, pos_in_range, null_offset, pos_offset}
  end
end
