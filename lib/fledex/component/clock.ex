# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Component.Clock do
  @behaviour Fledex.Component.Interface

  alias Fledex.Component.Dot

  defp create_name(base, child) do
    String.to_atom("#{base}_#{child}")
  end

  @impl true
  def configure(name, options) do
    trigger_name = Keyword.fetch!(options, :trigger_name)
    {helper_color, hour_color, minute_color} = Keyword.get(options, :colors, {:davy_s_grey, :red, :blue})

    use Fledex
    led_strip name, :config do
      component :minute, Dot,
        color: minute_color,
        count: 60,
        trigger_name: create_name(trigger_name, :minute)
      component :hour, Dot,
        color: hour_color,
        count: 24,
        trigger_name: create_name(trigger_name, :hour)
      static create_name(trigger_name, :helper) do
        leds(5) |> light(helper_color, 5) |> repeat(12)
      end
    end
  end
end
