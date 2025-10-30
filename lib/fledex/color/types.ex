# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
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

  @type colorint :: 0..0xFFFFFF
  @type rgb :: {red :: 0..255, green :: 0..255, blue :: 0..255}

  @type hsv :: HSV.t()
  @type hsl :: HSL.t()

  @type color :: rgb | RGB.t() | colorint | Types.color_name_t()
  @type color_any :: color() | hsv() | hsl()
end
