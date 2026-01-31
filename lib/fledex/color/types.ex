# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Types do
  @moduledoc """
  A couple of color related type definitions.
  """
  alias Fledex.Color.HSL
  alias Fledex.Color.HSV
  alias Fledex.Color.Names.Types
  alias Fledex.Color.RGB
  alias Fledex.Color.RGBW

  @typedoc """
  An integer representing the rgb encoded in the classical hex way:
  `0xrrggbb` values. It's also possible to add a value for a potential white led (rgbw)
  encoded as `0xwwrrggbb`.
  """
  @type colorint :: 0..0xFFFFFF | 0..0xFFFFFFFF
  @type rgb :: {red :: byte(), green :: byte(), blue :: byte()}

  @type hsv :: HSV.t()
  @type hsl :: HSL.t()

  @type color :: rgb | RGB.t() | RGBW.t() | colorint | Types.color_name_t()
  @type color_any :: color() | hsv() | hsl()
end
