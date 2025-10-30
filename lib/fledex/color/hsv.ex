# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.HSV do
  @moduledoc """
  This module represents the color representation for colors encoded in the
  [HSV (hue, saturation, value) color space](https://en.wikipedia.org/wiki/HSL_and_HSV)
  """

  defstruct h: 0, s: 0, v: 0
  @type t :: %__MODULE__{h: 0..255, s: 0..255, v: 0..255}

  defimpl Fledex.Color do
    alias Fledex.Color.Conversion.Rainbow
    alias Fledex.Color.HSV
    alias Fledex.Color.Types

    @spec to_colorint(HSV.t()) :: Types.colorint()
    def to_colorint(%HSV{h: _h, s: _s, v: _v} = hsv) do
      Rainbow.hsv2rgb(hsv, fn rgb -> rgb end)
      |> Fledex.Color.to_colorint()
    end
  end
end
