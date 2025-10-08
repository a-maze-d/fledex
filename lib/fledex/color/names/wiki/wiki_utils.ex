# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.WikiUtils do
  alias Fledex.Color.Names.LoadUtils

  def converter([index, name, hex, r, g, b, h, s1, l1, s2, v2, source]) do
    %{
      index: index,
      name: LoadUtils.str2atom(name),
      descriptive_name: String.trim(name),
      hex: LoadUtils.hexstr2i(hex),
      rgb: {LoadUtils.a2b(r), LoadUtils.a2b(g), LoadUtils.a2b(b)},
      hsl: {LoadUtils.a2b(h), LoadUtils.a2b(s1), LoadUtils.a2b(l1)},
      hsv: {LoadUtils.a2b(h), LoadUtils.a2b(s2), LoadUtils.a2b(v2)},
      source: String.trim(source)
    }
  end
end
