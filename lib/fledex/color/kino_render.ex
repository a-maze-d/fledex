# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.KinoRender do
  import Fledex.Color.Names, only: [is_color_name: 1]
  alias Fledex.Color.Types
  alias Fledex.Color.Utils
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

  def new(color) when is_atom(color) and is_color_name(color) do
    new([color])
  end

  @spec to_leds(t) :: Leds.t()
  def to_leds(%__MODULE__{colors: colors}) do
    colors =
      Enum.map(colors, fn color ->
        Utils.to_colorint(Utils.to_rgb(color))
      end)

    Leds.leds(
      length(colors),
      Map.new(
        Enum.reduce(colors, [], fn value, acc ->
          index = length(acc) + 1
          [{index, value} | acc]
        end)
      ),
      %{}
    )
  end

  @spec to_markdown(t) :: binary
  def to_markdown(%__MODULE__{} = colors) do
    Leds.to_markdown(to_leds(colors))
  end

  defimpl Kino.Render do
    alias Fledex.Color.KinoRender

    @impl true
    @spec to_livebook(Fledex.Color.KinoRender.t()) :: map
    def to_livebook(%KinoRender{} = colors) do
      md_kino = Kino.Markdown.new(KinoRender.to_markdown(colors))
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
