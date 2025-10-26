# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Types do
  alias Fledex.Color.HSL
  alias Fledex.Color.HSV
  alias Fledex.Color.Names.Types
  alias Fledex.Color.RGB

  @type rgb :: {red :: 0..255, green :: 0..255, blue :: 0..255} | RGB.t()
  @type hsv :: HSV.t()
  @type hsl :: HSL.t()
  @type colorint :: 0..0xFFFFFF

  @type color :: rgb | colorint | Types.color_name_t()
  @type color_any :: color() | hsv() | hsl()
end
