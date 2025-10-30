# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.KinoRender do
  @moduledoc """
  This module implements a `KinoRender` that converts a `Fledex` color to a markdown
  representation that can be used in a Livebook and allows nicer rendering of return
  values. Just return an instance of this module
  ```elixir
  Fledex.Color.KinoRender.new([color1, color2])
  ```

  Take a look at [this livebook](livebook/2b_fledex_how_to_define_leds.livemd).

  > #### Note {: .info}
  >
  > For the proper rendering to happen you need to ensure that the protocol
  > consolidation does not happen, by specifying the the `consolidate_protocols: false`
  > option to `Mix.install`, i.e.:
  > ```elixir
  > Mix.install(
  >   [
  >     {:fledex, "~>0.0.0"}
  >   ],
  >   consolidate_protocols: false
  > )
  > ```
  """
  alias Fledex.Color
  alias Fledex.Color.Types
  alias Fledex.Leds

  @doc """
  Guard to check that the value is within the provided bounds of a byte [0, 255]
  """
  @doc guard: true
  defguard is_byte(sub_pixel) when is_integer(sub_pixel) and sub_pixel >= 0 and sub_pixel <= 255

  defstruct [:colors]

  @type t :: %__MODULE__{
          colors: [Types.color()]
        }

  @spec new(Types.color() | [Types.color()]) :: t
  def new(colors) when is_list(colors) do
    %__MODULE__{colors: colors}
  end

  def new(color) when is_integer(color) do
    new([color])
  end

  def new({r, g, b} = color) when is_byte(r) and is_byte(g) and is_byte(b) do
    new([color])
  end

  def new(color) when is_atom(color) do
    new([color])
  end

  @spec to_leds(t) :: Leds.t()
  def to_leds(%__MODULE__{colors: colors}) do
    colors =
      Enum.map(colors, fn color ->
        Color.to_colorint(color)
      end)

    Leds.leds(
      length(colors),
      Enum.reduce(colors, [], fn value, acc ->
        index = length(acc) + 1
        [{index, value} | acc]
      end)
      |> Map.new(),
      %{}
    )
  end

  @spec to_markdown(t) :: binary
  def to_markdown(%__MODULE__{} = colors) do
    colors
    |> to_leds()
    |> Leds.to_markdown()
  end

  defimpl Kino.Render do
    alias Fledex.Color.KinoRender
    alias Kino.Render

    @impl Render
    @spec to_livebook(Fledex.Color.KinoRender.t()) :: map
    def to_livebook(%KinoRender{} = colors) do
      md_kino = KinoRender.to_markdown(colors) |> Kino.Markdown.new()
      i_kino = Kino.Inspect.new(colors)

      kino =
        Kino.Layout.tabs(
          Leds: md_kino,
          Raw: i_kino
        )

      Kino.Render.to_livebook(kino)
    end
  end
end
