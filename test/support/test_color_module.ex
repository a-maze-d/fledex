# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule TestColorModule do
  @behaviour Fledex.Color.Names.Interface

  defguard is_color_name(name) when name == :maze

  def names do
    [:maze]
  end

  def colors do
    [
      %{
        index: 1,
        name: :maze,
        descriptive_name: "maze special color",
        hex: 0x747474,
        rgb: {0x74, 0x74, 0x74},
        hsl: {0, 0, 0},
        hsv: %Fledex.Color.HSV{h: 0, s: 0, v: 0},
        source: "",
        module: __MODULE__
      }
    ]
  end

  def info(:maze, :hex) do
    0x747474
  end

  def info(:maze, :all) do
    [color] = colors()
    color
  end

  def maze(what \\ :hex) do
    info(:maze, what)
  end

  def maze(leds, _opts) do
    leds
  end
end
