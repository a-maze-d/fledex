# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.Clock do
  @behaviour Fledex.Component.Interface

  alias Fledex.Component.Dot

  defp create_name(base, child) when is_atom(base) and is_atom(child) do
    String.to_atom("#{Atom.to_string(base)}_#{Atom.to_string(child)}")
  end

  @impl true
  def configure(name, options) do
    trigger_name = Keyword.fetch!(options, :trigger_name)
    {trigger_hour, trigger_minute, trigger_second} = split_trigger(trigger_name)

    {helper_color, hour_color, minute_color, second_color} =
      Keyword.get(options, :colors, {:davy_s_grey, :red, :blue, :green})

    use Fledex

    led_strip name, :config do
      component(trigger_second, Dot,
        color: second_color,
        count: 60,
        trigger_name: trigger_second
      )

      # TODO: document this trick to do some logging
      # animation :logger do
      #   %{logger: logger} = trigger ->
      #     if rem(logger, 10) == 0 do
      #       IO.puts "logger: #{inspect trigger}"
      #     end
      #     {leds(1), %{trigger | logger: logger+1}}
      #   trigger -> {leds(1), Map.put_new(trigger, :logger, 0)}
      # end
      component(trigger_minute, Dot,
        color: minute_color,
        count: 60,
        trigger_name: trigger_minute
      )

      component(trigger_hour, Dot,
        color: hour_color,
        count: 24,
        trigger_name: trigger_hour
      )

      static create_name(name, :helper) do
        leds(5) |> light(helper_color) |> repeat(12)
      end
    end
  end

  defp split_trigger({hour, minute} = _trigger_name), do: {hour, minute, nil}
  defp split_trigger({_hour, _minute, _second} = trigger_name), do: trigger_name

  defp split_trigger(trigger_name) when is_atom(trigger_name) do
    {
      create_name(trigger_name, :hour),
      create_name(trigger_name, :minute),
      create_name(trigger_name, :second)
    }
  end
end
