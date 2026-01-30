# Copyright 2025-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.HSL do
  @moduledoc """
  This module represents the color representation for colors encoded in the
  [HSL (hue, saturation, lightness) color space](https://en.wikipedia.org/wiki/HSL_and_HSV)
  """
  defstruct h: 0, s: 0, l: 0
  @type t :: %__MODULE__{h: byte(), s: byte(), l: byte()}
end
