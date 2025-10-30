# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.WikiUtils do
  @moduledoc false
  alias Fledex.Color.Names.LoadUtils
  alias Fledex.Color.Names.Types

  @doc false
  @spec file_name() :: String.t()
  def file_name do
    Path.dirname(__DIR__) <> "/wiki/wiki_colors.csv"
  end

  @spec converter([integer | String.t()]) :: Types.color_struct_t()
  def converter([index, name, hex, r, g, b, h, s1, l1, s2, v2, source]) do
    %{
      index: index,
      name: LoadUtils.str2atom(name),
      descriptive_name: String.trim(name),
      hex: LoadUtils.hexstr2i(hex),
      rgb: {LoadUtils.a2b(r), LoadUtils.a2b(g), LoadUtils.a2b(b)},
      hsl: %Fledex.Color.HSL{h: LoadUtils.a2b(h), s: LoadUtils.a2b(s1), l: LoadUtils.a2b(l1)},
      hsv: %Fledex.Color.HSV{h: LoadUtils.a2b(h), s: LoadUtils.a2b(s2), v: LoadUtils.a2b(v2)},
      source: String.trim(source)
    }
  end
end
