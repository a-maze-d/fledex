# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.HSV do
  defstruct h: 0, s: 0, v: 0
  @type t :: %__MODULE__{h: 0..255, s: 0..255, v: 0..255}

  defimpl Fledex.Color do
    alias Fledex.Color.Conversion.Rainbow
    alias Fledex.Color.HSV

    def to_colorint(%HSV{h: _h, s: _s, v: _v} = hsv) do
      Rainbow.hsv2rgb(hsv, fn rgb -> rgb end)
      |> Fledex.Color.to_colorint()
    end
  end
end
