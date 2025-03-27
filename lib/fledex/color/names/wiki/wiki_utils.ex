# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.WikiUtils do
  alias Fledex.Color.Names.LoadUtils

  def converter([index, name, hex, r, g, b, h, s1, l1, s2, v2, source]) do
    %{
      index: index,
      name: LoadUtils.convert_to_atom(name),
      descriptive_name: String.trim(name),
      hex: LoadUtils.clean_and_convert(hex),
      rgb: {LoadUtils.to_byte(r), LoadUtils.to_byte(g), LoadUtils.to_byte(b)},
      hsl: {LoadUtils.to_byte(h), LoadUtils.to_byte(s1), LoadUtils.to_byte(l1)},
      hsv: {LoadUtils.to_byte(h), LoadUtils.to_byte(s2), LoadUtils.to_byte(v2)},
      source: String.trim(source)
    }
  end
end
