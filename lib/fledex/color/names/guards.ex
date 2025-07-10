# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Guards do
  require Fledex.Color.Names.Wiki, as: Wiki
  require Fledex.Color.Names.CSS, as: CSS
  require Fledex.Color.Names.SVG, as: SVG

  @doc """
    Check whether the atom is a valid color name.
    Note: RAL colors are not included (intentionaly)
  """
  @doc guard: true
  defguard is_color_name(atom)
           when Wiki.is_color_name(atom) or
                  CSS.is_color_name(atom) or
                  SVG.is_color_name(atom)

  #  or
  # CSS.is_color_name(atom) or
  # SVG.is_color_name(atom)
end
